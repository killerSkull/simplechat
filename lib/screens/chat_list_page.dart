import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:simplechat/screens/add_contact_screen.dart' hide showProfilePreview;
import 'package:simplechat/screens/chat/widgets/profile_preview_card.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot>? _chatsStream;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _chatsStream = _firestoreService.getChatsStream();
    }
  }

  void _showChatOptionsDialog(BuildContext context, UserModel user, String? nickname, String chatId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(nickname ?? user.displayName ?? 'Opciones'),
          contentPadding: const EdgeInsets.only(top: 12.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined),
                title: const Text('Ocultar Chat'),
                subtitle: const Text('El chat desaparecerá de tu lista'),
                onTap: () {
                  Navigator.pop(context);
                  _showHideChatConfirmation(context, chatId);
                },
              ),
              ListTile(
                leading: Icon(Icons.person_remove, color: Colors.red.shade400),
                title: Text('Eliminar Contacto', style: TextStyle(color: Colors.red.shade400)),
                subtitle: Text('Se borrará el contacto y el chat', style: TextStyle(color: Colors.red.shade400.withOpacity(0.8))),
                onTap: () {
                   Navigator.pop(context);
                  _showDeleteContactConfirmation(context, user, nickname, chatId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHideChatConfirmation(BuildContext context, String chatId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Ocultar este chat?'),
          content: const Text('Los mensajes se borrarán solo para ti y la conversación desaparecerá de tu lista.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Ocultar'),
              onPressed: () async {
                await _firestoreService.clearChatForUser(chatId: chatId);
                await _firestoreService.hideChatForUser(chatId: chatId);

                if (mounted) {
                  Navigator.of(context).pop();
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat ocultado y vaciado.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }


  void _showDeleteContactConfirmation(BuildContext context, UserModel userToDelete, String? nickname, String chatId) {
     showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Contacto'),
          content: Text('¿Estás seguro de que quieres eliminar a ${nickname ?? userToDelete.displayName ?? 'este usuario'}? El contacto y todo el historial de chat se eliminarán permanentemente.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar Contacto'),
              onPressed: () async {
                await _firestoreService.deleteContact(userToDelete.uid);
                await _firestoreService.deleteChat(chatId);
                if (mounted) {
                  Navigator.of(context).pop();
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${nickname ?? userToDelete.displayName ?? 'Usuario'} eliminado.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SimpleChat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(child: _buildUserList()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddContactScreen()),
          );
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildUserList() {
    if (_currentUser == null) {
      return const Center(child: Text('Inicia sesión para ver tus chats.'));
    }

    return StreamBuilder<Map<String, String>>(
      stream: _firestoreService.getContactsMapStream(),
      builder: (context, contactsSnapshot) {
        final contactsMap = contactsSnapshot.data ?? {};
        
        return StreamBuilder<QuerySnapshot>(
          stream: _chatsStream,
          builder: (context, chatSnapshot) {
            if (chatSnapshot.hasError) {
              print("Error en el stream de chats: ${chatSnapshot.error}");
              return const Center(child: Text('Ocurrió un error al cargar los chats.'));
            }
            if (chatSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(25.0),
                  child: Text(
                    'Tu lista de chats está vacía.\nToca el botón + para añadir un contacto.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              );
            }

            final chatDocs = chatSnapshot.data!.docs;
            
            final partnerUids = chatDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final participants = List<String>.from(data['participants'] ?? []);
              return participants.firstWhere((uid) => uid != _currentUser!.uid, orElse: () => '');
            }).where((uid) => uid.isNotEmpty).toSet().toList();

            if (partnerUids.isEmpty) {
              return const Center(child: Text('Inicia una conversación para verla aquí.'));
            }
            
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: partnerUids).snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final userMap = {for (var doc in userSnapshot.data!.docs) doc.id: UserModel.fromFirestore(doc)};

                return ListView.builder(
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    final chatDoc = chatDocs[index];
                    final chatDocData = chatDoc.data() as Map<String, dynamic>;
                    final participants = List<String>.from(chatDocData['participants'] ?? []);
                    final partnerUid = participants.firstWhere((uid) => uid != _currentUser!.uid, orElse: () => '');

                    if (partnerUid.isEmpty) return const SizedBox.shrink();

                    final user = userMap[partnerUid];
                    if (user == null) return const SizedBox.shrink();

                    // --- INICIO DE LA IMPLEMENTACIÓN DE TICKS ---
                    final lastMessage = chatDocData['last_message_text'] as String? ?? '';
                    final timestamp = (chatDocData['last_message_timestamp'] as Timestamp?)?.toDate();
                    final nickname = contactsMap[user.uid];
                    final lastMessageSender = chatDocData['last_message_sender_uid'] as String?;
                    final lastMessageStatus = chatDocData['last_message_status'] as String?;
                    final isSentByMe = lastMessageSender == _currentUser!.uid;
                    // --- FIN DE LA IMPLEMENTACIÓN DE TICKS ---
                    
                    return ListTile(
                      onLongPress: () => _showChatOptionsDialog(context, user, nickname, chatDoc.id),
                      leading: GestureDetector(
                        onTap: () => showProfilePreview(context, user, nickname, chatDoc.id),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                  ? CachedNetworkImageProvider(user.photoUrl!)
                                  : null,
                              child: user.photoUrl == null || user.photoUrl!.isEmpty
                                  ? const Icon(Icons.person, size: 30)
                                  : null,
                            ),
                            if (user.presence)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 15,
                                  height: 15,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      title: Text(nickname ?? user.displayName ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.bold)),
                      // --- SUBTÍTULO MODIFICADO PARA INCLUIR TICKS ---
                      subtitle: Row(
                        children: [
                          if (isSentByMe) ...[
                            _buildStatusIcon(lastMessageStatus),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      trailing: timestamp != null
                          ? Text(
                              DateFormat('HH:mm').format(timestamp),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            )
                          : const SizedBox.shrink(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              otherUser: user,
                              nickname: nickname,
                              chatId: chatDoc.id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
  
  // --- WIDGET HELPER PARA LOS TICKS ---
  Widget _buildStatusIcon(String? status) {
    IconData iconData;
    Color? color;
    switch (status) {
        case 'sent':
          iconData = Icons.done;
          break;
        case 'delivered':
          iconData = Icons.done_all;
          break;
        case 'read':
          iconData = Icons.done_all;
          color = Colors.lightBlueAccent;
          break;
        // No mostramos nada para 'sending' o si el estado es nulo
        default:
          return const SizedBox.shrink();
    }
    return Icon(iconData, size: 18, color: color ?? Colors.grey);
  }
}