import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:simplechat/screens/add_contact_screen.dart';
import 'package:simplechat/screens/chat_list/widgets/chat_list_item.dart';
import 'package:simplechat/screens/chat_list/widgets/expanding_fab.dart';
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

  // --- FUNCIÓN para manejar la navegación a "Mensajes Guardados" ---
  void _goToSavedMessages() async {
    if (_currentUser == null) return;
    
    // Usamos el servicio para obtener o crear el chat
    final chatId = await _firestoreService.getOrCreateSavedMessagesChat();

    // Obtenemos el modelo de usuario del usuario actual
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
    final currentUserModel = UserModel.fromFirestore(userDoc);
    
    if (mounted) {
       Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            // Le pasamos nuestro propio usuario como "el otro usuario"
            otherUser: currentUserModel, 
            nickname: "Mensajes Guardados",
            chatId: chatId,
          ),
        ),
      );
    }
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
      // --- REEMPLAZO: Usamos el nuevo widget ExpandingFab ---
      floatingActionButton: ExpandingFab(
        distance: 112.0,
        actions: [
          ActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddContactScreen())),
            icon: Icons.person_add,
            tooltip: 'Añadir Contacto',
          ),
          ActionButton(
            onPressed: _goToSavedMessages,
            icon: Icons.bookmark,
            tooltip: 'Mensajes Guardados',
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    if (_currentUser == null) {
      return const Center(child: Text('Inicia sesión para ver tus chats.'));
    }

    // Stream anidado para obtener primero los apodos y luego los chats
    return StreamBuilder<Map<String, String>>(
      stream: _firestoreService.getContactsMapStream(),
      builder: (context, contactsSnapshot) {
        final contactsMap = contactsSnapshot.data ?? {};
        
        return StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getChatsStream(),
          builder: (context, chatSnapshot) {
            if (chatSnapshot.hasError) {
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

            var chatDocs = chatSnapshot.data!.docs;
            
            // --- LÓGICA DE ORDENAMIENTO ---
            chatDocs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aIsPinned = (aData['pinned_for'] as List<dynamic>? ?? []).contains(_currentUser!.uid);
              final bIsPinned = (bData['pinned_for'] as List<dynamic>? ?? []).contains(_currentUser!.uid);

              if (aIsPinned && !bIsPinned) return -1;
              if (!aIsPinned && bIsPinned) return 1;

              final aTimestamp = aData['last_message_timestamp'] as Timestamp?;
              final bTimestamp = bData['last_message_timestamp'] as Timestamp?;
              return (bTimestamp ?? Timestamp.now()).compareTo(aTimestamp ?? Timestamp.now());
            });

            // Stream anidado final para obtener los perfiles de usuario
            return StreamBuilder<QuerySnapshot>(
              stream: _getUsersStream(chatDocs),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final userMap = {for (var doc in userSnapshot.data!.docs) doc.id: UserModel.fromFirestore(doc)};

                return ListView.builder(
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    final chatDoc = chatDocs[index];
                    final chatDocData = {
                      ...chatDoc.data() as Map<String, dynamic>,
                      'id': chatDoc.id // Añadimos el ID para pasarlo al preview
                    };

                    // --- NUEVA LÓGICA para identificar el chat de "Mensajes Guardados" ---
                    final isSavedMessages = chatDocData['is_saved_messages'] as bool? ?? false;

                    if (isSavedMessages) {
                      return _buildSavedMessagesItem(chatDocData);
                    }
                    
                    final partnerUid = (chatDocData['participants'] as List<dynamic>).firstWhere((uid) => uid != _currentUser!.uid, orElse: () => '');

                    if (partnerUid.isEmpty) return const SizedBox.shrink();
                    final user = userMap[partnerUid];
                    if (user == null) return const SizedBox.shrink();
                    
                    final nickname = contactsMap[user.uid];
                    final wasSentByMe = chatDocData['last_message_sender_uid'] == _currentUser!.uid;
                    final lastMessageStatus = chatDocData['last_message_status'] as String?;
                    final unreadCounterField = 'unread_count_for_${_currentUser!.uid}';
                    final unreadCount = chatDocData.containsKey(unreadCounterField) ? (chatDocData[unreadCounterField] as int) : 0;
                    
                    // --- CORRECCIÓN 1 (de nuevo): Se usa 'pinned_for' para determinar si está anclado ---
                    final isPinned = (chatDocData['pinned_for'] as List<dynamic>? ?? []).contains(_currentUser!.uid);
                    
                    // --- USANDO EL NUEVO WIDGET ---
                    return ChatListItem(
                      user: user,
                      chatDocData: chatDocData,
                      nickname: nickname,
                      wasSentByMe: wasSentByMe,
                      lastMessageStatus: lastMessageStatus,
                      unreadCount: unreadCount,
                      isPinned: isPinned,
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
                      onLongPress: () => _showChatOptionsDialog(context, user, nickname, chatDoc.id, isPinned),
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

  // --- WIDGET HELPER para mostrar el item de "Mensajes Guardados" ---
  Widget _buildSavedMessagesItem(Map<String, dynamic> chatDocData) {
     final lastMessageText = chatDocData['last_message_text'] as String? ?? '';
     final timestamp = (chatDocData['last_message_timestamp'] as Timestamp?)?.toDate();
     final unreadCounterField = 'unread_count_for_${_currentUser!.uid}';
     final unreadCount = chatDocData.containsKey(unreadCounterField) ? (chatDocData[unreadCounterField] as int) : 0;

    return ListTile(
      leading: const CircleAvatar(
        radius: 28,
        child: Icon(Icons.bookmark, size: 30),
      ),
      title: const Text('Mensajes Guardados', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        lastMessageText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: (timestamp != null) 
          ? Text(DateFormat('HH:mm').format(timestamp), style: const TextStyle(color: Colors.grey, fontSize: 12)) 
          : null,
      onTap: _goToSavedMessages, // Reutilizamos la función de navegación
    );
  }

  // Helper para obtener el stream de usuarios
  Stream<QuerySnapshot> _getUsersStream(List<QueryDocumentSnapshot> chatDocs) {
      final partnerUids = chatDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        return participants.firstWhere((uid) => uid != _currentUser!.uid, orElse: () => '');
      }).where((uid) => uid.isNotEmpty).toSet().toList();

      if (partnerUids.isEmpty) return const Stream.empty();

      return FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: partnerUids).snapshots();
  }

  // Los métodos para mostrar diálogos se mantienen aquí
  void _showChatOptionsDialog(BuildContext context, UserModel user, String? nickname, String chatId, bool isPinned) {
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
                leading: Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin),
                title: Text(isPinned ? 'Desfijar Chat' : 'Fijar Chat'),
                onTap: () {
                  Navigator.pop(context);
                  if (isPinned) {
                    _firestoreService.unpinChat(chatId);
                  } else {
                    _firestoreService.pinChat(chatId);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined),
                title: const Text('Ocultar Chat'),
                onTap: () {
                  Navigator.pop(context);
                  _showHideChatConfirmation(context, chatId);
                },
              ),
              ListTile(
                leading: Icon(Icons.person_remove, color: Colors.red.shade400),
                title: Text('Eliminar Contacto', style: TextStyle(color: Colors.red.shade400)),
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