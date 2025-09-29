import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:simplechat/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:simplechat/providers/audio_player_provider.dart';
import 'package:simplechat/services/auth_gate.dart';
import 'package:simplechat/services/firestore_service.dart';
import 'package:simplechat/services/notification_service.dart';
import 'package:simplechat/services/storage_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await initializeDateFormatting('es', null);
  
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  
  // 1. Creamos la instancia del servicio
  final notificationService = NotificationService();
  // 2. Ejecutamos la inicialización segura (sin UI)
  await notificationService.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioPlayerProvider()),
        // 3. Proveemos la instancia ya inicializada al resto de la app
        Provider<NotificationService>(create: (_) => notificationService),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<StorageService>(create: (_) => StorageService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      // 4. Pasamos la navigatorKey a nuestro widget principal
      child: MyApp(navigatorKey: notificationService.navigatorKey),
    ),
  );
}

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  const MyApp({super.key, required this.navigatorKey});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  StreamSubscription<User?>? _authSubscription;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // --- LA SOLUCIÓN AL BUG ---
    // 5. Una vez que este widget se construye, la UI está lista.
    //    Ahora es seguro configurar el listener para notificaciones de app terminada.
    context.read<NotificationService>().setupInteractedMessage();

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() {
         _currentUser = user;
      });
      if (_currentUser != null) {
        context.read<FirestoreService>().updateUserPresence(isOnline: true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_currentUser == null || !mounted) return;
    
    final firestoreService = context.read<FirestoreService>();

    switch (state) {
      case AppLifecycleState.resumed:
        firestoreService.updateUserPresence(isOnline: true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        firestoreService.updateUserPresence(isOnline: false);
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      navigatorKey: widget.navigatorKey, // La navigatorKey se asigna aquí
      title: 'SimpleChat',
      theme: themeProvider.themeData,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}