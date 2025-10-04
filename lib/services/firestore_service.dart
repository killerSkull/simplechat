import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:simplechat/models/user_model.dart';
import 'package:simplechat/services/storage_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // --- FUNCIÓN NUEVA: Para crear o recuperar el chat de "Mensajes Guardados" ---
  Future<String> getOrCreateSavedMessagesChat() async {
    final user = auth.currentUser;
    if (user == null) throw Exception("Usuario no autenticado");
    
    final chatId = 'saved_${user.uid}';
    final chatRef = _db.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        'participants': [user.uid],
        'is_saved_messages': true, // Flag para identificar este chat especial
        'last_message_text': 'Tus mensajes guardados aparecerán aquí.',
        'last_message_timestamp': FieldValue.serverTimestamp(),
        'last_message_sender_uid': user.uid,
        'pinned_for': [user.uid], // Anclado por defecto
        'visible_for': [user.uid],
        'created_at': FieldValue.serverTimestamp(),
      });
    }
    
    return chatId;
  }

  // --- BUG 2 FIX: Nuevo método para actualizar mensajes ---
   // --- FUNCIÓN QUE FALTABA ---
  Future<void> updateMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    // Actualiza el mensaje específico
    await _db.collection('chats').doc(chatId).collection('messages').doc(messageId).update({
      'text': newText,
      'is_edited': true,
    });

    // Revisa si el mensaje editado era el último del chat para actualizar la vista previa
    final chatDoc = await _db.collection('chats').doc(chatId).get();
    if (chatDoc.exists) {
      final lastMessageSnapshot = await _db.collection('chats').doc(chatId).collection('messages').orderBy('timestamp', descending: true).limit(1).get();
      if (lastMessageSnapshot.docs.isNotEmpty && lastMessageSnapshot.docs.first.id == messageId) {
        await _db.collection('chats').doc(chatId).update({
          'last_message_text': newText,
        });
      }
    }
  }

  // --- MÉTODO QUE FALTABA (RESTAURADO) ---
  /// Actualiza el campo 'current_chat_id' del usuario para saber si está en un chat.
  Future<void> updateUserActiveChat(String? chatId) async {
    final user = auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).set({
      'current_chat_id': chatId,
    }, SetOptions(merge: true));
  }
  
  Future<String?> startCall({
    required String recipientId,
    required bool isVideoCall,
  }) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) return null;
    try {
      final userDoc = await _db.collection('users').doc(currentUser.uid).get();
      final currentUserName = (userDoc.data() as Map<String, dynamic>)['display_name'] ?? 'Alguien';
      final callDocRef = _db.collection('calls').doc();
      await callDocRef.set({
        'caller_id': currentUser.uid,
        'caller_name': currentUserName,
        'receiver_id': recipientId,
        'is_video_call': isVideoCall,
        'status': 'ringing',
        'created_at': FieldValue.serverTimestamp(),
      });
      return callDocRef.id;
    } catch (e) {
      print("Error al iniciar llamada en Firestore: $e");
      return null;
    }
  }

  Stream<DocumentSnapshot> getCallStream(String callId) {
    if (callId.isEmpty) return const Stream.empty();
    return _db.collection('calls').doc(callId).snapshots();
  }

  Future<void> answerCall(String callId) async {
    await _db.collection('calls').doc(callId).update({'status': 'ongoing'});
  }

  Future<void> endCall(String callId, String currentUserId) async {
    if (callId.isEmpty) return;
    try {
      await _db.collection('calls').doc(callId).delete();
    } catch (e) {
      print("Error al finalizar la llamada (puede que ya no exista): $e");
    }
  }

  // Edit Message
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    await _db.collection('chats').doc(chatId).collection('messages').doc(messageId).update({
      'text': newText,
      'is_edited': true,
      'edited_at': FieldValue.serverTimestamp(),
    });
  }

  // PinChat
  Future<void> pinChat(String chatId) async {
    final user = auth.currentUser;
    if (user == null) return;
    await _db.collection('chats').doc(chatId).set({
      'pinned_for': FieldValue.arrayUnion([user.uid])
    }, SetOptions(merge: true));
  }
  /// Desfija un chat para el usuario actual.
  Future<void> unpinChat(String chatId) async {
    final user = auth.currentUser;
    if (user == null) return;
    await _db.collection('chats').doc(chatId).set({
      'pinned_for': FieldValue.arrayRemove([user.uid])
    }, SetOptions(merge: true));
  }
  
  String getChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode ? '$user1-$user2' : '$user2-$user1';
  }

  Stream<QuerySnapshot> getChatsStream() {
    final user = auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db
        .collection('chats')
        .where('visible_for', arrayContains: user.uid)
        .orderBy('last_message_timestamp', descending: true)
        .snapshots();
  }
  
  Future<void> saveUserToken(String token) async {
    final user = auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).set({
      'fcm_token': token,
    }, SetOptions(merge: true));
  }
  
  Future<void> createUserProfile(User user) async {
    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'display_name': user.displayName ?? '',
      'photo_url': user.photoURL ?? '',
      'status': '¡Hola! Estoy usando SimpleChat.',
      'phone_number': user.phoneNumber,
      'created_at': FieldValue.serverTimestamp(),
      'presence': true,
      'last_seen': FieldValue.serverTimestamp(),
      'profile_completed': false,
      'visible_for': [user.uid],
    }, SetOptions(merge: true));
  }
  
  Future<void> updateUserProfile({
    required String uid,
    required String displayName,
    required String status,
    String? phoneNumber,
    String? photoUrl,
    bool? profileCompleted,
  }) async {
    final dataToUpdate = {
      'display_name': displayName,
      'status': status,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (profileCompleted != null) 'profile_completed': profileCompleted,
    };
    await _db.collection('users').doc(uid).set(dataToUpdate, SetOptions(merge: true));
  }

  Future<void> updateUserPresence({required bool isOnline}) async {
    final user = auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).set({
      'presence': isOnline,
      'last_seen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<QuerySnapshot> searchUserByPhone(String phoneNumber) {
    return _db
        .collection('users')
        .where('phone_number', isEqualTo: phoneNumber)
        .limit(1)
        .get();
  }
  
  Future<bool> isContact(String contactUid) async {
    final user = auth.currentUser;
    if (user == null) return false;
    final doc = await _db
        .collection('users')
        .doc(user.uid)
        .collection('contacts')
        .doc(contactUid)
        .get();
    return doc.exists;
  }
  
  Future<void> addContact(String contactUid, String nickname) async {
    final user = auth.currentUser;
    if (user == null) return;
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('contacts')
        .doc(contactUid)
        .set({
          'added_at': FieldValue.serverTimestamp(),
          'nickname': nickname,
        });
  }

  Future<void> updateContactNickname(String contactUid, String newNickname) async {
    final user = auth.currentUser;
    if (user == null) return;
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('contacts')
        .doc(contactUid)
        .update({'nickname': newNickname});
  }

  Future<void> deleteContact(String contactUid) async {
    final user = auth.currentUser;
    if (user == null) return;
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('contacts')
        .doc(contactUid)
        .delete();
  }
  
  Stream<Map<String, String>> getContactsMapStream() {
    final user = auth.currentUser;
    if (user == null) return Stream.value({});
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('contacts')
        .snapshots()
        .map((snapshot) {
      final map = <String, String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        map[doc.id] = data['nickname'] as String? ?? '';
      }
      return map;
    });
  }
  
  Stream<List<UserModel>> getContactsStream() {
    final user = auth.currentUser;
    if (user == null) return Stream.value([]);
    return _db.collection('users').doc(user.uid).collection('contacts').snapshots().asyncMap((snapshot) async {
      final contactUids = snapshot.docs.map((doc) => doc.id).toList();
      if (contactUids.isEmpty) return [];
      final userDocs = await _db.collection('users').where(FieldPath.documentId, whereIn: contactUids).get();
      return userDocs.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  Stream<DocumentSnapshot> getChatStream(String chatId) {
    return _db.collection('chats').doc(chatId).snapshots();
  }

  Future<void> updateTypingStatus({required String chatId, required String currentUserId, required bool isTyping}) async {
    final Map<String, dynamic> data = isTyping
      ? {'typing_status': FieldValue.arrayUnion([currentUserId])}
      : {'typing_status': FieldValue.arrayRemove([currentUserId])};
    await _db.collection('chats').doc(chatId).set(data, SetOptions(merge: true));
  }
  
  Query getMessagesQuery(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true);
  }

   // --- MÉTODO sendMessage CON LÓGICA DE ESTADO AÑADIDA ---
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String recipientId,
    String? text,
    String? imageUrl,
    String? videoUrl,
    String? thumbnailUrl,
    String? audioUrl,
    int? audioDuration,
    Map<String, String>? contact,
    Map<String, dynamic>? document,
    Map<String, dynamic>? music,
  }) async {
    final messageData = {
      'sender_uid': senderId,
      'recipient_uid': recipientId,
      'text': text,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'audio_url': audioUrl,
      'audio_duration': audioDuration,
      'contact': contact,
      'document': document,
      'music': music,
      'timestamp': FieldValue.serverTimestamp(),
      'is_edited': false, // Nuevo campo
      'status': 'sent', // <-- LÍNEA AÑADIDA
      'is_deleted': false,
      'reactions': {},
    };
    messageData.removeWhere((key, value) => value == null);

    final messageRef = await _db.collection('chats').doc(chatId).collection('messages').add(messageData);
    final unreadCounterField = 'unread_count_for_$recipientId';
    _db.collection('chats').doc(chatId).collection('messages').doc(messageRef.id).update({'status': 'delivered'});


    await _db.collection('chats').doc(chatId).set({
      'participants': [senderId, recipientId],
      'last_message_text': _getLastMessageText(messageData),
      'last_message_timestamp': FieldValue.serverTimestamp(),
      'last_message_sender_uid': senderId, // <-- LÍNEA AÑADIDA
      'last_message_status': 'sent',     // <-- LÍNEA AÑADIDA
      'visible_for': [senderId, recipientId],
      unreadCounterField: FieldValue.increment(1),
    }, SetOptions(merge: true));
    
    

    

    // Simulación de entrega (en una app real, el otro dispositivo lo confirmaría)
    Future.delayed(const Duration(seconds: 1), () {
        messageRef.update({'status': 'delivered'});
        _db.collection('chats').doc(chatId).set({'last_message_status': 'delivered'}, SetOptions(merge: true));
    });
  }

  
  

  Future<void> toggleReaction(String chatId, String messageId, String reaction) async {
    final user = auth.currentUser;
    if (user == null) return;
    final messageRef = _db.collection('chats').doc(chatId).collection('messages').doc(messageId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(messageRef);
      if (!snapshot.exists) return;

      final reactions = Map<String, dynamic>.from(snapshot.data()?['reactions'] ?? {});
      final reactedBy = List<String>.from(reactions[reaction] ?? []);

      if (reactedBy.contains(user.uid)) {
        reactedBy.remove(user.uid);
      } else {
        reactedBy.add(user.uid);
      }

      if (reactedBy.isEmpty) {
        reactions.remove(reaction);
      } else {
        reactions[reaction] = reactedBy;
      }
      
      transaction.update(messageRef, {'reactions': reactions});
    });

    final senderName = user.displayName ?? 'Alguien';
    await _db.collection('chats').doc(chatId).update({
      'last_message_text': '$senderName reaccionó con un $reaction',
      'last_message_timestamp': FieldValue.serverTimestamp(),
    });
  }

 // --- MÉTODO markMessagesAsRead ACTUALIZADO PARA USAR 'status' ---
  Future<void> markMessagesAsRead({required String chatId, required String currentUserId}) async {
    final unreadCounterField = 'unread_count_for_$currentUserId';
    final chatDocRef = _db.collection('chats').doc(chatId);
    final messagesQuery = chatDocRef
        .collection('messages')
        .where('recipient_uid', isEqualTo: currentUserId)
        .where('status', isNotEqualTo: 'read');


    final querySnapshot = await messagesQuery.get();
    
    // Se resetea el contador de no leídos para el usuario actual.
    await _db.collection('chats').doc(chatId).set({
      unreadCounterField: 0,
    }, SetOptions(merge: true));
    // Se actualiza el estado de los mensajes a 'read'.
    final messagesToUpdate = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('recipient_uid', isEqualTo: currentUserId)
        .where('status', isNotEqualTo: 'read')
        .get();
    WriteBatch batch = _db.batch();
    for (var doc in messagesToUpdate.docs) {
      batch.update(doc.reference, {'status': 'read'});
    }
    await batch.commit();
  

    // Actualiza el estado del último mensaje solo si es necesario
    final chatDoc = await chatDocRef.get();
    if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>;
        // Solo actualiza a 'read' si el último mensaje fue para mí y no estaba leído
        if (data['last_message_sender_uid'] != currentUserId) {
            await chatDocRef.set({'last_message_status': 'read'}, SetOptions(merge: true));
        }
    }
  }

  Future<void> clearChatForUser({required String chatId}) async {
    final user = auth.currentUser;
    if (user == null) return;
    final clearedAtField = 'cleared_at_for_${user.uid}';
    
    final batch = _db.batch();
    final chatRef = _db.collection('chats').doc(chatId);
    
    batch.set(chatRef, {
      clearedAtField: Timestamp.now(),
    }, SetOptions(merge: true));

    batch.update(chatRef, {
      'last_message_text': 'Chat vaciado',
      'last_message_timestamp': FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
  }

  Future<void> hideChatForUser({required String chatId}) async {
    final user = auth.currentUser;
    if (user == null) return;
    await _db.collection('chats').doc(chatId).update({
      'visible_for': FieldValue.arrayRemove([user.uid])
    });
  }
  
  Future<void> deleteChat(String chatId) async {
    await _db.collection('chats').doc(chatId).delete();
  }
  
  Future<void> deleteMessageForMe(String chatId, String messageId) async {
    final user = auth.currentUser;
    if (user == null) return;
    
    final deletedForField = 'deleted_for';
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set({
          deletedForField: FieldValue.arrayUnion([user.uid])
        }, SetOptions(merge: true));
  }

  Future<void> deleteMessageForEveryone({
    required String chatId,
    required String messageId,
  }) async {
     final user = auth.currentUser;
    if (user == null) return;

    final deletedMessageText = ' Mensaje eliminado';

    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
          'text': deletedMessageText,
          'image_url': null,
          'video_url': null,
          'thumbnail_url': null,
          'audio_url': null,
          'audio_duration': null,
          'contact': null,
          'document': null,
          'music': null,
          'is_deleted': true,
          'reactions': {},
        });

    final lastMessageSnapshot = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (lastMessageSnapshot.docs.isNotEmpty) {
       final lastMessage = lastMessageSnapshot.docs.first.data();
       await _db.collection('chats').doc(chatId).update({
        'last_message_text': _getLastMessageText(lastMessage),
        'last_message_timestamp': lastMessage['timestamp']
      });
    } else {
      await _db.collection('chats').doc(chatId).update({
        'last_message_text': '',
        'last_message_timestamp': FieldValue.serverTimestamp()
      });
    }
  }

  String _getLastMessageText(Map<String, dynamic> data) {
    if (data['is_deleted'] == true) return '🚫 Mensaje eliminado';
    if (data.containsKey('text') && data['text'] != null && data['text'].isNotEmpty) return data['text'];
    if (data.containsKey('image_url')) return '📷 Foto';
    if (data.containsKey('video_url')) return '▶️ Video';
    if (data.containsKey('audio_url')) return '🎤 Mensaje de voz';
    if (data.containsKey('contact')) return '👤 Contacto: ${data['contact']['name']}';
    if (data.containsKey('document')) return '📄 Documento: ${data['document']['name']}';
    if (data.containsKey('music')) return '🎵 Audio: ${data['music']['name']}';
    return 'Mensaje';
  }

  Future<String?> deleteUserAccount() async {
    final user = auth.currentUser;
    if (user == null) return "No hay usuario autenticado.";

    try {
      await _db.collection('users').doc(user.uid).delete();
      await StorageService().deleteUserProfilePicture(user.uid);
      await user.delete();
      return null; 
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'Esta operación requiere que inicies sesión de nuevo por seguridad.';
      }
      return 'Error al eliminar la cuenta: ${e.message}';
    } catch (e) {
      return 'Ocurrió un error inesperado: $e';
    }
  }

  Future<String> exportChatHistory({
    required String chatId,
    required UserModel currentUser,
    required UserModel otherUser,
  }) async {
    final messagesSnapshot = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .get();

    final StringBuffer history = StringBuffer();
    final dateFormat = DateFormat('d/M/y, h:mm a');

    for (final doc in messagesSnapshot.docs) {
      final data = doc.data();
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
      
      if (timestamp == null) continue;
      
      final senderUid = data['sender_uid'] as String;
      final senderName = senderUid == currentUser.uid ? currentUser.displayName : otherUser.displayName;
      
      final messageContent = _getLastMessageText(data);
      
      history.writeln('${dateFormat.format(timestamp)} - $senderName: $messageContent');
    }
    
    return history.toString();
  }
}
