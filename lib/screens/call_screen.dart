import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:simplechat/services/agora_service.dart';
import 'package:simplechat/services/firestore_service.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String token;
  final String otherUserName;
  final bool isVideoCall;

  const CallScreen({
    super.key,
    required this.channelName,
    required this.token,
    required this.otherUserName,
    this.isVideoCall = true,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final RtcEngine _engine;
  late final FirestoreService _firestoreService;
  StreamSubscription? _callStreamSubscription;

  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isVideoDisabled = false;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _initializeAgora();
    _listenToCallChanges();
  }

  @override
  void dispose() {
    _firestoreService.endCall(widget.channelName, _firestoreService.auth.currentUser!.uid);
    _callStreamSubscription?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  void _listenToCallChanges() {
    _callStreamSubscription = _firestoreService.getCallStream(widget.channelName).listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'];
        if (status != 'ongoing' && status != 'ringing') {
          if (mounted) Navigator.of(context).pop();
        }
      } else {
         if (mounted) Navigator.of(context).pop();
      }
    });
  }

  Future<void> _initializeAgora() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(appId: AgoraService.appId));

      // --- CORRECCIÓN DEFINITIVA ---
      // Se establece el perfil del canal a "Comunicación". Esto le dice a Agora
      // que optimice para una llamada 1 a 1 de baja latencia. Es crucial
      // hacerlo después de inicializar y antes de unirse.
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
            if (mounted) Navigator.of(context).pop();
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
        await _engine.disableVideo();
        await _engine.enableAudio();
        setState(() => _isVideoDisabled = true);
      }

      await Future.delayed(const Duration(milliseconds: 200));

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
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Para el estilo pixel art que te gusta, mantenemos la lógica
    final isPixelTheme = theme.textTheme.bodyLarge?.fontFamily == 'PressStart2P';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: [
            _buildRemoteVideo(),
            if (_localUserJoined)
              Positioned(
                top: 50,
                right: 20,
                child: _buildLocalVideo(),
              ),
            _buildCallControls(isPixelTheme),
            if (!_localUserJoined) const Center(child: CircularProgressIndicator()),
            _buildTopInfo(),
          ],
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

  Widget _buildCallControls(bool isPixelTheme) {
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
                _engine.enableLocalVideo(!_isVideoDisabled);
                setState(() => _isVideoDisabled = !_isVideoDisabled);
              },
              icon: _isVideoDisabled ? Icons.videocam_off : Icons.videocam,
              color: _isVideoDisabled ? Colors.red : Colors.white,
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
              if (mounted) Navigator.of(context).pop();
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