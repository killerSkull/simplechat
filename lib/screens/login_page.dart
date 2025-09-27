import 'package:firebase_ui_auth/firebase_ui_auth.dart' as ui; // Se añade un prefijo 'ui'
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

// Se añaden los imports que faltaban
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart'; 

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Se usa el prefijo 'ui' para especificar de dónde vienen los widgets
    return ui.SignInScreen(
      providers: [
        ui.EmailAuthProvider(), // <- Solucionado: Ahora es explícitamente de firebase_ui_auth
        // Ahora sí, 'GoogleProvider' se reconoce correctamente
        GoogleProvider(
            clientId:
                "29978125325-12h8sm9dtgc0nbp8mbp6saecnf6bok68.apps.googleusercontent.com"),
      ],
      // Llama a createUserProfile después de un inicio de sesión exitoso.
      actions: [
        // Se usa el prefijo 'ui' aquí también
        ui.AuthStateChangeAction<ui.SignedIn>((context, state) {
          if (state.user != null) {
            FirestoreService().createUserProfile(state.user!);
          }
        }),
      ],
      headerBuilder: (context, constraints, shrinkOffset) {
        return Padding(
          padding: const EdgeInsets.all(40.0),
          child: Center(
              child: Text(
            'SimpleChat',
            style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple[400]),
          )),
        );
      },
      subtitleBuilder: (context, action) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('¡Bienvenido! Inicia sesión para continuar'),
        );
      },
    );
  }
}