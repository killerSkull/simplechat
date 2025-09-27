import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:simplechat/models/uploading_message_model.dart';
import 'message_bubble.dart';

class MessageList extends StatelessWidget {
  final Query? messagesQuery;
  // --- CAMBIO: Ahora recibe `uploadingMessages` en lugar de `pendingMessages` ---
  final List<UploadingMessage> uploadingMessages;
  final bool isSearching;
  final String searchQuery;
  final Function(DocumentSnapshot, LongPressStartDetails) onLongPressMessage;
  final List<String> selectedMessages;
  final Function(String, String) onAddContact;

  const MessageList({
    super.key,
    required this.messagesQuery,
    required this.uploadingMessages,
    required this.isSearching,
    required this.searchQuery,
    required this.onLongPressMessage,
    required this.selectedMessages,
    required this.onAddContact,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    if (messagesQuery == null && uploadingMessages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: messagesQuery?.snapshots(),
      builder: (context, messagesSnapshot) {
        if (messagesSnapshot.connectionState == ConnectionState.waiting && uploadingMessages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final messages = messagesSnapshot.data?.docs ?? [];
        
        final visibleMessages = messages.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final deletedFor = List<String>.from(data['deleted_for'] ?? []);
          return !deletedFor.contains(currentUserId);
        }).toList();

        final filteredMessages = isSearching && searchQuery.isNotEmpty
          ? visibleMessages.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final text = data['text'] as String?;
              return text != null && text.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList()
          : visibleMessages;

        if (filteredMessages.isEmpty && uploadingMessages.isEmpty) {
           return const Center(child: Text('Envía un mensaje para empezar.'));
        }

        // --- LÓGICA MEJORADA: Combina mensajes subidos y mensajes en la nube ---
        return ListView.builder(
          reverse: true,
          itemCount: filteredMessages.length + uploadingMessages.length,
          itemBuilder: (context, index) {
            // Muestra primero los mensajes que se están subiendo
            if (index < uploadingMessages.length) {
              final uploadingItem = uploadingMessages[index];
              return MessageBubble(
                uploadingMessage: uploadingItem,
                isSelected: false,
                onLongPress: (_) {},
                onAddContact: (_, __) {},
              );
            }
            // Luego, muestra los mensajes ya enviados
            final doc = filteredMessages[index - uploadingMessages.length];
            final messageId = doc.id;
            final isSelected = selectedMessages.contains(messageId);
            
            return MessageBubble(
              doc: doc,
              isSelected: isSelected,
              onLongPress: (details) => onLongPressMessage(doc, details),
              onAddContact: onAddContact,
            );
          },
        );
      },
    );
  }
}
