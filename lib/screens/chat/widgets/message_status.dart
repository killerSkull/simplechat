import 'package:flutter/material.dart';

class MessageStatus extends StatelessWidget {
  final String? status;
  final String timestamp;
  final bool isMe;
  final Color color;

  const MessageStatus({
    super.key,
    required this.status,
    required this.timestamp,
    required this.isMe,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    Widget? statusIcon;
    if (isMe) {
      switch (status) {
        case 'sending':
          statusIcon = Icon(Icons.watch_later_outlined, size: 14, color: color);
          break;
        case 'sent':
          statusIcon = Icon(Icons.done, size: 14, color: color);
          break;
        case 'delivered':
          statusIcon = Icon(Icons.done_all, size: 14, color: color);
          break;
        case 'read':
          // El color azul especial para el estado 'leído'
          statusIcon = const Icon(Icons.done_all, size: 14, color: Colors.lightBlueAccent);
          break;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          timestamp,
          style: TextStyle(color: color, fontSize: 10),
        ),
        if (statusIcon != null) ...[
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 1.0), // Pequeño ajuste visual
            child: statusIcon,
          ),
        ],
      ],
    );
  }
}