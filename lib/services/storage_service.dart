import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- MODIFICADO: Ahora todos los métodos de subida aceptan un callback de progreso ---
  UploadTask _uploadFile(String refPath, File file) {
    final ref = _storage.ref().child(refPath);
    return ref.putFile(file);
  }

  UploadTask uploadProfileImage({required String userId, required File file}) {
    return _uploadFile('profile_pictures/$userId.jpg', file);
  }

  UploadTask uploadChatImage({required String chatId, required File file}) {
    final fileName = const Uuid().v4();
    return _uploadFile('chat_media/$chatId/images/$fileName.jpg', file);
  }
  
  // El método de video ahora es más complejo, así que no usa el helper
  Future<Map<String, String>?> uploadChatVideo({
    required String chatId,
    required File file,
    required Function(double) onProgress,
  }) async {
    try {
      final fileName = const Uuid().v4();
      final videoRef = _storage.ref().child('chat_media/$chatId/videos/$fileName.mp4');
      final videoUploadTask = videoRef.putFile(file);

      // Escuchar el progreso de la subida del video
      videoUploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
        onProgress(progress);
      });

      final videoSnapshot = await videoUploadTask;
      final videoUrl = await videoSnapshot.ref.getDownloadURL();

      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: file.path,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
      );
      
      if (thumbnailPath == null) {
        return {'videoUrl': videoUrl, 'thumbnailUrl': ''};
      }

      final thumbRef = _storage.ref().child('chat_media/$chatId/thumbnails/$fileName.jpg');
      final thumbUploadTask = thumbRef.putFile(File(thumbnailPath));
      final thumbSnapshot = await thumbUploadTask;
      final thumbUrl = await thumbSnapshot.ref.getDownloadURL();
      
      return {'videoUrl': videoUrl, 'thumbnailUrl': thumbUrl};
      
    } catch (e) {
      print("Error al subir video de chat: $e");
      return null;
    }
  }

  UploadTask uploadChatAudio({required String chatId, required String filePath}) {
    final fileName = const Uuid().v4();
    return _uploadFile('chat_media/$chatId/audio/$fileName.m4a', File(filePath));
  }

  UploadTask uploadChatFile({
    required String chatId,
    required String filePath,
    required String folder,
  }) {
    final file = File(filePath);
    final fileName = file.path.split('/').last;
    return _uploadFile('chat_media/$chatId/$folder/$fileName', file);
  }

  // --- (El resto de los métodos como deleteUserProfilePicture se mantienen) ---
    Future<void> deleteUserProfilePicture(String userId) async {
    try {
      final ref = _storage.ref().child('profile_pictures').child('$userId.jpg');
      await ref.delete();
    } catch (e) {
      // Ignora el error si el archivo no existe
      if (e is FirebaseException && e.code == 'object-not-found') {
        return;
      }
      print("Error al eliminar la foto de perfil: $e");
    }
  }
}
