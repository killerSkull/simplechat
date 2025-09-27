import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:simplechat/models/user_model.dart';

class AudioMessageBubble extends StatefulWidget {
  final String audioUrl;
  final int durationInMilliseconds;
  final bool isMe;
  final String senderUid;

  const AudioMessageBubble({
    super.key,
    required this.audioUrl,
    required this.durationInMilliseconds,
    required this.isMe,
    required this.senderUid,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  StreamSubscription? _playerSubscription;

  @override
  void initState() {
    super.initState();
    _player.openPlayer();
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _player.closePlayer();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_player.isStopped) {
      await _player.startPlayer(
          fromURI: widget.audioUrl,
          whenFinished: () {
            if (mounted) setState(() {});
          });
    } else if (_player.isPlaying) {
      await _player.pausePlayer();
    } else {
      await _player.resumePlayer();
    }
    if (mounted) setState(() {});
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMe
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSecondaryContainer;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.isMe)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(widget.senderUid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircleAvatar(radius: 20);
              final user = UserModel.fromFirestore(snapshot.data!);
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null || user.photoUrl!.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
              );
            }
          ),
        IconButton(
          icon: Icon(_player.isPlaying ? Icons.pause : Icons.play_arrow, color: color),
          onPressed: _togglePlayPause,
        ),
        Expanded(
          child: StreamBuilder<PlaybackDisposition>(
            stream: _player.onProgress,
            builder: (context, snapshot) {
              final duration = Duration(milliseconds: widget.durationInMilliseconds);
              final position = snapshot.hasData ? snapshot.data!.position : Duration.zero;
              
              double sliderValue = 0.0;
              if (duration.inMilliseconds > 0) {
                sliderValue = (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
              }
              
              return SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                  trackHeight: 2.0,
                ),
                child: Slider(
                  value: sliderValue,
                  onChanged: (value) async {
                    final newPosition = duration * value;
                    await _player.seekToPlayer(newPosition);
                  },
                  activeColor: color,
                  inactiveColor: color.withOpacity(0.3),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatDuration(Duration(milliseconds: widget.durationInMilliseconds)),
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }
}