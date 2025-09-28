import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:simplechat/models/user_model.dart';
import 'package:simplechat/services/agora_service.dart';
import 'package:simplechat/services/storage_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  var db;
  // --- NUEVO: Métodos para gestionar llamadas ---

  /// Obtiene un stream para escuchar los cambios en un documento de llamada.
  Stream<DocumentSnapshot> getCallStream(String chatId) {
    return _db.collection('calls').doc(chatId).snapshots();
  }

  /// Inicia una llamada creando un documento en Firestore.
  /// Esto activará la Cloud Function que envía la notificación.
  Future<void> startCall({
    required String chatId,
    required String recipientId,
    required bool isVideoCall,
  }) async {
    final user = auth.currentUser;
    if (user == null) return;

    // 1. Obtiene el token de Agora necesario para unirse al canal.
    final token = await AgoraService.fetchToken(chatId);
    if (token == null) {
      print("No se pudo obtener el token de Agora. Cancelando llamada.");
      return;
    }

    // 2. Crea el documento de la llamada en la colección 'calls'.
    await _db.collection('calls').doc(chatId).set({
      'callerId': user.uid,
      'callerName': user.displayName ?? 'Alguien',
      'callerPhotoUrl': user.photoURL ?? '',
      'recipientId': recipientId,
      'token': token,
      'isVideoCall': isVideoCall,
      'status': 'ringing', // Estados: ringing, ongoing, ended, missed, rejected
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Actualiza el estado de la llamada a 'ongoing' cuando el receptor contesta.
  Future<void> answerCall(String chatId) async {
    await _db.collection('calls').doc(chatId).update({'status': 'ongoing'});
  }

  /// Finaliza una llamada, actualizando su estado final.
  Future<void> endCall(String chatId, String currentUserId) async {
    final callDoc = await _db.collection('calls').doc(chatId).get();
    if (!callDoc.exists) return;

    final callData = callDoc.data()!;
    final recipientId = callData['recipientId'];
    final status = callData['status'];

    String finalStatus = 'ended';

    // Determina si la llamada fue rechazada o perdida en lugar de solo terminada.
    if (status == 'ringing' && currentUserId == recipientId) {
      finalStatus = 'rejected';
    } else if (status == 'ringing') {
      finalStatus = 'missed';
    }

    await _db.collection('calls').doc(chatId).update({'status': finalStatus});
  }


  // --- (El resto de los métodos se mantienen igual) ---

  Future<void> updateUserActiveChat(String? chatId) async {
    final user = auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set({
      'current_chat_id': chatId,
    }, SetOptions(merge: true));
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

  Stream<QuerySnapshot> getChatsStream() {
    final user = auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db
        .collection('chats')
        .where('visible_for', arrayContains: user.uid)
        .orderBy('last_message_timestamp', descending: true)
        .snapshots();
  }
  
  String getChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode ? '$user1-$user2' : '$user2-$user1';
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
      'is_read': false,
      'is_deleted': false,
      'reactions': {},
    };
    messageData.removeWhere((key, value) => value == null);

    await _db.collection('chats').doc(chatId).collection('messages').add(messageData);

    String lastMessageText = _getLastMessageText(messageData);

    await _db.collection('chats').doc(chatId).set({
      'participants': [senderId, recipientId],
      'last_message_text': lastMessageText,
      'last_message_timestamp': FieldValue.serverTimestamp(),
      'visible_for': [senderId, recipientId],
    }, SetOptions(merge: true));
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

  Future<void> markMessagesAsRead({required String chatId, required String currentUserId}) async {
    final querySnapshot = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('recipient_uid', isEqualTo: currentUserId)
        .where('is_read', isEqualTo: false)
        .get();
    
    WriteBatch batch = _db.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    await batch.commit();
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

    final deletedMessageText = '🚫 Mensaje eliminado';

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