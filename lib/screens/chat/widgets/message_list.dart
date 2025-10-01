import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:simplechat/models/uploading_message_model.dart';
import 'message_bubble.dart';

class MessageList extends StatelessWidget {
  final Query? messagesQuery;
  final List<UploadingMessage> uploadingMessages;
  final bool isSearching;
  final String searchQuery;
  final Function(DocumentSnapshot, LongPressStartDetails) onLongPressMessage;
  final List<String> selectedMessages;
  final Function(String, String) onAddContact;
  final String chatId;

  const MessageList({
    super.key,
    required this.messagesQuery,
    required this.uploadingMessages,
    required this.isSearching,
    required this.searchQuery,
    required this.onLongPressMessage,
    required this.selectedMessages,
    required this.onAddContact,
    required this.chatId,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    if (messagesQuery == null) {
      // If there's no query, just build with uploading messages if any
      if (uploadingMessages.isEmpty) {
        return const Center(child: Text('Inicia una conversación.'));
      }
      return _buildList([], uploadingMessages, currentUserId, onLongPressMessage);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: messagesQuery?.snapshots(),
      builder: (context, messagesSnapshot) {
        // --- BUG 2 FIX: Removed the ConnectionState.waiting check ---
        // We now build the list immediately, even if it's empty, to avoid the spinner.
        
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

        return _buildList(filteredMessages, uploadingMessages, currentUserId, onLongPressMessage);
      },
    );
  }

  // Helper method to build the list, keeping the builder clean
  ListView _buildList(
    List<DocumentSnapshot> messages, 
    List<UploadingMessage> uploadingMessages, 
    String currentUserId,
    Function(DocumentSnapshot, LongPressStartDetails) onLongPressMessage,
  ) {
    return ListView.builder(
      reverse: true,
      itemCount: messages.length + uploadingMessages.length,
      itemBuilder: (context, index) {
        if (index < uploadingMessages.length) {
          final uploadingItem = uploadingMessages[index];
          return MessageBubble(
            uploadingMessage: uploadingItem,
            isSelected: false,
            onLongPress: (_) {},
            onAddContact: (String _, String __) {}, // Explicitly typed
            chatId: chatId,
          );
        }
        
        final doc = messages[index - uploadingMessages.length];
        final messageId = doc.id;
        final isSelected = selectedMessages.contains(messageId);
        
        return MessageBubble(
          doc: doc,
          isSelected: isSelected,
          onLongPress: (details) => onLongPressMessage(doc, details),
          onAddContact: onAddContact,
          chatId: chatId,
        );
      },
    );
  }
}