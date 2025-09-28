import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simplechat/screens/contact_profile_screen.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final UserModel otherUser;
  final String? nickname;
  final String chatId;
  final bool isSearching;
  final ValueChanged<bool> onToggleSearch;
  final TextEditingController searchController;
  final ValueChanged<String> onMenuSelected;
  // --- NUEVO: Callbacks para iniciar llamadas ---
  final VoidCallback onStartVideoCall;
  final VoidCallback onStartVoiceCall;

  const ChatAppBar({
    super.key,
    required this.otherUser,
    this.nickname,
    required this.chatId,
    required this.isSearching,
    required this.onToggleSearch,
    required this.searchController,
    required this.onMenuSelected,
    required this.onStartVideoCall,
    required this.onStartVoiceCall,
  });

  String _formatLastSeen(DateTime lastSeen) {
    Intl.defaultLocale = 'es';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final lastSeenDate = DateTime(lastSeen.year, lastSeen.month, lastSeen.day);

    if (lastSeenDate == today) {
      return 'últ. vez hoy a las ${DateFormat('h:mm a').format(lastSeen)}';
    } else if (lastSeenDate == yesterday) {
      return 'últ. vez ayer a las ${DateFormat('h:mm a').format(lastSeen)}';
    } else if (now.difference(lastSeen).inDays < 7) {
      return 'últ. vez el ${DateFormat('EEEE').format(lastSeen)}';
    } else {
      return 'últ. vez el ${DateFormat('d/M/y').format(lastSeen)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => onToggleSearch(false),
        ),
        title: TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar mensajes...',
            border: InputBorder.none,
          ),
          style: TextStyle(color: theme.appBarTheme.foregroundColor),
        ),
      );
    }

    return AppBar(
      titleSpacing: 0,
      title: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(otherUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Text(nickname ?? otherUser.displayName ?? 'Usuario');
          
          final user = UserModel.fromFirestore(snapshot.data!);

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactProfileScreen(user: user, nickname: nickname)),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null || user.photoUrl!.isEmpty
                      ? const Icon(Icons.person, size: 22)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname ?? user.displayName ?? 'Usuario', 
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.appBarTheme.foregroundColor
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirestoreService().getChatStream(chatId),
                        builder: (context, typingSnapshot) {
                          String subtitleText = 'desconectado';
                          Color subtitleColor = theme.appBarTheme.foregroundColor?.withOpacity(0.7) ?? Colors.white70;

                          if (user.presence) {
                             subtitleText = 'en línea';
                             subtitleColor = Colors.greenAccent;
                          } else if (user.lastSeen != null) {
                            subtitleText = _formatLastSeen(user.lastSeen!);
                            subtitleColor = theme.appBarTheme.foregroundColor?.withOpacity(0.7) ?? Colors.white70;
                          }

                          if (typingSnapshot.hasData && typingSnapshot.data!.exists) {
                            final data = typingSnapshot.data!.data() as Map<String, dynamic>;
                            final typingUids = List<String>.from(data['typing_status'] ?? []);
                            if (typingUids.contains(otherUser.uid)) {
                              subtitleText = 'Escribiendo...';
                              subtitleColor = Colors.greenAccent;
                            }
                          }
                          return Text(
                            subtitleText, 
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: subtitleColor
                            )
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        // --- NUEVOS BOTONES DE LLAMADA ---
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: onStartVideoCall,
        ),
        IconButton(
          icon: const Icon(Icons.call),
          onPressed: onStartVoiceCall,
        ),
        PopupMenuButton<String>(
          onSelected: onMenuSelected,
          itemBuilder: (BuildContext context) {
            return {'Buscar en el chat', 'Exportar chat', 'Vaciar chat'}.map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

