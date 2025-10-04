import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

class MessageInputBar extends StatefulWidget {
  final TextEditingController messageController;
  final bool isContact;
  final bool isEmojiPickerVisible;
  final bool isRecording;
  final bool isRecorderInitialized;
  // --- BUG 1 FIX: Receive a ValueNotifier instead of a static Duration ---
  final ValueNotifier<Duration> recordingDurationNotifier;
  final VoidCallback onAddContact;
  final VoidCallback onSendMessage;
  final VoidCallback onSendMedia;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final ValueChanged<String> onTextChanged;
  final VoidCallback toggleEmojiPicker;
  final VoidCallback onOpenCamera;
  final bool isEditing;
  final VoidCallback onCancelEdit;
  final VoidCallback onConfirmEdit;

  const MessageInputBar({
    super.key,
    required this.messageController,
    required this.isContact,
    required this.isEmojiPickerVisible,
    required this.isRecording,
    required this.isRecorderInitialized,
    required this.recordingDurationNotifier,
    required this.onAddContact,
    required this.onSendMessage,
    required this.onSendMedia,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onTextChanged,
    required this.toggleEmojiPicker,
    required this.onOpenCamera,
    required this.isEditing,
    required this.onCancelEdit,
    required this.onConfirmEdit,
  });

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  bool _showSendButton = false;
   final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.messageController.addListener(_updateButtonState);
    if (widget.isEditing) {
      _focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(covariant MessageInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditing && !oldWidget.isEditing) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    widget.messageController.removeListener(_updateButtonState);
    _focusNode.dispose();
    super.dispose();
  }
  
  
  void _updateButtonState() {
    if (mounted) {
      final hasText = widget.messageController.text.isNotEmpty;
      if (hasText != _showSendButton) {
        setState(() => _showSendButton = hasText);
      }
    }
  }


  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _showSendButton;
    final theme = Theme.of(context);
    final isRecording = widget.recordingDurationNotifier.value > Duration.zero;

    if (!widget.isContact && !widget.isEditing) {
      return Container(
        color: theme.colorScheme.surfaceVariant,
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Añadir a contactos para chatear'),
              onPressed: widget.onAddContact,
              style: ElevatedButton.styleFrom(
                foregroundColor: theme.colorScheme.onPrimary,
                backgroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    if (!widget.isContact) {
       return Container(
            color: theme.colorScheme.surfaceVariant,
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Añadir a contactos para chatear'),
                  onPressed: widget.onAddContact,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onPrimary,
                    backgroundColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
    }
      
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            color: theme.scaffoldBackgroundColor,
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
                        widget.isEditing 
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.onCancelEdit,
                        color: theme.iconTheme.color?.withOpacity(0.7),
                      )
                        : IconButton(
                          icon: Icon(widget.isEmojiPickerVisible ? Icons.keyboard : Icons.emoji_emotions_outlined),
                          onPressed: widget.toggleEmojiPicker,
                          color: theme.iconTheme.color?.withOpacity(0.7),
                        ),
                        Expanded(
                          // --- BUG 1 FIX: Use ValueListenableBuilder ---
                          // This widget listens to the notifier and only rebuilds the timer text.
                          child: ValueListenableBuilder<Duration>(
                            valueListenable: widget.recordingDurationNotifier,
                            builder: (context, duration, child) {
                              if (widget.isRecording) {
                                return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(" Grabando...", style: TextStyle(color: Colors.red)),
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: Text(_formatDuration(duration), style: const TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  );
                              }
                              // If not recording, return the original text field
                              return child!;
                            },
                            child: TextField(
                              controller: widget.messageController,
                              onChanged: widget.onTextChanged,
                              onTap: () {
                                if (widget.isEmojiPickerVisible) widget.toggleEmojiPicker();
                              },
                              maxLines: 5,
                              minLines: 1,
                              decoration: const InputDecoration(
                                hintText: 'Mensaje',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                              ),
                            ),
                          ),
                        ),
                        if (!widget.isEditing)
                        IconButton(
                          icon: const Icon(Icons.attach_file),
                          onPressed: widget.onSendMedia,
                          color: theme.iconTheme.color?.withOpacity(0.7),
                        ),
                        if (!hasText && !widget.isEditing)
                          IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: widget.onOpenCamera,
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
                    child: (widget.isEditing && hasText)
                      ? IconButton(
                        key: const ValueKey('confirm_icon'),
                        icon: const Icon(Icons.check, color: Colors.white),
                        onPressed: widget.onConfirmEdit,
                        )
                    : hasText
                      ? IconButton(
                          key: const ValueKey('send_icon'),
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: widget.isRecording ? null : widget.onSendMessage,
                        )
                      : GestureDetector(
                          key: const ValueKey('mic_icon'),
                          onLongPress: widget.onStartRecording,
                          onLongPressEnd: (details) => widget.onStopRecording(),
                          child: Icon(
                            widget.isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        if (widget.isEmojiPickerVisible)
          SizedBox(
            height: 300,
            child: EmojiPicker(
              textEditingController: widget.messageController,
              onBackspacePressed: () {
                widget.messageController
                  ..text = widget.messageController.text.characters.skipLast(0).toString()
                  ..selection = TextSelection.fromPosition(
                      TextPosition(offset: widget.messageController.text.length));
              },
              config: Config(
                bgColor: theme.scaffoldBackgroundColor,
                iconColorSelected: theme.colorScheme.primary,
                indicatorColor: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}