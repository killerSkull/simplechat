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
  
  final notificationService = NotificationService();
  final themeProvider = ThemeProvider();
  
  // Se espera a que el tema esté cargado antes de arrancar la app
  await themeProvider.loadPreferences();
  
  runApp(
    MultiProvider(
      providers: [
        // --- CORRECCIÓN CRÍTICA ---
        // Se crea el GlobalKey aquí para que esté disponible en toda la app
        Provider<GlobalKey<NavigatorState>>(create: (_) => GlobalKey<NavigatorState>()),
        
        // --- CORRECCIÓN DEL ERROR ---
        // Se usa el constructor correcto para crear un nuevo AudioPlayerProvider
        ChangeNotifierProvider(create: (_) => AudioPlayerProvider()),
        
        // Se proveen las instancias ya creadas de los servicios
        Provider.value(value: notificationService),
        Provider(create: (_) => FirestoreService()),
        Provider(create: (_) => StorageService()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: MyApp(notificationService: notificationService),
    ),
  );
}

class MyApp extends StatefulWidget {
  final NotificationService notificationService;
  const MyApp({super.key, required this.notificationService});

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

    // Se inicializa el servicio de notificaciones después de que la UI esté lista,
    // pasándole el GlobalKey que ahora sí está disponible en el context.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.notificationService.init(navigatorKey: context.read<GlobalKey<NavigatorState>>());
    });
    
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
      case AppLifecycleState.hidden:
        firestoreService.updateUserPresence(isOnline: false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      // Se asigna el GlobalKey al MaterialApp para que controle la navegación
      navigatorKey: context.read<GlobalKey<NavigatorState>>(),
      title: 'SimpleChat',
      theme: themeProvider.themeData,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}