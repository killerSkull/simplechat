import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

// --- CAMBIO: Convertido a StatefulWidget para gestionar el estado del botón ---
class MessageInputBar extends StatefulWidget {
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

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  // Este booleano controlará qué botón se muestra.
  bool _showSendButton = false;

  @override
  void initState() {
    super.initState();
    // Añadimos un "escucha" al controlador de texto.
    // Se activará con CUALQUIER cambio (tecleo, emojis, etc.).
    widget.messageController.addListener(_updateButtonState);
    _updateButtonState(); // Comprobamos el estado inicial.
  }

  @override
  void dispose() {
    // Es importante quitar el "escucha" para evitar fugas de memoria.
    widget.messageController.removeListener(_updateButtonState);
    super.dispose();
  }
  
  // Esta función se encarga de actualizar el estado del botón.
  void _updateButtonState() {
    if (mounted) {
      final hasText = widget.messageController.text.isNotEmpty;
      if (hasText != _showSendButton) {
        setState(() {
          _showSendButton = hasText;
        });
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
    // --- AHORA USA EL ESTADO INTERNO _showSendButton ---
    final hasText = _showSendButton;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.isContact)
          Container(
            color: theme.colorScheme.surfaceContainerHighest,
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
                          icon: Icon(widget.isEmojiPickerVisible ? Icons.keyboard : Icons.emoji_emotions_outlined),
                          onPressed: widget.toggleEmojiPicker,
                          color: theme.iconTheme.color?.withOpacity(0.7),
                        ),
                        Expanded(
                          child: widget.isRecording
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(" Grabando...", style: TextStyle(color: Colors.red)),
                                  Text(_formatDuration(widget.recordingDuration), style: const TextStyle(color: Colors.red)),
                                ],
                              )
                            : TextField(
                                controller: widget.messageController,
                                onChanged: widget.onTextChanged,
                                onTap: () {
                                  if (widget.isEmojiPickerVisible) widget.toggleEmojiPicker();
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
                          onPressed: widget.onSendMedia,
                          color: theme.iconTheme.color?.withOpacity(0.7),
                        ),
                        if (!hasText)
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
                    child: hasText
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
                            widget.isRecording ? Icons.mic_off : Icons.mic,
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