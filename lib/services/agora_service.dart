import 'package:cloud_functions/cloud_functions.dart';

class AgoraService {
  // --- ¡MUY IMPORTANTE! ---
  // Reemplaza esto con tu App ID de Agora.
  static const String appId = "77d636faa353436a99029acd0095cefa";
  
  // La función getChannelId se ha eliminado porque ahora usamos el chatId existente.

  // --- Función para obtener el token de Agora desde Firebase ---
  static Future<String?> fetchToken(String channelName) async {
    try {
      // Llama a la función de Firebase que creamos en index.js
      final callable = FirebaseFunctions.instance.httpsCallable('generateAgoraToken');
      final results = await callable.call({'channelName': channelName});
      // Devuelve el token que nos da el servidor
      return results.data['token'];
    } on FirebaseFunctionsException catch (e) {
      print('Error al obtener el token de Agora: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Error inesperado al obtener el token: $e');
      return null;
    }
  }
}