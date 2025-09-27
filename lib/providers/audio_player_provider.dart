import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

class AudioPlayerProvider with ChangeNotifier {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  StreamSubscription? _playerSubscription;

  String? _currentUrl;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  String? get currentUrl => _currentUrl;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  AudioPlayerProvider() {
    _player.openPlayer().then((_) {
      _player.setSubscriptionDuration(const Duration(milliseconds: 100));
    });
  }

  Future<void> play(String url) async {
    if (_isPlaying && _currentUrl == url) {
      await pause();
      return;
    }

    if (_isPlaying || _player.isPaused) {
      await stop();
    }
    
    _currentUrl = url;
    await _player.startPlayer(
      fromURI: url,
      whenFinished: () {
        stop();
      },
    );

    _playerSubscription?.cancel();
    _playerSubscription = _player.onProgress!.listen((playback) {
      _currentPosition = playback.position;
      _totalDuration = playback.duration;
      notifyListeners();
    });

    _isPlaying = true;
    notifyListeners();
  }

  Future<void> pause() async {
    if (_isPlaying) {
      await _player.pausePlayer();
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> seek(Duration position) async {
    if (_currentUrl != null) {
      await _player.seekToPlayer(position);
    }
  }

  Future<void> stop() async {
    if (_player.isPlaying || _player.isPaused) {
      await _player.stopPlayer();
    }
    _currentUrl = null;
    _isPlaying = false;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    _playerSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _player.closePlayer();
    super.dispose();
  }
}