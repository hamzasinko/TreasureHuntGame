// lib/services/led_service.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/game_config.dart';

class LedService {
  RawDatagramSocket? _socket;

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

  // ── Shell flash helpers ─────────────────────────────────────────────────

  /// Flash green 3 times then hold green (correct shell)
  void shellCorrect(int shell) {
    final from = _pad(GameConfig.ledStartForShell(shell));
    final to   = _pad(GameConfig.ledEndForShell(shell));
    // strobe green 3 times quickly, then set solid green background
    _send('setStrobeRGBW 000 255 000 000');
    _send('strobe 03 080 080');
    // hold green after flash settles
    Future.delayed(const Duration(milliseconds: 600), () {
      _send('setBG 000 255 000 000 $from $to');
    });
  }

  /// Flash red 3 times then hold red (wrong antenna)
  void shellWrong(int shell) {
    final from = _pad(GameConfig.ledStartForShell(shell));
    final to   = _pad(GameConfig.ledEndForShell(shell));
    _send('setStrobeRGBW 255 000 000 000');
    _send('strobe 03 080 080');
    Future.delayed(const Duration(milliseconds: 600), () {
      _send('setBG 255 000 000 000 $from $to');
    });
  }

  /// Clear a single shell lane back to idle blue
  void shellOff(int shell) {
    final from = _pad(GameConfig.ledStartForShell(shell));
    final to   = _pad(GameConfig.ledEndForShell(shell));
    _send('setBG 000 000 000 000 $from $to');
  }

  // ── Global effects ──────────────────────────────────────────────────────

  void allOff() => _send('allOff');

  void setBgBlue() => _send('setBG 000 050 255 000 000 081');

  /// Countdown pulse — white strobe single flash per tick
  void countdownPulse() {
    _send('setStrobeRGBW 255 255 255 000');
    _send('strobe 01 120 000');
  }

  /// Game start — all-colour race for 2 seconds then settle to blue
  void gameStartEffect() {
    _send('looprace A y');
    Future.delayed(const Duration(seconds: 2), () {
      _send('looprace A n');
      _send('stopRace A');
      setBgBlue();
    });
  }

  /// Victory — fast multi-colour disco (50ms per blink, 100 blinks)
  void victoryEffect() {
    _send('allOff');
    Future.delayed(const Duration(milliseconds: 100), () {
      _send('discoA 08 0050 0100'); // 50ms per blink = fast
    });
  }

  void stopAll() {
    _send('looprace A n');
    _send('stopRace A');
    _send('allOff');
  }

  void dispose() {
    _socket?.close();
    _socket = null;
  }

  String _pad(int n) => n.toString().padLeft(3, '0');
}