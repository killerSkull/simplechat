import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Mensaje recibido en primer plano!");
      final chatId = message.data['chatId'];
      
      if (AppState().activeChatId == chatId) {
        print("El usuario ya está en el chat. No se mostrará notificación local.");
        return;
      }

      if (message.notification != null) {
        showLocalNotification(message);
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
        // La lógica se maneja centralmente en _handleMessage
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

  void _handleMessage(RemoteMessage message) async {
    final data = message.data;
    final senderId = data['senderId'];
    final currentUserId = FirestoreService().auth.currentUser?.uid;
    
    if (senderId != null && currentUserId != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
      if (userDoc.exists) {
        final userModel = UserModel.fromFirestore(userDoc);
        
        final contactDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).collection('contacts').doc(senderId).get();
        
        // --- CORRECCIÓN FINAL AQUÍ ---
        // Se reescribe la lógica de forma explícita para evitar el error del analizador.
        final String? nickname;
        if (contactDoc.exists) {
          nickname = contactDoc.data()?['nickname'];
        } else {
          nickname = null;
        }

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(otherUser: userModel, nickname: nickname, chatId: 'chatId',),
          ),
        );
      }
    }
  }
}
