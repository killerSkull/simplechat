// Archivo: profile_preview_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:simplechat/models/user_model.dart';
import 'package:simplechat/screens/chat_screen.dart';
import 'package:simplechat/screens/contact_profile_screen.dart';

void showProfilePreview(BuildContext context, UserModel user, String? nickname) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ... (el resto del widget de imagen se queda igual)
            SizedBox(
              height: 250,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: user.photoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Icon(Icons.person, size: 100, color: Colors.grey),
                          )
                        : const Icon(Icons.person, size: 100, color: Colors.grey),
                  ),
                  Positioned(
                    top: 8,
                    left: 16,
                    child: Text(
                      nickname ?? user.displayName ?? 'Usuario', // <-- CAMBIO: Usa el nickname si existe
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 8.0, color: Colors.black54)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Barra de iconos
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat),
                    onPressed: () {
                      Navigator.of(context).pop(); // Cierra el diálogo
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // <-- CAMBIO: Pasa el nickname a ChatScreen
                          builder: (context) => ChatScreen(otherUser: user, nickname: nickname),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.call),
                    onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Función de llamada próximamente.')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam),
                    onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Función de videollamada próximamente.')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      Navigator.of(context).pop(); // Cierra el diálogo
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // <-- CAMBIO: Pasa el nickname a ContactProfileScreen
                          builder: (context) => ContactProfileScreen(user: user, nickname: nickname),
                        ),
                      );
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      );
    },
  );
}