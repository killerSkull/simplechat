import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:simplechat/screens/call_screen.dart';
import 'package:simplechat/services/firestore_service.dart';

class IncomingCallScreen extends StatelessWidget {
  final Map<String, dynamic> callData;

  const IncomingCallScreen({super.key, required this.callData});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    // Extraemos los datos de la notificación
    final String chatId = callData['channelName'];
    final String callerName = callData['callerName'];
    final String callerPhotoUrl = callData['callerPhotoUrl'];
    final bool isVideoCall = callData['isVideoCall'].toString() == 'true';
    final String token = callData['token'];
    final String currentUserId = firestoreService.auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              CircleAvatar(
                radius: 60,
                backgroundImage: callerPhotoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(callerPhotoUrl)
                    : null,
                child: callerPhotoUrl.isEmpty
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 24),
              Text(
                callerName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                isVideoCall ? 'Videollamada entrante...' : 'Llamada entrante...',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón para rechazar la llamada
                    FloatingActionButton(
                      heroTag: 'reject_call',
                      onPressed: () async {
                        await firestoreService.endCall(chatId, currentUserId);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.call_end, color: Colors.white),
                    ),
                    // Botón para aceptar la llamada
                    FloatingActionButton(
                      heroTag: 'accept_call',
                      onPressed: () async {
                        await firestoreService.answerCall(chatId);
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CallScreen(
                                channelName: chatId,
                                token: token,
                                otherUserName: callerName,
                                isVideoCall: isVideoCall,
                              ),
                            ),
                          );
                        }
                      },
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.call, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}