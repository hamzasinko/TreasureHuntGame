import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/game_config.dart';

class LedService {
  RawDatagramSocket? _socket;
  GameMode _mode = GameMode.single;

  void setMode(GameMode mode) => _mode = mode;

  Future<void> init() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    debugPrint('[LED] UDP socket bound');
  }

  void _send(String cmd) {
    if (_socket == null) return;
    _socket!.send(
      cmd.codeUnits,
      InternetAddress(GameConfig.ledHost),
      GameConfig.ledPort,
    );
    debugPrint('[LED] → $cmd');
  }

  String _pad(int n) => n.toString().padLeft(3, '0');

  // ── Range helpers ───────────────────────────────────────────────────────

  // Active LED range based on mode
  String get _activeFrom => _pad(
      _mode == GameMode.single ? GameConfig.singleLedStart : 0);
  String get _activeTo => _pad(
      _mode == GameMode.single ? GameConfig.singleLedEnd : 81);

  // Group A range (shells 1-4): LEDs 58-81
  String get _groupAFrom => _pad(GameConfig.groupALedStart);
  String get _groupATo   => _pad(GameConfig.groupALedEnd);

  // Group B range (shells 5-8): LEDs 0-57
  String get _groupBFrom => _pad(GameConfig.groupBLedStart);
  String get _groupBTo   => _pad(GameConfig.groupBLedEnd);

  // Single mode active range: LEDs 34-81
  String get _singleFrom => _pad(GameConfig.singleLedStart);
  String get _singleTo   => _pad(GameConfig.singleLedEnd);

  // ── Shell feedback ──────────────────────────────────────────────────────

  void shellCorrect(int shell) {
    final from = _pad(GameConfig.ledStartForShell(shell, _mode));
    final to   = _pad(GameConfig.ledEndForShell(shell, _mode));
    // Stop any fx on this lane first
    _send('stopFXRange $from $to');
    Future.delayed(const Duration(milliseconds: 50), () {
      // Strobe green 3 times on this range
      _send('strobeRange 03 080 080 000 255 000 000 $from $to');
      // Hold solid green after flash
      Future.delayed(const Duration(milliseconds: 600), () {
        _send('stopFXRange $from $to');
        _send('setBG 000 255 000 000 $from $to');
      });
    });
  }

  void shellWrong(int shell) {
    final from = _pad(GameConfig.ledStartForShell(shell, _mode));
    final to   = _pad(GameConfig.ledEndForShell(shell, _mode));
    _send('stopFXRange $from $to');
    Future.delayed(const Duration(milliseconds: 50), () {
      // Strobe red 3 times on this range
      _send('strobeRange 03 080 080 255 000 000 000 $from $to');
      // Hold solid red after flash
      Future.delayed(const Duration(milliseconds: 600), () {
        _send('stopFXRange $from $to');
        _send('setBG 255 000 000 000 $from $to');
      });
    });
  }

  void shellOff(int shell) {
    final from = _pad(GameConfig.ledStartForShell(shell, _mode));
    final to   = _pad(GameConfig.ledEndForShell(shell, _mode));
    _send('stopFXRange $from $to');
    _send('setBG 000 000 000 000 $from $to');
  }

  // ── Group celebration (two-group mode only) ─────────────────────────────

  void groupCelebration(int group) {
    if (_mode != GameMode.twoGroups) return;
    final from = group == 1 ? _groupAFrom : _groupBFrom;
    final to   = group == 1 ? _groupATo   : _groupBTo;
    // Stop any running fx on this group's range
    Future.delayed(const Duration(milliseconds: 700), () {
      // Fast green disco on this group's range only
      _send('stopFXRange $from $to');
      _send('stopRaceFXRange $from $to');
      _send('discoRange 08 0050 G $from $to');
    });
  }

  // ── Global ──────────────────────────────────────────────────────────────

  void allOff() => _send('allOff');

  void setBgIdle() {
    if (_mode == GameMode.single) {
      // Only light up active range 34-81
      _send('setBG 000 000 000 000 000 033'); // off for 0-33
      _send('setBG 080 030 000 000 $_singleFrom $_singleTo');
    } else {
      // Both groups active 0-81
      _send('setBG 080 030 000 000 000 081');
    }
  }

  // ── Countdown ───────────────────────────────────────────────────────────

  void countdownPulse(int secondsLeft) {
    // Clear active range only
    _send('stopFXRange $_activeFrom $_activeTo');
    _send('setBG 000 000 000 000 $_activeFrom $_activeTo');

    String color;
    switch (secondsLeft) {
      case 5: color = '000 000 255 000'; break; // blue
      case 4: color = '000 255 000 000'; break; // green
      case 3: color = '000 255 255 000'; break; // cyan
      case 2: color = '255 255 000 000'; break; // yellow
      case 1: color = '255 000 000 000'; break; // red
      default: color = '255 000 000 000';
    }

    Future.delayed(const Duration(milliseconds: 50), () {
      _send('setBG $color $_activeFrom $_activeTo');
      Future.delayed(const Duration(milliseconds: 800),
          () => _send('setBG 000 000 000 000 $_activeFrom $_activeTo'));
    });
  }

  void countdownGo() {
    _send('stopFXRange $_activeFrom $_activeTo');
    _send('setBG 000 000 000 000 $_activeFrom $_activeTo');
    // 3 white flashes on active range
    Future.delayed(const Duration(milliseconds: 100),
        () => _send('setBG 255 255 255 000 $_activeFrom $_activeTo'));
    Future.delayed(const Duration(milliseconds: 400),
        () => _send('setBG 000 000 000 000 $_activeFrom $_activeTo'));
    Future.delayed(const Duration(milliseconds: 550),
        () => _send('setBG 255 255 255 000 $_activeFrom $_activeTo'));
    Future.delayed(const Duration(milliseconds: 850),
        () => _send('setBG 000 000 000 000 $_activeFrom $_activeTo'));
    Future.delayed(const Duration(milliseconds: 1000),
        () => _send('setBG 255 255 255 000 $_activeFrom $_activeTo'));
    Future.delayed(const Duration(milliseconds: 1300),
        () => _send('setBG 000 000 000 000 $_activeFrom $_activeTo'));
    Future.delayed(const Duration(milliseconds: 1500), setBgIdle);
  }

  // ── Game start ──────────────────────────────────────────────────────────

  void gameStartEffect() {
    if (_mode == GameMode.single) {
      // Race only on active range 34-81
      _send('startRaceRange A $_singleFrom $_singleTo 01');
      Future.delayed(const Duration(seconds: 2), () {
        _send('stopRaceRange A $_singleFrom $_singleTo');
        _send('stopRaceFXRange $_singleFrom $_singleTo');
        setBgIdle();
      });
    } else {
      // Race on full range for two groups
      _send('startRaceRange A 000 081 01');
      Future.delayed(const Duration(seconds: 2), () {
        _send('stopRaceRange A 000 081');
        _send('stopRaceFXRange 000 081');
        setBgIdle();
      });
    }
  }

  // ── Victory ─────────────────────────────────────────────────────────────

  void victoryEffect() {
    Future.delayed(const Duration(milliseconds: 800), () {
      // Full disco on entire strip
      _send('allOff');
      _send('discoRange 08 0050 A 000 081');
    });
  }

  // ── Stop all ────────────────────────────────────────────────────────────

  void stopAll() {
    _send('stopRaceRange A 000 081');
    _send('stopRaceFXRange 000 081');
    _send('stopFXRange 000 081');
    _send('allOff');
  }

  void dispose() {
    _socket?.close();
    _socket = null;
  }
}