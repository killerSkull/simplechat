import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:simplechat/screens/call_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:simplechat/models/uploading_message_model.dart';
import 'package:simplechat/models/user_model.dart';
import 'package:simplechat/screens/chat/components/attachment_menu.dart';
import 'package:simplechat/screens/chat/components/selection_app_bar.dart';
import 'package:simplechat/screens/chat/logic/chat_state_manager.dart';
import 'package:simplechat/screens/chat/widgets/chat_app_bar.dart';
import 'package:simplechat/screens/chat/widgets/message_input_bar.dart';
import 'package:simplechat/screens/chat/widgets/message_list.dart';
import 'package:simplechat/services/firestore_service.dart';
import 'package:simplechat/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  final UserModel otherUser;
  final String? nickname;
  final String chatId;

  const ChatScreen({super.key, required this.otherUser, this.nickname, required this.chatId,});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late final ChatStateManager _chatManager;
  late final FirestoreService _firestoreService;
  late final StorageService _storageService;
  final _messageController = TextEditingController();
  Query? _messagesQuery;
  bool _isEmojiPickerVisible = false;
  Timer? _typingTimer;
  bool _isContact = false;
  bool _isSearching = false;
  final _searchController = TextEditingController();
  StreamSubscription? _chatSubscription;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  StreamSubscription? _recorderSubscription;
  Timestamp? _currentClearedAtTimestamp;

  @override
  void initState() {
    super.initState();
    _firestoreService = context.read<FirestoreService>();
    _storageService = context.read<StorageService>();
    final currentUser = _firestoreService.auth.currentUser!;

    _messagesQuery = _firestoreService.getMessagesQuery(widget.chatId);

    _chatManager = ChatStateManager(
      context: context,
      firestoreService: _firestoreService,
      storageService: _storageService,
      chatId: widget.chatId,
      currentUserId: currentUser.uid,
      otherUserId: widget.otherUser.uid,
    );

    _chatManager.addListener(() => setState(() {}));

    WidgetsBinding.instance.addObserver(this);
    _firestoreService.updateUserActiveChat(widget.chatId);

    _listenForChatUpdates(widget.chatId, currentUser.uid);
    _checkIfContact();
    _firestoreService.markMessagesAsRead(
        chatId: widget.chatId, currentUserId: currentUser.uid);
    _searchController.addListener(() => setState(() {}));

    _recorder.openRecorder().then((value) {
      if (mounted) {
        setState(() => _isRecorderInitialized = true);
        _recorder.setSubscriptionDuration(const Duration(milliseconds: 500));
        _recorderSubscription = _recorder.onProgress!.listen((e) {
          if (mounted) setState(() => _recordingDuration = e.duration);
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _firestoreService.updateUserActiveChat(null);
    _chatManager.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _typingTimer?.cancel();
    _chatSubscription?.cancel();
    _recorderSubscription?.cancel();
    _recorder.closeRecorder();
    _firestoreService.updateTypingStatus(
        chatId: _chatManager.chatId,
        currentUserId: _chatManager.currentUserId,
        isTyping: false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _firestoreService.updateUserActiveChat(_chatManager.chatId);
    } else if (state == AppLifecycleState.paused) {
      _firestoreService.updateUserActiveChat(null);
    }
  }

  void _listenForChatUpdates(String chatId, String currentUserId) {
    _chatSubscription =
        _firestoreService.getChatStream(chatId).listen((chatSnapshot) {
      if (mounted) {
        Timestamp? newClearedAtTimestamp;
        if (chatSnapshot.exists) {
            final chatData = chatSnapshot.data() as Map<String, dynamic>;
            final clearedAtField = 'cleared_at_for_$currentUserId';
            newClearedAtTimestamp = chatData[clearedAtField] as Timestamp?;
        }
        
        if (newClearedAtTimestamp != _currentClearedAtTimestamp) {
          Query newQuery = _firestoreService.getMessagesQuery(chatId);
          if (newClearedAtTimestamp != null) {
            newQuery =
                newQuery.where('timestamp', isGreaterThan: newClearedAtTimestamp);
          }
          setState(() {
            _messagesQuery = newQuery;
            _currentClearedAtTimestamp = newClearedAtTimestamp;
          });
        }
      }
    });
  }

  void _checkIfContact() async {
    final isContact = await _firestoreService.isContact(widget.otherUser.uid);
    if (mounted) setState(() => _isContact = isContact);
  }

  void _onTextChanged(String text) {
    _typingTimer?.cancel();
    if (text.isNotEmpty) {
      _firestoreService.updateTypingStatus(
          chatId: _chatManager.chatId,
          currentUserId: _chatManager.currentUserId,
          isTyping: true);
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _firestoreService.updateTypingStatus(
            chatId: _chatManager.chatId,
            currentUserId: _chatManager.currentUserId,
            isTyping: false);
      });
    } else {
      _firestoreService.updateTypingStatus(
          chatId: _chatManager.chatId,
          currentUserId: _chatManager.currentUserId,
          isTyping: false);
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!mounted || status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se necesita permiso del micrófono.')),
      );
      return;
    }
    if (!_isRecorderInitialized) return;

    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/${const Uuid().v4()}.aac';

    await _recorder.startRecorder(toFile: path, codec: Codec.aacADTS);

    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecorderInitialized || !_isRecording) return;

    final path = await _recorder.stopRecorder();

    setState(() => _isRecording = false);

    if (path != null) {
      final file = File(path);
      final message = UploadingMessage(
        id: const Uuid().v4(),
        filePath: path,
        fileSize: await file.length(),
        type: MessageType.audio,
      );
      final uploadTask = _storageService.uploadChatAudio(
          chatId: _chatManager.chatId, filePath: path);
      _chatManager.handleFileUpload(uploadTask, message,
          audioDuration: _recordingDuration.inMilliseconds);
    }
  }

  void _showClearChatConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Vaciar Chat'),
          content: const Text(
              '¿Estás seguro de que quieres eliminar todos los mensajes de este chat solo para ti?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Vaciar'),
              onPressed: () async {
                await _firestoreService.clearChatForUser(
                    chatId: _chatManager.chatId);
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportChat() async {
    final currentUserDoc = await _firestoreService.db
        .collection('users')
        .doc(_chatManager.currentUserId)
        .get();
    final currentUserModel = UserModel.fromFirestore(currentUserDoc);
    final chatHistory = await _firestoreService.exportChatHistory(
      chatId: _chatManager.chatId,
      currentUser: currentUserModel,
      otherUser: widget.otherUser,
    );
    if (!mounted) return;
    if (chatHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay mensajes para exportar.')),
      );
      return;
    }
    final tempDir = await getTemporaryDirectory();
    final fileName = 'Chat con ${widget.otherUser.displayName}.txt';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(chatHistory);
    await Share.shareXFiles([XFile(file.path)],
        text: 'Historial de chat de SimpleChat');
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'Vaciar chat':
        _showClearChatConfirmationDialog();
        break;
      case 'Exportar chat':
        _exportChat();
        break;
      case 'Buscar en el chat':
        setState(() => _isSearching = true);
        break;
    }
  }
  
  /// --- LÓGICA DE LLAMADA ACTUALIZADA ---
  Future<void> _startCall(bool isVideoCall) async {
    // 1. Pedir permisos
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus.isGranted && micStatus.isGranted) {
      final channelName = widget.chatId;

      // 2. Iniciar la llamada en Firestore. Esto creará el documento y
      //    activará la función en la nube para enviar la notificación.
      await _firestoreService.startCall(
        chatId: channelName,
        recipientId: widget.otherUser.uid,
        isVideoCall: isVideoCall,
      );

      // 3. Escuchar el documento de la llamada para obtener el token.
      final callStream = _firestoreService.getCallStream(channelName);
      final callDoc = await callStream.firstWhere((doc) =>
          doc.exists && (doc.data() as Map<String, dynamic>).containsKey('token'));
      
      final callData = callDoc.data() as Map<String, dynamic>;
      
      // 4. Navegar a la pantalla de llamada con los datos correctos.
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              channelName: channelName,
              token: callData['token'],
              otherUserName: widget.nickname ?? widget.otherUser.displayName ?? 'Usuario',
              isVideoCall: isVideoCall, callId: '',
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se necesitan permisos de cámara y micrófono.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _chatManager.isSelectionMode
          ? SelectionAppBar(
              selectedMessages: _chatManager.selectedMessages,
              onExitSelection: _chatManager.exitSelectionMode,
              onCopy: _chatManager.copySelectedMessage,
              onDelete: _chatManager.showDeleteMessageDialog,
            )
          : ChatAppBar(
              onStartVideoCall: () => _startCall(true),
              onStartVoiceCall: () => _startCall(false),
              otherUser: widget.otherUser,
              nickname: widget.nickname,
              chatId: _chatManager.chatId,
              isSearching: _isSearching,
              onToggleSearch: (isSearching) => setState(() {
                _isSearching = isSearching;
                if (!isSearching) _searchController.clear();
              }),
              searchController: _searchController,
              onMenuSelected: _handleMenuSelection,
            ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: MessageList(
                messagesQuery: _messagesQuery,
                uploadingMessages: _chatManager.uploadingMessages,
                isSearching: _isSearching,
                searchQuery: _searchController.text,
                onLongPressMessage: _chatManager.onMessageLongPress,
                selectedMessages:
                    _chatManager.selectedMessages.map((doc) => doc.id).toList(),
                onAddContact: (uid, name) {
                  _firestoreService.addContact(uid, name);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('$name ha sido añadido a tus contactos.')),
                  );
                },
              ),
            ),
            if (!_isSearching && !_chatManager.isSelectionMode)
              MessageInputBar(
                messageController: _messageController,
                isContact: _isContact,
                isEmojiPickerVisible: _isEmojiPickerVisible,
                onSendMessage: () {
                  final text = _messageController.text.trim();
                  if (text.isNotEmpty) {
                    _chatManager.sendMessage(text: text);
                    _messageController.clear();
                    _typingTimer?.cancel();
                    _firestoreService.updateTypingStatus(
                        chatId: _chatManager.chatId,
                        currentUserId: _chatManager.currentUserId,
                        isTyping: false);
                  }
                },
                onSendMedia: () => showAttachmentMenu(
                  context,
                  onPickFromCamera: _chatManager.pickFromCamera,
                  onPickFromGallery: _chatManager.pickFromGallery,
                  onPickMusic: () => _chatManager.pickFile('music'),
                  onPickContact: () =>
                      _chatManager.showContactPicker(widget.otherUser.uid),
                  onPickDocument: () => _chatManager.pickFile('document'),
                ),
                onTextChanged: _onTextChanged,
                toggleEmojiPicker: () => setState(() {
                  _isEmojiPickerVisible = !_isEmojiPickerVisible;
                  if (_isEmojiPickerVisible) FocusScope.of(context).unfocus();
                }),
                onOpenCamera: _chatManager.pickFromCamera,
                isRecording: _isRecording,
                isRecorderInitialized: _isRecorderInitialized,
                recordingDuration: _recordingDuration,
                onStartRecording: _startRecording,
                onStopRecording: _stopRecording,
                onAddContact: () async {
                  await _firestoreService.addContact(
                      widget.otherUser.uid, widget.otherUser.displayName ?? '');
                  _checkIfContact();
                },
              ),
          ],
        ),
      ),
    );
  }
}
