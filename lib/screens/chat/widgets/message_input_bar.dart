import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

class MessageInputBar extends StatelessWidget {
  final TextEditingController messageController;
  final bool isContact;
  final bool isEmojiPickerVisible;
  final bool isRecording;
  final bool isRecorderInitialized;
  final Duration recordingDuration;
  final VoidCallback onAddContact;
  final VoidCallback onSendMessage;
  final VoidCallback onSendMedia;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final ValueChanged<String> onTextChanged;
  final VoidCallback toggleEmojiPicker;
  final VoidCallback onOpenCamera;
  
  const MessageInputBar({
    super.key,
    required this.messageController,
    required this.isContact,
    required this.isEmojiPickerVisible,
    required this.isRecording,
    required this.isRecorderInitialized,
    required this.recordingDuration,
    required this.onAddContact,
    required this.onSendMessage,
    required this.onSendMedia,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onTextChanged,
    required this.toggleEmojiPicker,
    required this.onOpenCamera,
  });
  
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final hasText = messageController.text.isNotEmpty;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isContact)
          Container(
            color: theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Añadir a contactos para chatear'),
                  onPressed: onAddContact,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onPrimary, 
                    backgroundColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(isEmojiPickerVisible ? Icons.keyboard : Icons.emoji_emotions_outlined),
                          onPressed: toggleEmojiPicker,
                          color: theme.iconTheme.color?.withOpacity(0.7),
                        ),
                        Expanded(
                          child: isRecording
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(" Grabando...", style: TextStyle(color: Colors.red)),
                                  Text(_formatDuration(recordingDuration), style: const TextStyle(color: Colors.red)),
                                ],
                              )
                            : TextField(
                                controller: messageController,
                                onChanged: onTextChanged,
                                onTap: () {
                                  if (isEmojiPickerVisible) toggleEmojiPicker();
                                },
                                maxLines: 5,
                                minLines: 1,
                                decoration: InputDecoration(
                                  hintText: 'Mensaje',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                                ),
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.attach_file),
                          onPressed: onSendMedia,
                          color: theme.iconTheme.color?.withOpacity(0.7),
                        ),
                        if (!hasText)
                          IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: onOpenCamera,
                            color: theme.iconTheme.color?.withOpacity(0.7),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: hasText
                      ? IconButton(
                          key: const ValueKey('send_icon'),
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: isRecording ? null : onSendMessage,
                        )
                      : GestureDetector(
                          key: const ValueKey('mic_icon'),
                          onLongPress: onStartRecording,
                          onLongPressEnd: (details) => onStopRecording(),
                          child: Icon(
                            isRecording ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        if (isEmojiPickerVisible)
          SizedBox(
            height: 300,
            child: EmojiPicker(
              textEditingController: messageController,
              onBackspacePressed: () {
                messageController
                  ..text = messageController.text.characters.skipLast(1).toString()
                  ..selection = TextSelection.fromPosition(
                      TextPosition(offset: messageController.text.length));
              },
              config: Config(
                // --- CAMBIO: Usa el color de fondo del tema actual ---
                bgColor: theme.scaffoldBackgroundColor,
                iconColorSelected: theme.colorScheme.primary,
                indicatorColor: theme.colorScheme.primary,
                // ... el resto de la configuración se mantiene ...
              ),
            ),
          ),
      ],
    );
  }
}