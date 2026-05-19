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

  // ── Shell feedback ──────────────────────────────────────────────────────

  void shellCorrect(int shell) {
    final from = _pad(GameConfig.ledStartForShell(shell));
    final to   = _pad(GameConfig.ledEndForShell(shell));
    _send('setStrobeRGBW 000 255 000 000');
    _send('strobe 03 080 080');
    Future.delayed(const Duration(milliseconds: 100), () {
      _send('setBG 000 255 000 000 $from $to');
    });
  }

  void shellWrong(int shell) {
    final from = _pad(GameConfig.ledStartForShell(shell));
    final to   = _pad(GameConfig.ledEndForShell(shell));
    _send('setStrobeRGBW 255 000 000 000');
    _send('strobe 03 080 080');
    Future.delayed(const Duration(milliseconds: 100), () {
      _send('setBG 255 000 000 000 $from $to');
    });
  }

  void shellOff(int shell) {
    final from = _pad(GameConfig.ledStartForShell(shell));
    final to   = _pad(GameConfig.ledEndForShell(shell));
    _send('setBG 000 000 000 000 $from $to');
  }

  // ── Global ──────────────────────────────────────────────────────────────

  void allOff() => _send('allOff');

  void setBgBlue() => _send('setBG 000 050 255 000 000 081');

  void setBgIdle() => _send('setBG 080 030 000 000 000 081');

  // ── Countdown ───────────────────────────────────────────────────────────

  void countdownPulse(int secondsLeft) {
    _send('allOff');
    switch (secondsLeft) {
      case 5: _send('setBG 000 000 255 000 000 081'); break; // blue
      case 4: _send('setBG 000 255 000 000 000 081'); break; // green
      case 3: _send('setBG 000 255 255 000 000 081'); break; // cyan
      case 2: _send('setBG 255 255 000 000 000 081'); break; // yellow
      case 1: _send('setBG 255 000 000 000 000 081'); break; // red
      default: _send('setBG 255 000 000 000 000 081');
    }
    Future.delayed(const Duration(milliseconds: 800), () => _send('allOff'));
  }

  void countdownGo() {
    _send('allOff');
    Future.delayed(const Duration(milliseconds: 100), () => _send('setBG 255 255 255 000 000 081'));
    Future.delayed(const Duration(milliseconds: 400), () => _send('allOff'));
    Future.delayed(const Duration(milliseconds: 550), () => _send('setBG 255 255 255 000 000 081'));
    Future.delayed(const Duration(milliseconds: 850), () => _send('allOff'));
    Future.delayed(const Duration(milliseconds: 1000), () => _send('setBG 255 255 255 000 000 081'));
    Future.delayed(const Duration(milliseconds: 1300), () => _send('allOff'));
    Future.delayed(const Duration(milliseconds: 1500), () => setBgIdle());
  }

  // ── Game start ──────────────────────────────────────────────────────────

  void gameStartEffect() {
    _send('looprace A y');
    Future.delayed(const Duration(seconds: 2), () {
      _send('looprace A n');
      _send('stopRace A');
      setBgIdle();
    });
  }

  // ── Victory ─────────────────────────────────────────────────────────────

  void victoryEffect() {
    _send('allOff');
    Future.delayed(const Duration(milliseconds: 100), () {
      _send('discoA 08 0050 0100');
    });
    _send('looprace A y');
  }

  // ── Stop all ────────────────────────────────────────────────────────────

  void stopAll() {
    _send('looprace A n');
    _send('stopRace A');
    _send('allOff');
    _send('setBgOff');
  }

  void dispose() {
    _socket?.close();
    _socket = null;
  }

  String _pad(int n) => n.toString().padLeft(3, '0');
}