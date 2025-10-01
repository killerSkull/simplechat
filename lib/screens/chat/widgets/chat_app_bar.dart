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
          style: TextStyle(color: theme.appBarTheme.foregroundColor, fontSize: 18),
        ),
      );
    }

    return AppBar(
      // --- AJUSTE DE DISEÑO (VERSIÓN FINAL) ---
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      // Usamos el 'leading' para agrupar el botón de atrás y el avatar
      leadingWidth: 70, // Ancho suficiente para ambos elementos
      leading: Row(
        children: [
          const BackButton(),
          // Movemos el CircleAvatar aquí para que esté junto al botón
          CircleAvatar(
            radius: 18,
            backgroundImage: otherUser.photoUrl != null && otherUser.photoUrl!.isNotEmpty
                ? CachedNetworkImageProvider(otherUser.photoUrl!)
                : null,
            child: otherUser.photoUrl == null || otherUser.photoUrl!.isEmpty
                ? const Icon(Icons.person, size: 20)
                : null,
          ),
        ],
      ),
      // El 'title' ahora es solo el texto y es clickeable
      title: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ContactProfileScreen(user: otherUser, nickname: nickname)),
          );
        },
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(otherUser.uid).snapshots(),
          builder: (context, userSnapshot) {
            final user = userSnapshot.hasData ? UserModel.fromFirestore(userSnapshot.data!) : otherUser;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nickname ?? user.displayName ?? 'Usuario',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.appBarTheme.foregroundColor,
                    fontSize: 18, 
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirestoreService().getChatStream(chatId),
                  builder: (context, chatSnapshot) {
                    String subtitleText = ' ';
                    Color subtitleColor = theme.appBarTheme.foregroundColor?.withOpacity(0.7) ?? Colors.white70;

                    if (user.presence) {
                       subtitleText = 'en línea';
                       subtitleColor = Colors.lightGreenAccent;
                    } else if (user.lastSeen != null) {
                      subtitleText = _formatLastSeen(user.lastSeen!);
                    }

                    if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
                      final data = chatSnapshot.data!.data() as Map<String, dynamic>;
                      final typingUids = List<String>.from(data['typing_status'] ?? []);
                      if (typingUids.contains(otherUser.uid)) {
                        subtitleText = 'escribiendo...';
                        subtitleColor = Colors.lightGreenAccent;
                      }
                    }
                    
                    return Text(
                      subtitleText,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                      )
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        // --- AJUSTE DE DISEÑO (VERSIÓN FINAL) ---
        // Se reduce el 'splashRadius' para un feedback visual más pequeño y se ajusta el padding
        IconButton(
          splashRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          icon: const Icon(Icons.videocam),
          onPressed: onStartVideoCall,
        ),
        IconButton(
          splashRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 4),
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