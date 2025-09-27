import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? status;
  final String? phoneNumber;
  final bool presence;
  final DateTime? lastSeen;
  final bool profileCompleted;

  final String? nickname;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.status,
    this.phoneNumber,
    required this.presence,
    this.lastSeen,
    required this.profileCompleted, 
    required this.nickname,
  });

  // CORRECCIÓN: El factory ahora usa el DocumentSnapshot completo.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id, // Usamos el ID del documento, que es infalible.
      email: data['email'],
      displayName: data['display_name'],
      photoUrl: data['photo_url'],
      status: data['status'],
      phoneNumber: data['phone_number']?.toString(),
      nickname: data['nickname'],
      presence: data['presence'] ?? false,
      lastSeen: (data['last_seen'] as Timestamp?)?.toDate(),
      profileCompleted: data['profile_completed'] ?? false,
    );
  }
}