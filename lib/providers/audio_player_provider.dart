import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

class AudioPlayerProvider with ChangeNotifier {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  StreamSubscription? _playerSubscription;

  // --- BUG 1 FIX: Use a Completer to await initialization ---
  final Completer<void> _initCompleter = Completer<void>();

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
      // --- BUG 1 FIX: Mark initialization as complete ---
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    });
  }

  Future<void> play(String url) async {
    // --- BUG 1 FIX: Wait for the player to be ready before proceeding ---
    await _initCompleter.future;

    if (_isPlaying && _currentUrl == url) {
      await pause();
      return;
    }

    if (_isPlaying || _player.isPaused) {
      await stop();
    }
    
    _currentUrl = url;
    try {
      await _player.startPlayer(
        fromURI: url,
        whenFinished: () {
          stop();
        },
      );

      _playerSubscription?.cancel();
      _playerSubscription = _player.onProgress!.listen((playback) {
        if(playback.duration.inMilliseconds > 0){
          _currentPosition = playback.position;
          _totalDuration = playback.duration;
          notifyListeners();
        }
      });

      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      print('Error starting player: $e');
      // Handle error, maybe show a snackbar
    }
  }

  Future<void> pause() async {
    if (_isPlaying) {
      await _player.pausePlayer();
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> seek(Duration position) async {
    await _initCompleter.future;
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