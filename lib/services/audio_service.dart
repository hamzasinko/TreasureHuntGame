// lib/services/audio_service.dart

import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _bgPlayer = AudioPlayer();

  Future<void> playCorrect() async {
    await _player.stop();
    await _player.play(AssetSource('sounds/correct.mp3'));
  }

  Future<void> playWrong() async {
    await _player.stop();
    await _player.play(AssetSource('sounds/wrong.mp3'));
  }

  Future<void> playCountdown() async {
    await _player.play(AssetSource('sounds/countdown.mp3'));
  }

  Future<void> playGameStart() async {
    await _player.play(AssetSource('sounds/game_start.mp3'));
  }

  Future<void> playVictory() async {
    await _bgPlayer.stop();
    await _player.play(AssetSource('sounds/victory.mp3'));
  }

  Future<void> playSplash() async {
    await _player.play(AssetSource('sounds/splash.mp3'));
  }

  Future<void> stopAll() async {
    await _player.stop();
    await _bgPlayer.stop();
  }

  void dispose() {
    _player.dispose();
    _bgPlayer.dispose();
  }
}
