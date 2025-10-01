import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:simplechat/screens/incaming_call_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:simplechat/models/user_model.dart';
import 'package:simplechat/screens/chat_screen.dart';
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

  static String? currentHandledCallId;

  /// --- PASO 1: INICIALIZACIÓN BÁSICA ---
  /// Esto se puede ejecutar de forma segura antes de que la UI se construya.
  Future<void> init({required GlobalKey<NavigatorState> navigatorKey}) async {
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
    
    // Configura los listeners para cuando la app está abierta o en segundo plano
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  /// --- PASO 2: GESTIÓN DE INTERACCIÓN ---
  /// Esta función SÓLO debe llamarse después de que la UI esté lista.
  /// Se encarga de la notificación que abre la app desde un estado terminado.
  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      // Añadimos un pequeño retraso para garantizar que el Navigator esté 100% listo.
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleMessage(initialMessage);
      });
    }
  }

  // --- (El resto del archivo se mantiene igual, pero lo incluyo para que esté completo) ---

  void _onForegroundMessage(RemoteMessage message) {
    print("Mensaje recibido en primer plano!");
    final type = message.data['type'];

    if (type == 'incoming_call') {
      _handleIncomingCall(message.data);
    } else {
      final chatId = message.data['chatId'];
      if (AppState().activeChatId == chatId) {
        return;
      }
      if (message.notification != null) {
        showLocalNotification(message);
      }
    }
  }

  void _handleMessage(RemoteMessage message) {
    final type = message.data['type'];
    if (type == 'incoming_call') {
      _handleIncomingCall(message.data);
    } else {
      _handleChatMessage(message.data);
    }
  }
  
  void _handleIncomingCall(Map<String, dynamic> data) {
    final String? callId = data['callId'];
    if (callId == null || callId.isEmpty || callId == currentHandledCallId) {
      return;
    }
    currentHandledCallId = callId;

    // Usamos el navigatorKey.currentState, que ahora sabemos que está listo.
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => IncomingCallScreen(callData: data),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _initLocalNotifications() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', 'High Importance Notifications',
      description: 'Este canal se usa para notificaciones importantes.',
      importance: Importance.max, playSound: true);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('notification_icon');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true, requestBadgePermission: true, requestAlertPermission: true);
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    await _localNotifications.initialize(initializationSettings);
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  void showLocalNotification(RemoteMessage message) {
    _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel', 'High Importance Notifications',
          channelDescription: 'Este canal se usa para notificaciones importantes.',
          icon: 'notification_icon', importance: Importance.max, priority: Priority.high, playSound: true),
        iOS: const DarwinNotificationDetails(
          sound: 'default', presentAlert: true, presentBadge: true, presentSound: true),
      ),
      payload: message.data.toString(),
    );
  }

  void _handleChatMessage(Map<String, dynamic> data) async {
    final senderId = data['senderId'];
    final currentUserId = FirestoreService().auth.currentUser?.uid;
    
    if (senderId != null && currentUserId != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
      if (userDoc.exists) {
        final userModel = UserModel.fromFirestore(userDoc);
        final contactDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).collection('contacts').doc(senderId).get();
        
        String? nickname;
        if (contactDoc.exists) {
          final contactData = contactDoc.data();
          if (contactData != null && contactData.containsKey('nickname')) {
            nickname = contactData['nickname'] as String?;
          }
        }
        
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