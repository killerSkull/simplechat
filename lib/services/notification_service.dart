import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:simplechat/models/user_model.dart';
import 'package:simplechat/screens/chat_screen.dart';
import 'package:simplechat/screens/incaming_call_screen.dart';
import 'package:simplechat/services/app_state.dart';
import 'package:simplechat/services/firestore_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();

    final fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      print("FCM Token: $fcmToken");
      await FirestoreService().saveUserToken(fcmToken);
      _firebaseMessaging.onTokenRefresh.listen((token) {
        FirestoreService().saveUserToken(token);
      });
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    await _initLocalNotifications();
    await _setupInteractedMessage();

    // --- MODIFICADO: Ahora el listener distingue entre tipos de mensaje ---
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Mensaje recibido en primer plano!");
      final type = message.data['type'];

      if (type == 'incoming_call') {
        // Si es una llamada y la app está abierta, navegamos directamente
        _handleIncomingCall(message.data);
      } else {
        // Si es un mensaje de chat, usamos la lógica anterior
        final chatId = message.data['chatId'];
        if (AppState().activeChatId == chatId) {
          return;
        }
        if (message.notification != null) {
          showLocalNotification(message);
        }
      }
    });
  }

  Future<void> _initLocalNotifications() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Este canal se usa para notificaciones importantes.',
      importance: Importance.max,
      playSound: true,
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('notification_icon');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Esta lógica ahora se centraliza en _setupInteractedMessage
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void showLocalNotification(RemoteMessage message) {
    _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'Este canal se usa para notificaciones importantes.',
          icon: 'notification_icon',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  Future<void> _setupInteractedMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  /// --- MODIFICADO: Este método ahora actúa como un 'router' ---
  /// Decide qué hacer basado en el tipo de notificación.
  void _handleMessage(RemoteMessage message) {
    final type = message.data['type'];
    if (type == 'incoming_call') {
      _handleIncomingCall(message.data);
    } else {
      _handleChatMessage(message.data);
    }
  }

  /// --- NUEVO: Lógica específica para manejar una llamada entrante ---
  void _handleIncomingCall(Map<String, dynamic> data) {
    // Usamos el navigatorKey global para mostrar la pantalla de llamada
    // sin importar en qué parte de la app esté el usuario.
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => IncomingCallScreen(callData: data),
        fullscreenDialog: true, // Para que aparezca como una superposición
      ),
    );
  }

  /// --- NUEVO: Lógica extraída para manejar solo notificaciones de chat ---
  void _handleChatMessage(Map<String, dynamic> data) async {
    final senderId = data['senderId'];
    final currentUserId = FirestoreService().auth.currentUser?.uid;
    
    if (senderId != null && currentUserId != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
      if (userDoc.exists) {
        final userModel = UserModel.fromFirestore(userDoc);
        
        final contactDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).collection('contacts').doc(senderId).get();
        
        // --- CORRECCIÓN APLICADA ---
        // Se reescribe la lógica de forma explícita para mayor claridad.
        String? nickname;
        if (contactDoc.exists) {
          // Si el documento de contacto existe, intentamos obtener el apodo.
          final contactData = contactDoc.data();
          if (contactData != null && contactData.containsKey('nickname')) {
            nickname = contactData['nickname'] as String?;
          }
        }
        
        // Obtenemos el ID del chat para navegar correctamente
        final chatId = FirestoreService().getChatId(currentUserId, senderId);

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              otherUser: userModel,
              nickname: nickname,
              chatId: chatId,
            ),
          ),
        );
      }
    }
  }
}
