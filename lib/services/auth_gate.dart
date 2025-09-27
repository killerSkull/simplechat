import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:simplechat/models/user_model.dart';
import 'package:simplechat/screens/chat_list_page.dart';
import 'package:simplechat/screens/login_page.dart';
import 'package:simplechat/screens/profile_setup_page.dart';
import 'package:simplechat/services/notification_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Si no hay usuario, vamos a la página de login.
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        // Si hay un usuario, INICIAMOS el servicio de notificaciones.
        // Esto es crucial para que el token se guarde después de iniciar sesión.
        final notificationService = context.read<NotificationService>();
        notificationService.initNotifications();

        // Luego, comprobamos si el perfil del usuario está completo.
        return ProfileCheck(user: snapshot.data!);
      },
    );
  }
}

class ProfileCheck extends StatelessWidget {
  final User user;
  const ProfileCheck({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return ProfileSetupPage(user: user);
        }
        
        final userModel = UserModel.fromFirestore(snapshot.data!);

        if (!userModel.profileCompleted) {
          return ProfileSetupPage(user: user);
        }

        return const ChatListPage();
      },
    );
  }
}