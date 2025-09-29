import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:simplechat/services/agora_service.dart';
import 'package:simplechat/services/firestore_service.dart';

class CallScreen extends StatefulWidget {
  final String callId;
  final String channelName;
  final String token;
  final String otherUserName;
  final bool isVideoCall;

  const CallScreen({
    super.key,
    required this.callId,
    required this.channelName,
    required this.token,
    required this.otherUserName,
    required this.isVideoCall,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final RtcEngine _engine;
  final FirestoreService firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // --- NUEVO: Se usa una suscripción en lugar de un StreamBuilder ---
  // Esto separa la lógica de la UI y evita cierres inesperados.
  StreamSubscription<DocumentSnapshot>? _callSubscription;

  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isVideoDisabled = false;

  @override
  void initState() {
    super.initState();
    _initializeAgora();
    _listenForCallEnd();
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    _engine.leaveChannel();
    _engine.release();
    // --- LÓGICA DE FINALIZACIÓN DE LLAMADA ---
    // Al salir de la pantalla, se elimina el documento de la llamada para todos.
    if (currentUser != null) {
      firestoreService.endCall(widget.callId, currentUser!.uid);
    }
    super.dispose();
  }

  // --- NUEVO: Lógica de escucha aislada ---
  void _listenForCallEnd() {
    _callSubscription =
        firestoreService.getCallStream(widget.callId).listen((snapshot) {
      // Si el documento de la llamada deja de existir, significa que alguien colgó.
      if (mounted && !snapshot.exists) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _initializeAgora() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(appId: AgoraService.appId));

      await _engine.setChannelProfile(ChannelProfileType.channelProfileCommunication);

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            setState(() => _localUserJoined = true);
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            setState(() => _remoteUid = remoteUid);
          },
          onUserOffline: (connection, remoteUid, reason) {
            setState(() => _remoteUid = null);
            // El cierre ahora es manejado por _listenForCallEnd
          },
          onError: (err, msg) {
            print("Error de Agora: $err - $msg");
          },
        ),
      );

      if (widget.isVideoCall) {
        await _engine.enableVideo();
        await _engine.startPreview();
      } else {
        await _engine.disableVideo(); // Explícitamente desactiva el video
        await _engine.enableAudio();
      }

      await _engine.joinChannel(
        token: widget.token,
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(),
      );
    } catch (e) {
      print("--- ERROR FATAL AL INICIALIZAR AGORA: $e ---");
    }
  }

  // --- La UI se mantiene prácticamente igual, pero ahora es más estable ---
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Stack(
            children: [
              _buildRemoteVideo(),
              if (_localUserJoined && !_isVideoDisabled)
                Positioned(
                  top: 50,
                  right: 20,
                  child: _buildLocalVideo(),
                ),
              _buildCallControls(),
              _buildTopInfo(),
               if (!_localUserJoined)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopInfo() {
    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Column(
        children: [
          Text(
            widget.otherUserName,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
           if (_remoteUid == null && _localUserJoined)
            const Text(
              'Conectando...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildRemoteVideo() {
    if (_remoteUid != null && widget.isVideoCall) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isVideoCall ? Icons.videocam_off_outlined : Icons.voicemail,
                color: Colors.white.withOpacity(0.5),
                size: 80,
              ),
              const SizedBox(height: 20),
              if (!widget.isVideoCall)
                 const Text("Llamada de voz", style: TextStyle(color: Colors.white70, fontSize: 18)),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildLocalVideo() {
    if (widget.isVideoCall) {
      return SizedBox(
        width: 120,
        height: 160,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _engine,
              canvas: const VideoCanvas(uid: 0),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCallControls() {
    final theme = Theme.of(context);
    final isPixelTheme = theme.textTheme.bodyLarge?.fontFamily == 'PressStart2P';

    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            onPressed: () {
              _engine.muteLocalAudioStream(!_isMuted);
              setState(() => _isMuted = !_isMuted);
            },
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            color: _isMuted ? Colors.red : Colors.white,
            backgroundColor: Colors.white.withOpacity(0.2),
            isPixel: isPixelTheme,
          ),
          if (widget.isVideoCall)
            _buildControlButton(
              onPressed: () {
                setState(() => _isVideoDisabled = !_isVideoDisabled);
                _engine.enableLocalVideo(!_isVideoDisabled);
              },
              icon: _isVideoDisabled ? Icons.videocam_off : Icons.videocam,
              color: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.2),
              isPixel: isPixelTheme,
            ),
          if (widget.isVideoCall)
             _buildControlButton(
              onPressed: () => _engine.switchCamera(),
              icon: Icons.switch_camera,
              color: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.2),
              isPixel: isPixelTheme,
            ),
          _buildControlButton(
            onPressed: () {
              // Simplemente cierra la pantalla. El método dispose se encargará del resto.
              Navigator.of(context).pop();
            },
            icon: Icons.call_end,
            color: Colors.white,
            backgroundColor: Colors.red,
            isPixel: isPixelTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required bool isPixel,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: isPixel ? const BeveledRectangleBorder() : const CircleBorder(),
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.all(15),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}