import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:simplechat/models/uploading_message_model.dart';
import 'package:simplechat/models/user_model.dart';
import 'package:simplechat/services/firestore_service.dart';
import 'package:simplechat/services/storage_service.dart';
import 'package:simplechat/screens/chat/components/delete_message_dialog.dart';
import 'package:uuid/uuid.dart';

class ChatStateManager with ChangeNotifier {
  final BuildContext context;
  final FirestoreService firestoreService;
  final StorageService storageService;
  final String chatId;
  final String currentUserId;
  final String otherUserId;

  bool _isSelectionMode = false;
  final List<DocumentSnapshot> _selectedMessages = [];
  final List<UploadingMessage> _uploadingMessages = [];

  bool get isSelectionMode => _isSelectionMode;
  List<DocumentSnapshot> get selectedMessages => _selectedMessages;
  List<UploadingMessage> get uploadingMessages => _uploadingMessages;

  ChatStateManager({
    required this.context,
    required this.firestoreService,
    required this.storageService,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
  });

  void handleFileUpload(UploadTask uploadTask, UploadingMessage message, {int? audioDuration}) {
    _uploadingMessages.insert(0, message);
    notifyListeners();

    uploadTask.snapshotEvents.listen((taskSnapshot) {
      final progress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
      final index = _uploadingMessages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        _uploadingMessages[index].progress = progress;
        notifyListeners();
      }
    });

    uploadTask.whenComplete(() async {
      final downloadUrl = await uploadTask.snapshot.ref.getDownloadURL();
      _uploadingMessages.removeWhere((m) => m.id == message.id);
      notifyListeners();

      switch (message.type) {
        case MessageType.image:
          sendMessage(imageUrl: downloadUrl);
          break;
        case MessageType.audio:
          sendMessage(audioUrl: downloadUrl, audioDuration: audioDuration);
          break;
        case MessageType.document:
          sendMessage(document: {'url': downloadUrl, 'name': message.fileName, 'size': message.fileSize});
          break;
        case MessageType.music:
          sendMessage(music: {'url': downloadUrl, 'name': message.fileName, 'size': message.fileSize});
          break;
        case MessageType.video:
          break;
      }
    });
  }

  Future<void> pickFromCamera() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;
    
    final file = File(pickedFile.path);
    final message = UploadingMessage(
      id: const Uuid().v4(),
      filePath: pickedFile.path,
      type: MessageType.image,
      fileSize: await file.length(),
    );
    
    final uploadTask = storageService.uploadChatImage(chatId: chatId, file: file);
    handleFileUpload(uploadTask, message);
  }

  Future<void> pickFromGallery() async {
    final pickedFile = await ImagePicker().pickMedia();
    if (pickedFile == null) return;
    final file = File(pickedFile.path);

    if (pickedFile.path.toLowerCase().endsWith('.mp4') || pickedFile.path.toLowerCase().endsWith('.mov')) {
        final message = UploadingMessage(
          id: const Uuid().v4(),
          filePath: pickedFile.path,
          type: MessageType.video,
          fileSize: await file.length(),
        );
        _uploadingMessages.insert(0, message);
        notifyListeners();

        final urls = await storageService.uploadChatVideo(
          chatId: chatId,
          file: file,
          onProgress: (progress) {
            final index = _uploadingMessages.indexWhere((m) => m.id == message.id);
            if (index != -1) {
              _uploadingMessages[index].progress = progress;
              notifyListeners();
            }
          }
        );

        _uploadingMessages.removeWhere((m) => m.id == message.id);
        notifyListeners();
        if (urls != null) {
          sendMessage(videoUrl: urls['videoUrl'], thumbnailUrl: urls['thumbnailUrl']);
        }
    } else {
       final message = UploadingMessage(
          id: const Uuid().v4(),
          filePath: pickedFile.path,
          type: MessageType.image,
          fileSize: await file.length(),
        );
        final uploadTask = storageService.uploadChatImage(chatId: chatId, file: file);
        handleFileUpload(uploadTask, message);
    }
  }

  Future<void> pickFile(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: type == 'music' ? FileType.audio : FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      final message = UploadingMessage(
        id: const Uuid().v4(),
        filePath: file.path!,
        fileName: file.name,
        fileSize: file.size,
        type: type == 'music' ? MessageType.music : MessageType.document,
      );
      final uploadTask = storageService.uploadChatFile(
        chatId: chatId,
        filePath: file.path!,
        folder: type == 'music' ? 'music' : 'documents',
      );
      handleFileUpload(uploadTask, message);
    }
  }

  Future<void> showContactPicker(String otherUserUid) async {
    final contacts = await firestoreService.getContactsStream().first;
    final filteredContacts = contacts.where((c) => c.uid != otherUserUid).toList();

    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Compartir Contacto'),
          content: SizedBox(
            width: double.maxFinite,
            child: filteredContacts.isEmpty
              ? const Text('No tienes otros contactos para compartir.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    return ListTile(
                      title: Text(contact.displayName ?? 'Sin nombre'),
                      onTap: () {
                        sendMessage(contact: {
                          'uid': contact.uid,
                          'name': contact.displayName ?? 'Sin nombre',
                          'phone': contact.phoneNumber ?? 'No disponible',
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
          ),
        );
      },
    );
  }

  void sendMessage({
    String? text,
    String? imageUrl,
    String? videoUrl,
    String? thumbnailUrl,
    String? audioUrl,
    int? audioDuration,
    Map<String, String>? contact,
    Map<String, dynamic>? document,
    Map<String, dynamic>? music,
  }) {
    firestoreService.sendMessage(
      chatId: chatId,
      senderId: currentUserId,
      recipientId: otherUserId,
      text: text,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      audioUrl: audioUrl,
      audioDuration: audioDuration,
      contact: contact,
      document: document,
      music: music,
    );
  }

  void onMessageLongPress(DocumentSnapshot messageDoc, LongPressStartDetails details) {
    final messageId = messageDoc.id;
    final alreadySelected = _selectedMessages.any((doc) => doc.id == messageId);

    if (_isSelectionMode) {
      if (alreadySelected) {
        _selectedMessages.removeWhere((doc) => doc.id == messageId);
        if (_selectedMessages.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedMessages.add(messageDoc);
      }
    } else {
      _isSelectionMode = true;
      _selectedMessages.add(messageDoc);
      _showReactionOverlay(messageDoc, details.globalPosition);
    }
    notifyListeners();
  }

  void _showReactionOverlay(DocumentSnapshot messageDoc, Offset tapPosition) async {
    final selectedReaction = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1), // Un fondo sutil
      builder: (BuildContext context) {
        // Calcula el tamaño y la posición del overlay
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = screenWidth * 0.8; // El diálogo ocupa el 80% del ancho
        final dialogHeight = 52.0; // Altura fija

        // Centra el diálogo horizontalmente en la posición del toque, pero evita que se salga de la pantalla
        final left = (tapPosition.dx - (dialogWidth / 2)).clamp(8.0, screenWidth - dialogWidth - 8.0);
        // Posiciona el diálogo encima del mensaje
        final top = (tapPosition.dy - dialogHeight - 12).clamp(8.0, MediaQuery.of(context).size.height - dialogHeight - 8.0);

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: SizedBox(
                width: dialogWidth,
                height: dialogHeight,
                child: _ReactionsDialog(),
              ),
            ),
          ],
        );
      },
    );

    if (selectedReaction != null) {
      await firestoreService.toggleReaction(chatId, messageDoc.id, selectedReaction);
      exitSelectionMode();
    } else {
      // Per the original logic, do nothing if no reaction is selected,
      // leaving the user in selection mode.
    }
  }

  void exitSelectionMode() {
    if (_isSelectionMode) {
      _isSelectionMode = false;
      _selectedMessages.clear();
      notifyListeners();
    }
  }

  void showDeleteMessageDialog() async {
    final result = await showDeleteDialog(context, _selectedMessages.length);

    if (result != null) {
      if (result == 'all') {
        for (final message in _selectedMessages) {
          firestoreService.deleteMessageForEveryone(chatId: chatId, messageId: message.id);
        }
      } else if (result == 'me') {
        for (final message in _selectedMessages) {
          firestoreService.deleteMessageForMe(chatId, message.id);
        }
      }
      exitSelectionMode();
    }
  }

  void copySelectedMessage() {
    if (_selectedMessages.isNotEmpty) {
      final text = (_selectedMessages.first.data() as Map<String, dynamic>)['text'] as String?;
      if (text != null && text.isNotEmpty) {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensaje copiado.')),
        );
      }
    }
    exitSelectionMode();
  }
}

// --- WIDGET DE DIÁLOGO DE REACCIONES MEJORADO ---
// Más pequeño, deslizable y con un estilo similar a WhatsApp.
class _ReactionsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Lista de emojis ampliada para que el deslizamiento sea útil
    final reactions = ['👍', '❤️', '😂', '😯', '😢', '🙏', '🔥', '🎉', '💯', '👏', '😮', '😍'];
    final theme = Theme.of(context);

    return Card(
      color: theme.dialogTheme.backgroundColor,
      shape: theme.dialogTheme.shape ?? const StadiumBorder(), // Bordes redondeados como una píldora
      elevation: theme.dialogTheme.elevation ?? 8,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: reactions.length,
        itemBuilder: (context, index) {
          final reaction = reactions[index];
          return InkWell(
            onTap: () => Navigator.pop(context, reaction),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Text(
                  reaction,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}