import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_config.dart';
import '../models/shell_model.dart';
import 'rfid_service.dart';
import 'led_service.dart';
import 'audio_service.dart';

enum GamePhase { menu, countdown, playing, victory }

class GameController extends ChangeNotifier {
  final RfidService  _rfid  = RfidService();
  final LedService   _led   = LedService();
  final AudioService _audio = AudioService();

  GamePhase phase           = GamePhase.menu;
  int countdown             = GameConfig.countdownSeconds;
  int secondsRemaining      = GameConfig.gameDurationSeconds;
  int score                 = 0;

  late List<ShellModel> shells;
  StreamSubscription<TagEvent>? _rfidSub;
  Timer? _countdownTimer;
  Timer? _gameTimer;

  // ── Init ────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final volume = prefs.getDouble('generalVolume') ?? 1.0;

    _audio.setSfxVolume(volume);
    _audio.setMusicVolume(volume);
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
  // ---- Function to go to 4 shells
  void fourShells() {
    // Implementation for 4 shells mode
  }

  // ── Countdown ───────────────────────────────────────────────────────────

  Future<void> startCountdown() async {
    // Clear any running LED effects before starting
    _led.stopAll();
    await Future.delayed(const Duration(milliseconds: 200));

    phase     = GamePhase.countdown;
    countdown = GameConfig.countdownSeconds;
    _resetShells();
    notifyListeners();

    // Small delay so screen renders before audio starts
    await Future.delayed(const Duration(milliseconds: 100));
    _audio.playCountdown();

    // Fire first pulse immediately for the first number
    _led.countdownPulse(countdown);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      countdown--;

      if (countdown > 0) {
        _led.countdownPulse(countdown);
      } else {
        t.cancel();
        _led.countdownGo();
        notifyListeners(); // show GO
        // Wait for GO animation to fully complete before starting game
        Future.delayed(const Duration(milliseconds: 1500), _startGame);
        return;
      }

      notifyListeners();
    });
  }

  // ── Game start ──────────────────────────────────────────────────────────

  void _startGame() {
    // Re-send init commands in case reader drifted out of label mode
    _rfid.reinit();

    phase            = GamePhase.playing;
    secondsRemaining = GameConfig.gameDurationSeconds;
    _led.gameStartEffect();
    _audio.playGameStart();
    _audio.startGameSoundtrack();
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
    if (event.type == TagEventType.removed) return;

    final shell = shells[event.shellNumber - 1];
    if (shell.isFound) return; // already scored, ignore duplicates

    shell.tagId = event.tagId;

    // Correct = shell scanned at its own reader
    // shells 1-4 → X002, shells 5-8 → X007
    final expectedReader = event.shellNumber <= 4
        ? GameConfig.reader1Prefix
        : GameConfig.reader2Prefix;
    final isCorrect = event.readerPrefix == expectedReader;

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
      Future.delayed(const Duration(milliseconds: 150),_endGame);
    }
  }

  // ── End game ────────────────────────────────────────────────────────────

  void _endGame() {
    _gameTimer?.cancel();
    phase = GamePhase.victory;
    _led.victoryEffect();
    _audio.playVictory();
    _audio.startGameSoundtrack();
    notifyListeners();
  }

  // ── Return to menu ──────────────────────────────────────────────────────

  void returnToMenu() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _led.stopAll();
    _audio.stopSoundtrack();
    _audio.stopAll();
    phase = GamePhase.menu;
    _resetShells();
    notifyListeners();
  }

  // ── Dispose ──────────────────────────────────────────────────────────────

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