import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  
  // --- MEJORA 3: Helpers para los divisores de fecha ---
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCompare = DateTime(date.year, date.month, date.day);

    if (dateToCompare == today) {
      return 'Hoy';
    } else if (dateToCompare == yesterday) {
      return 'Ayer';
    } else {
      return DateFormat('d \'de\' MMMM \'de\' yyyy', 'es').format(date);
    }
  }


  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    if (messagesQuery == null) {
      if (uploadingMessages.isEmpty) {
        return const Center(child: Text('Inicia una conversación.'));
      }
      // Si solo hay mensajes subiendo, no necesitamos divisores.
      return _buildUploadingList(uploadingMessages);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: messagesQuery?.snapshots(),
      builder: (context, messagesSnapshot) {
        
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
        
        // --- MEJORA 3: Construimos la lista con los divisores de fecha ---
        final List<Widget> itemsWithDividers = [];

        // Primero, los mensajes que se están subiendo (siempre al principio/abajo)
        for (final uploadingItem in uploadingMessages) {
          itemsWithDividers.add(MessageBubble(
            uploadingMessage: uploadingItem,
            isSelected: false,
            onLongPress: (_) {},
            onAddContact: (String _, String __) {},
            chatId: chatId,
          ));
        }

        // Luego, los mensajes ya enviados con sus divisores de fecha
        for (int i = 0; i < filteredMessages.length; i++) {
          final doc = filteredMessages[i];
          final messageData = doc.data() as Map<String, dynamic>;
          final timestamp = (messageData['timestamp'] as Timestamp?)?.toDate();

          // Comparamos la fecha del mensaje actual con la del mensaje anterior en el chat
          // (que es el siguiente en nuestra lista, ya que está ordenada descendente)
          if (timestamp != null) {
            DateTime? previousMessageTimestamp;
            if (i + 1 < filteredMessages.length) {
              final previousDoc = filteredMessages[i + 1];
              final previousMessageData = previousDoc.data() as Map<String, dynamic>;
              previousMessageTimestamp = (previousMessageData['timestamp'] as Timestamp?)?.toDate();
            }

            // Si es el último mensaje (el más antiguo) o el día es diferente, añadimos un divisor
            if (previousMessageTimestamp == null || !_isSameDay(timestamp, previousMessageTimestamp)) {
              itemsWithDividers.add(_DateDivider(date: timestamp));
            }
          }

          // Añadimos la burbuja del mensaje
          final messageId = doc.id;
          final isSelected = selectedMessages.contains(messageId);
          itemsWithDividers.add(MessageBubble(
            doc: doc,
            isSelected: isSelected,
            onLongPress: (details) => onLongPressMessage(doc, details),
            onAddContact: onAddContact,
            chatId: chatId,
          ));
        }

        return ListView.builder(
          reverse: true,
          itemCount: itemsWithDividers.length,
          itemBuilder: (context, index) {
            return itemsWithDividers[index];
          },
        );
      },
    );
  }
  
  // Widget auxiliar para los mensajes en proceso de subida
  ListView _buildUploadingList(List<UploadingMessage> uploadingMessages) {
     return ListView.builder(
      reverse: true,
      itemCount: uploadingMessages.length,
      itemBuilder: (context, index) {
        final uploadingItem = uploadingMessages[index];
        return MessageBubble(
          uploadingMessage: uploadingItem,
          isSelected: false,
          onLongPress: (_) {},
          onAddContact: (String _, String __) {},
          chatId: chatId,
        );
      },
    );
  }
}

// --- MEJORA 3: Widget para el divisor de fecha ---
class _DateDivider extends StatelessWidget {
  final DateTime date;
  
  const _DateDivider({required this.date});
  
  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCompare = DateTime(date.year, date.month, date.day);

    if (dateToCompare == today) {
      return 'Hoy';
    } else if (dateToCompare == yesterday) {
      return 'Ayer';
    } else {
      return DateFormat('d \'de\' MMMM \'de\' yyyy', 'es').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Text(
          _formatDateSeparator(date),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}