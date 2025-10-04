import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:simplechat/models/uploading_message_model.dart';
import 'package:simplechat/providers/audio_player_provider.dart';
import 'package:simplechat/screens/full_screen_image_viewer.dart';
import 'package:simplechat/services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:filesize/filesize.dart';
import 'package:characters/characters.dart';

// Helper class to hold the result of emoji analysis
class _EmojiAnalysis {
  final bool isOnlyEmojis;
  final int count;

  _EmojiAnalysis(this.isOnlyEmojis, this.count);
}

// Helper function to analyze a string for emoji content
_EmojiAnalysis _analyzeTextForEmojis(String? text) {
  if (text == null || text.trim().isEmpty) {
    return _EmojiAnalysis(false, 0);
  }
  final textWithoutEmojis = text.replaceAll(
      RegExp(
        r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff]|\ufe0f)',
      ),
      '');
  if (textWithoutEmojis.trim().isEmpty) {
    final characterCount = text.trim().characters.length;
    return _EmojiAnalysis(true, characterCount);
  }
  return _EmojiAnalysis(false, 0);
}

class MessageBubble extends StatelessWidget {
  final DocumentSnapshot? doc;
  final UploadingMessage? uploadingMessage;
  final bool isSelected;
  final Function(LongPressStartDetails) onLongPress;
  final String? contactPhotoUrl;
  final Function(String, String) onAddContact;
  final String chatId;

  const MessageBubble({
    super.key,
    this.doc,
    this.uploadingMessage,
    required this.isSelected,
    required this.onLongPress,
    this.contactPhotoUrl,
    required this.onAddContact,
    required this.chatId,
  });

  Future<void> _onOpenLink(LinkableElement link) async {
    final uri = Uri.parse(link.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('HH:mm').format(timestamp);
  }

  Widget _buildStatusIcon(String status, Color color) {
    IconData icon;
    switch (status) {
      case 'sending':
        icon = Icons.watch_later_outlined;
        break;
      case 'sent':
        icon = Icons.done;
        break;
      case 'delivered':
        icon = Icons.done_all;
        break;
      case 'read':
        icon = Icons.done_all;
        color = Colors.lightBlueAccent;
        break;
      default:
        icon = Icons.done;
    }
    return Icon(icon, size: 14, color: color);
  }

  @override
  Widget build(BuildContext context) {
    if (uploadingMessage != null) {
      return _buildUploadingBubble(context, uploadingMessage!);
    }

    final currentUser = FirebaseAuth.instance.currentUser!;
    final message = doc!.data() as Map<String, dynamic>;

    final bool isMe = message['sender_uid'] == currentUser.uid;
    final bool isDeleted = message['is_deleted'] as bool? ?? false;
    final String status = message['status'] as String? ?? 'sent';

    final text = message['text'] as String?;
    final _EmojiAnalysis emojiAnalysis = _analyzeTextForEmojis(text);
    final bool isSingleJumboEmoji =
        emojiAnalysis.isOnlyEmojis && emojiAnalysis.count == 1;
    final bool isMultiJumboEmoji =
        emojiAnalysis.isOnlyEmojis && emojiAnalysis.count > 1 && emojiAnalysis.count <= 3;

    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = isSelected
        ? (isMe ? Colors.blue.shade900 : Colors.grey.shade700)
        : isSingleJumboEmoji
            ? Colors.transparent
            : (isMe
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondaryContainer);
    final textColor = isMe
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSecondaryContainer;

    final timestamp = (message['timestamp'] as Timestamp?)?.toDate();
    final imageUrl = message['image_url'] as String?;
    final videoUrl = message['video_url'] as String?;
    final thumbnailUrl = message['thumbnail_url'] as String?;
    final audioUrl = message['audio_url'] as String?;
    final audioDuration = message['audio_duration'] as int?;

    final contactData = message['contact'] as Map<String, dynamic>?;
    final documentData = message['document'] as Map<String, dynamic>?;
    final musicData = message['music'] as Map<String, dynamic>?;

    final reactions = Map<String, dynamic>.from(message['reactions'] ?? {});
    final bool isEdited = message['is_edited'] as bool? ?? false;

    return GestureDetector(
      onLongPressStart: isDeleted ? null : onLongPress,
      child: Container(
        alignment: alignment,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: isSingleJumboEmoji
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: isDeleted
                    ? Theme.of(context).colorScheme.surfaceVariant
                    : color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSingleJumboEmoji
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: isDeleted
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.block,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 14),
                        const SizedBox(width: 4),
                        Text(
                          text ?? "Mensaje eliminado",
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (imageUrl != null)
                          _buildImage(context, imageUrl, text),
                        if (videoUrl != null)
                          _buildVideo(context, videoUrl, thumbnailUrl, text),
                        if (audioUrl != null)
                          AudioPlayerWidget(
                            audioUrl: audioUrl,
                            durationInMilliseconds: audioDuration,
                            isMe: isMe,
                            contactPhotoUrl: contactPhotoUrl,
                          ),
                        if (contactData != null)
                          _buildContact(context, contactData, textColor),
                        if (documentData != null)
                          _buildDocument(context, documentData, textColor),
                        if (musicData != null)
                          AudioPlayerWidget(
                            audioUrl: musicData['url'],
                            durationInMilliseconds: null,
                            isMe: isMe,
                            contactPhotoUrl: contactPhotoUrl,
                          ),
                        if (text != null && text.isNotEmpty)
                          Linkify(
                            onOpen: _onOpenLink,
                            text: text,
                            style: TextStyle(
                              color: textColor,
                              fontSize: isSingleJumboEmoji
                                  ? 48.0
                                  : isMultiJumboEmoji
                                      ? 32.0
                                      : null,
                            ),
                            linkStyle: TextStyle(
                                color: isMe
                                    ? Colors.yellowAccent
                                    : Colors.lightBlueAccent),
                          ),
                        if (!isSingleJumboEmoji) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isEdited)
                                Text(
                                  'Editado ',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.7),
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              if (timestamp != null)
                                Text(
                                  _formatTimestamp(timestamp),
                                  style: TextStyle(
                                      color: textColor.withOpacity(0.7),
                                      fontSize: 10),
                                ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                _buildStatusIcon(status, textColor.withOpacity(0.7)),
                                
                              ]
                              
                            ],
                          )
                        ],
                      ],
                    ),
            ),
            if (reactions.isNotEmpty)
              _buildReactions(context, reactions, isMe),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingBubble(BuildContext context, UploadingMessage message) {
    return Container(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (message.type == MessageType.image ||
                message.type == MessageType.video)
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.file(
                  message.file,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.4),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            if (message.type == MessageType.document ||
                message.type == MessageType.music ||
                message.type == MessageType.audio)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(
                        message.type == MessageType.music
                            ? Icons.music_note
                            : message.type == MessageType.audio
                                ? Icons.mic
                                : Icons.insert_drive_file,
                        color: Colors.white,
                        size: 30),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(message.fileName ?? "Archivo",
                            style: const TextStyle(color: Colors.white))),
                  ],
                ),
              ),
            // --- BUG 3 FIX: Replaced CircularProgressIndicator with a subtler icon ---
            Icon(
              Icons.watch_later_outlined,
              color: Colors.white.withOpacity(0.8),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactions(
      BuildContext context, Map<String, dynamic> reactions, bool isMe) {
    final reactionEntries = reactions.entries.toList();
    return Padding(
      padding:
          EdgeInsets.only(left: isMe ? 0 : 20, right: isMe ? 20 : 0, top: 2),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: reactionEntries.map((entry) {
          final count = (entry.value as List).length;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Theme.of(context).dividerColor, width: 0.5)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 12)),
                if (count > 1) ...[
                  const SizedBox(width: 4),
                  Text(count.toString(),
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold)),
                ]
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImage(BuildContext context, String imageUrl, String? caption) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => FullScreenMediaViewer(imageUrl: imageUrl))),
      child: Padding(
        padding: EdgeInsets.only(
            bottom: caption != null && caption.isNotEmpty ? 4.0 : 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideo(BuildContext context, String videoUrl,
      String? thumbnailUrl, String? caption) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => FullScreenMediaViewer(videoUrl: videoUrl))),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(
                bottom: caption != null && caption.isNotEmpty ? 4.0 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: CachedNetworkImage(
                  imageUrl: thumbnailUrl ?? '',
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.videocam),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 50),
          ),
        ],
      ),
    );
  }

  Widget _buildContact(BuildContext context, Map<String, dynamic> contactData,
      Color textColor) {
    final isMe = (doc!.data() as Map<String, dynamic>)['sender_uid'] ==
        FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<bool>(
      future:
          isMe ? Future.value(true) : FirestoreService().isContact(contactData['uid']),
      builder: (context, snapshot) {
        final bool isAlreadyContact = snapshot.data ?? false;

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: textColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.person, size: 40, color: textColor),
                title: Text(contactData['name'] ?? 'Contacto',
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.bold)),
                subtitle: Text(contactData['phone'] ?? '',
                    style: TextStyle(color: textColor.withOpacity(0.8))),
              ),
              if (!isAlreadyContact) ...[
                const Divider(),
                TextButton(
                  onPressed: () =>
                      onAddContact(contactData['uid'], contactData['name']),
                  child: const Text('Añadir a contactos'),
                )
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileMessage(BuildContext context, Map<String, dynamic> fileData,
      IconData icon, Color textColor) {
    final size = fileData['size'];
    final sizeText = (size is num) ? filesize(size) : '...';

    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, size: 40, color: textColor),
        title: Text(fileData['name'] ?? 'Archivo',
            style: TextStyle(color: textColor)),
        subtitle: Text(sizeText,
            style: TextStyle(color: textColor.withOpacity(0.8))),
        trailing: Icon(Icons.download, color: textColor),
        onTap: () async {
          final url = fileData['url'];
          if (url != null) {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }

  Widget _buildDocument(BuildContext context,
      Map<String, dynamic> documentData, Color textColor) {
    return _buildFileMessage(
        context, documentData, Icons.insert_drive_file, textColor);
  }
}

class AudioPlayerWidget extends StatelessWidget {
  final String audioUrl;
  final int? durationInMilliseconds;
  final bool isMe;
  final String? contactPhotoUrl;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.durationInMilliseconds,
    required this.isMe,
    this.contactPhotoUrl,
  });

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioPlayerProvider>();
    final isCurrentlyPlaying =
        audioProvider.currentUrl == audioUrl && audioProvider.isPlaying;

    final currentPosition = audioProvider.currentUrl == audioUrl
        ? audioProvider.currentPosition
        : Duration.zero;
    final totalDuration = audioProvider.currentUrl == audioUrl
        ? audioProvider.totalDuration
        : (durationInMilliseconds != null
            ? Duration(milliseconds: durationInMilliseconds!)
            : Duration.zero);

    final double progress = (totalDuration.inMilliseconds > 0)
        ? (currentPosition.inMilliseconds / totalDuration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    final color = isMe
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSecondaryContainer;
    final waveColor = color.withOpacity(0.5);
    final progressColor = color;

    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                color: color, size: 28),
            onPressed: () => context.read<AudioPlayerProvider>().play(audioUrl),
          ),
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundImage:
                    contactPhotoUrl != null && contactPhotoUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(contactPhotoUrl!)
                        : null,
                child: contactPhotoUrl == null || contactPhotoUrl!.isEmpty
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (audioProvider.currentUrl == audioUrl) {
                      final box = context.findRenderObject() as RenderBox;
                      final newProgress =
                          (details.localPosition.dx / box.size.width)
                              .clamp(0.0, 1.0);
                      audioProvider.seek(totalDuration * newProgress);
                    }
                  },
                  child: CustomPaint(
                    size: const Size(double.infinity, 30),
                    painter: WaveformPainter(
                      waveColor: waveColor,
                      progressColor: progressColor,
                      progress: progress,
                      // --- BUG 1 FIX: Pass the audioUrl to ensure a consistent seed ---
                      seed: audioUrl.hashCode,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(currentPosition),
                        style: TextStyle(
                            color: color.withOpacity(0.8), fontSize: 11)),
                    Text(_formatDuration(totalDuration),
                        style: TextStyle(
                            color: color.withOpacity(0.8), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final Color waveColor;
  final Color progressColor;
  final double progress;
  // --- BUG 1 FIX: The waveform data is now final and passed in ---
  final List<double> _waveformData;

  WaveformPainter({
    required this.waveColor,
    required this.progressColor,
    required this.progress,
    required int seed,
  }) : _waveformData = _generateWaveformData(seed);

  // --- BUG 1 FIX: The generation logic is now a static method ---
  static List<double> _generateWaveformData(int seed) {
    // Use the seed to create a predictable random sequence
    final random = Random(seed);
    return List<double>.generate(50, (index) {
      final value = (index % 15 == 0)
          ? 0.2
          : (index % 5 == 0)
              ? 0.4
              : 0.6;
      // Use the seeded random generator
      return value + (random.nextDouble() * 0.4);
    }).toList();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final middleY = size.height / 2;
    final widthPerBar = size.width / _waveformData.length;
    final progressWidth = size.width * progress;

    for (int i = 0; i < _waveformData.length; i++) {
      final barHeight = _waveformData[i] * size.height * 0.8;
      final startX = i * widthPerBar;

      final barPaint = paint
        ..color = (startX < progressWidth) ? progressColor : waveColor;

      canvas.drawLine(
        Offset(startX, middleY - barHeight / 2),
        Offset(startX, middleY + barHeight / 2),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    // Only repaint if the progress changes. The waveform itself never changes.
    return progress != oldDelegate.progress;
  }
}