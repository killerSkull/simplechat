import 'dart:io';

enum MessageType { image, video, audio, document, music }

class UploadingMessage {
  final String id;
  final String filePath;
  final String? fileName;
  final int fileSize; // <-- MODIFICADO: Ahora es obligatorio
  final MessageType type;
  double progress;

  UploadingMessage({
    required this.id,
    required this.filePath,
    required this.fileSize,
    required this.type,
    this.fileName,
    this.progress = 0.0,
  });

  File get file => File(filePath);
}