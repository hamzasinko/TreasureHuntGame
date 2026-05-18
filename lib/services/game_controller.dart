// lib/services/game_controller.dart
//
// Central state machine for the pool shell hunt game.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game_config.dart';
import '../models/shell_model.dart';
import 'rfid_service.dart';
import 'led_service.dart';
import 'audio_service.dart';

enum GamePhase { menu, countdown, playing, victory }

class GameController extends ChangeNotifier {
  final RfidService _rfid = RfidService();
  final LedService  _led  = LedService();
  final AudioService _audio = AudioService();

  GamePhase phase = GamePhase.menu;
  int countdown = GameConfig.countdownSeconds;
  int secondsRemaining = GameConfig.gameDurationSeconds;
  int score = 0;

  late List<ShellModel> shells;
  StreamSubscription<TagEvent>? _rfidSub;
  Timer? _countdownTimer;
  Timer? _gameTimer;

  // ── Init ────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _led.init();
    await _rfid.connect();
    _rfidSub = _rfid.events.listen(_onTagEvent);
    _resetShells();
  }

  void _resetShells() {
    shells = List.generate(
      GameConfig.totalShells,
      (i) => ShellModel(number: i + 1),
    );
    score = 0;
  }

  // ── Start flow ──────────────────────────────────────────────────────────

  Future<void> startCountdown() async {
    phase = GamePhase.countdown;
    countdown = GameConfig.countdownSeconds;
    _resetShells();
    _led.setBgBlue();
    _audio.playCountdown();
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      countdown--;
      _led.countdownPulse();
      notifyListeners();

      if (countdown <= 0) {
        t.cancel();
        _startGame();
      }
    });
  }

  void _startGame() {
    phase = GamePhase.playing;
    secondsRemaining = GameConfig.gameDurationSeconds;
    _led.gameStartEffect();
    _audio.playGameStart();
    notifyListeners();

    if (GameConfig.gameDurationSeconds > 0) {
      _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        secondsRemaining--;
        notifyListeners();
        if (secondsRemaining <= 0) {
          t.cancel();
          _endGame();
        }
      });
    }
  }

  // ── Tag events ──────────────────────────────────────────────────────────

  void _onTagEvent(TagEvent event) {
    if (phase != GamePhase.playing) return;
    if (event.type == TagEventType.removed) return; // only care about detections

    final shell = shells[event.shellNumber - 1];

    // Determine if the tag was scanned at the correct antenna
    // "Correct" means shell N is found at its own antenna:
    //   shells 1-4 are found on reader X002, shells 5-8 on reader X007.
    final expectedReader = event.shellNumber <= 4
        ? GameConfig.reader1Prefix
        : GameConfig.reader2Prefix;
    final isCorrect = event.readerPrefix == expectedReader;

    if (shell.isFound) return; // already scored, ignore duplicates

    shell.tagId = event.tagId;

    if (isCorrect) {
      shell.state = ShellState.found;
      score++;
      _led.shellCorrect(event.shellNumber);
      _audio.playCorrect();
    } else {
      shell.state = ShellState.wrong;
      _led.shellWrong(event.shellNumber);
      _audio.playWrong();
    }

    notifyListeners();

    // Check win condition
    if (shells.every((s) => s.isFound)) {
      _endGame();
    }
  }

  // ── End game ────────────────────────────────────────────────────────────

  void _endGame() {
    _gameTimer?.cancel();
    phase = GamePhase.victory;
    _led.victoryEffect();
    _audio.playVictory();
    notifyListeners();
  }

  // ── Return to menu ──────────────────────────────────────────────────────

  void returnToMenu() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _led.stopAll();
    _led.allOff();
    _audio.stopAll();
    phase = GamePhase.menu;
    _resetShells();
    notifyListeners();
  }

  // ── Dispose ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _rfidSub?.cancel();
    _rfid.dispose();
    _led.dispose();
    _audio.dispose();
    _countdownTimer?.cancel();
    _gameTimer?.cancel();
    super.dispose();
  }
}
