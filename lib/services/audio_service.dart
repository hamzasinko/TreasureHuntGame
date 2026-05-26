// lib/services/audio_service.dart

import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _sfx        = AudioPlayer(); 
  final AudioPlayer _soundtrack = AudioPlayer(); 

  double _currentVolume = 1.0;

  Future<void> playCorrect() async {
    await _sfx.stop();
    await _sfx.play(AssetSource('sounds/correct.mp3'));
  }

  Future<void> playWrong() async {
    await _sfx.stop();
    await _sfx.play(AssetSource('sounds/wrong.mp3'));
  }

  Future<void> playCountdown() async {
    await _sfx.play(AssetSource('sounds/countdown.mp3'));
  }

  Future<void> playGameStart() async {
    await _sfx.play(AssetSource('sounds/game_start.mp3'));
  }

  Future<void> playVictory() async {
    await _sfx.play(AssetSource('sounds/victory.mp3'));
  }

  Future<void> playSplash() async {
    await _sfx.play(AssetSource('sounds/splash.mp3'));
  }

  // ── Soundtrack ────────────────────────────────────────────────────────
  Future<void> startGameSoundtrack() async {
    await _soundtrack.stop();
    await _soundtrack.setReleaseMode(ReleaseMode.loop);
    await _soundtrack.play(AssetSource('sounds/pirate-soundtrack.mp3'));
  }

  Future<void> stopSoundtrack() async {
    await _soundtrack.stop();
  }

  Future<void> stopAll() async {
    await _sfx.stop();
    await _soundtrack.stop();
  }

  void dispose() {
    _sfx.dispose();
    _soundtrack.dispose();
  }

  // ── SoundSettings ────────────────────────────────────────────────────────

  Future<void> setSfxVolume(double volume) async {
    _currentVolume = volume;
    await _sfx.setVolume(volume);
  }

  Future<void> setMusicVolume(double volume) async {
    await _soundtrack.setVolume(volume);
  }

  Future<void> playTestSound(double volume) async {
    await _sfx.setVolume(volume);
    await _sfx.stop();
    await _sfx.play(AssetSource('sounds/splash.mp3'));
  }

  double get volume => _currentVolume;
}
