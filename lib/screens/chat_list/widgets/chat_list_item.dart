import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simplechat/models/user_model.dart';
import 'package:simplechat/screens/chat/widgets/profile_preview_card.dart';

class ChatListItem extends StatelessWidget {
  final UserModel user;
  final Map<String, dynamic> chatDocData;
  final String? nickname;
  final bool wasSentByMe;
  final String? lastMessageStatus;
  final int unreadCount;
  final bool isPinned;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ChatListItem({
    super.key,
    required this.user,
    required this.chatDocData,
    required this.nickname,
    required this.wasSentByMe,
    this.lastMessageStatus,
    required this.unreadCount,
    required this.isPinned,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastMessageText = chatDocData['last_message_text'] as String? ?? '';
    final timestamp = (chatDocData['last_message_timestamp'] as Timestamp?)?.toDate();

    return ListTile(
      onLongPress: onLongPress,
      leading: GestureDetector(
        onTap: () => showProfilePreview(context, user, nickname, chatDocData['id']),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(user.photoUrl!)
                  : null,
              child: user.photoUrl == null || user.photoUrl!.isEmpty
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            if (user.presence)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
      title: Text(nickname ?? user.displayName ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Row(
        children: [
          if (wasSentByMe) ...[
            _buildStatusIcon(lastMessageStatus),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              lastMessageText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                color: unreadCount > 0 ? theme.colorScheme.primary : null,
              ),
            ),
          ),
        ],
      ),
      trailing: _ChatListItemTrailing(
        timestamp: timestamp,
        unreadCount: unreadCount,
        isPinned: isPinned,
      ),
      onTap: onTap,
    );
  }

  Widget _buildStatusIcon(String? status) {
    IconData iconData;
    Color? color;
    switch (status) {
      case 'sent':
        iconData = Icons.done;
        break;
      case 'delivered':
        iconData = Icons.done_all;
        break;
      case 'read':
        iconData = Icons.done_all;
        color = Colors.lightBlueAccent;
        break;
      default:
        return const SizedBox.shrink();
    }
    return Icon(iconData, size: 18, color: color ?? Colors.grey);
  }
}

class _ChatListItemTrailing extends StatelessWidget {
  final DateTime? timestamp;
  final int unreadCount;
  final bool isPinned;

  const _ChatListItemTrailing({
    required this.timestamp,
    required this.unreadCount,
    required this.isPinned,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 60, // Ancho fijo para alinear todo correctamente
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (timestamp != null)
            Text(
              DateFormat('HH:mm').format(timestamp!),
              style: TextStyle(
                color: unreadCount > 0 ? theme.colorScheme.primary : Colors.grey,
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 4),
          if (isPinned || unreadCount > 0)
            SizedBox(
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isPinned)
                    const Icon(Icons.push_pin, color: Colors.grey, size: 16),
                  if (isPinned && unreadCount > 0)
                    const SizedBox(width: 4), // Espacio entre el pin y el badge
                  if (unreadCount > 0)
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}