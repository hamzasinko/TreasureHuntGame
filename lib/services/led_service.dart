import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/game_config.dart';

class LedService {
  RawDatagramSocket? _socket;
  GameMode _mode = GameMode.single;

  final Map<String, Timer> _strobeTimers = {};

  void setMode(GameMode mode) => _mode = mode;

  Future<void> init() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    debugPrint('[LED] UDP socket bound');
  }

  void _send(String cmd) {
    if (_socket == null) {
      debugPrint('[LED] Socket not ready, dropping: $cmd');
      return;
    }
    try {
      _socket!.send(
        cmd.codeUnits,
        InternetAddress(GameConfig.ledHost),
        GameConfig.ledPort,
      );
      debugPrint('[LED] → $cmd');
    } catch (e) {
      debugPrint('[LED] Send error: $e');
    }
  }

  String _pad(int n) => n.toString().padLeft(3, '0');

  // ── Range helpers ───────────────────────────────────────────────────────

  String get _activeFrom => _pad(
      _mode == GameMode.single ? GameConfig.singleLedStart : 0);
  String get _activeTo   => _pad(
      _mode == GameMode.single ? GameConfig.singleLedEnd : 81);
  String get _groupAFrom => _pad(GameConfig.groupALedStart);
  String get _groupATo   => _pad(GameConfig.groupALedEnd);
  String get _groupBFrom => _pad(GameConfig.groupBLedStart);
  String get _groupBTo   => _pad(GameConfig.groupBLedEnd);
  String get _singleFrom => _pad(GameConfig.singleLedStart);
  String get _singleTo   => _pad(GameConfig.singleLedEnd);

  static const int _strobeHoldMs = 650;

  // ── Shell feedback ──────────────────────────────────────────────────────

  void shellCorrect(int shell) {
    final from = _pad(GameConfig.ledStartForShell(shell, _mode));
    final to   = _pad(GameConfig.ledEndForShell(shell, _mode));
    final key  = '$from-$to';
    _strobeTimers[key]?.cancel();
    _strobeTimers.remove(key);
    _runShellEffect(
      key: key,
      from: from,
      to: to,
      strobeColor: '000 255 000 000',
      holdColor:   '000 255 000 000',
    );
  }

  void shellWrong(int shell) {
    final from = _pad(GameConfig.ledStartForShell(shell, _mode));
    final to   = _pad(GameConfig.ledEndForShell(shell, _mode));
    final key  = '$from-$to';
    _strobeTimers[key]?.cancel();
    _strobeTimers.remove(key);
    _runShellEffect(
      key: key,
      from: from,
      to: to,
      strobeColor: '255 000 000 000',
      holdColor:   '255 000 000 000',
    );
  }

  Future<void> _runShellEffect({
    required String key,
    required String from,
    required String to,
    required String strobeColor,
    required String holdColor,
  }) async {
    _send('stopFXRange $from $to');
    await Future.delayed(const Duration(milliseconds: 20));
    _send('strobeRange 03 80 0080 $strobeColor $from $to');
    _strobeTimers[key] = Timer(
      Duration(milliseconds: _strobeHoldMs),
       () async {
        if (_strobeTimers.containsKey(key)) {
          _send('stopFXRange $from $to');
          await Future.delayed(const Duration(milliseconds: 30));
          _send('setBG $holdColor $from $to');
          _strobeTimers.remove(key);
        }
      },
    );
  }

  void shellOff(int shell) {
    final from = _pad(GameConfig.ledStartForShell(shell, _mode));
    final to   = _pad(GameConfig.ledEndForShell(shell, _mode));
    final key  = '$from-$to';
    _strobeTimers[key]?.cancel();
    _strobeTimers.remove(key);
    _send('stopFXRange $from $to');
    _send('setBG 000 000 000 000 $from $to');
  }

  // ── Group celebration (two-group mode only) ─────────────────────────────

  void groupCelebration(int group) {
    if (_mode != GameMode.twoGroups) return;
    _cancelStrobersInRange(group);
    _runGroupCelebration(group);
  }

  Future<void> _runGroupCelebration(int group) async {
    final from = group == 1 ? _groupAFrom : _groupBFrom;
    final to   = group == 1 ? _groupATo   : _groupBTo;
    await Future.delayed(Duration(milliseconds: _strobeHoldMs + 100));
    _send('stopFXRange $from $to');
    await Future.delayed(const Duration(milliseconds: 20));
    _send('stopRaceFXRange $from $to');
    await Future.delayed(const Duration(milliseconds: 20));
    _send('discoRange 08 0050 G $from $to');
  }

  void _cancelStrobersInRange(int group) {
    final rangeFrom = group == 1
        ? GameConfig.groupALedStart
        : GameConfig.groupBLedStart;
    final rangeTo = group == 1
        ? GameConfig.groupALedEnd
        : GameConfig.groupBLedEnd;
    final keysToCancel = <String>[];
    for (final key in _strobeTimers.keys) {
      final parts = key.split('-');
      if (parts.length == 2) {
        final ledFrom = int.tryParse(parts[0]) ?? -1;
        final ledTo   = int.tryParse(parts[1]) ?? -1;
        if (ledFrom >= rangeFrom && ledTo <= rangeTo) {
          keysToCancel.add(key);
        }
      }
    }
    for (final key in keysToCancel) {
      _strobeTimers[key]?.cancel();
      _strobeTimers.remove(key);
    }
  }

  // ── Global ──────────────────────────────────────────────────────────────

  void allOff() => _send('allOff');

  void setBgIdle() {
    if (_mode == GameMode.single) {
      _send('setBG 000 000 000 000 000 033');
      _send('setBG 080 030 000 000 $_singleFrom $_singleTo');
    } else {
      _send('setBG 080 030 000 000 000 081');
    }
  }

  // ── Countdown ───────────────────────────────────────────────────────────

  void countdownPulse(int secondsLeft) => _runCountdownPulse(secondsLeft);

  Future<void> _runCountdownPulse(int secondsLeft) async {
    _send('stopFXRange $_activeFrom $_activeTo');
    _send('setBG 000 000 000 000 $_activeFrom $_activeTo');

    final colors = {
      5: '000 000 255 000', // blue
      4: '000 255 000 000', // green
      3: '000 255 255 000', // cyan
      2: '255 255 000 000', // yellow
      1: '255 000 000 000', // red
    };
    final color = colors[secondsLeft] ?? '255 000 000 000';

    await Future.delayed(const Duration(milliseconds: 50));
    _send('setBG $color $_activeFrom $_activeTo');
    await Future.delayed(const Duration(milliseconds: 800));
    _send('setBG 000 000 000 000 $_activeFrom $_activeTo');
  }

  void countdownGo() => _runCountdownGo();

  Future<void> _runCountdownGo() async {
    _send('stopFXRange $_activeFrom $_activeTo');
    _send('setBG 000 000 000 000 $_activeFrom $_activeTo');
    await Future.delayed(const Duration(milliseconds: 100));
    _send('setBG 255 255 255 000 $_activeFrom $_activeTo');
    await Future.delayed(const Duration(milliseconds: 300));
    _send('setBG 000 000 000 000 $_activeFrom $_activeTo');
    await Future.delayed(const Duration(milliseconds: 150));
    _send('setBG 255 255 255 000 $_activeFrom $_activeTo');
    await Future.delayed(const Duration(milliseconds: 300));
    _send('setBG 000 000 000 000 $_activeFrom $_activeTo');
    await Future.delayed(const Duration(milliseconds: 150));
    _send('setBG 255 255 255 000 $_activeFrom $_activeTo');
    await Future.delayed(const Duration(milliseconds: 300));
    _send('setBG 000 000 000 000 $_activeFrom $_activeTo');
    await Future.delayed(const Duration(milliseconds: 200));
    setBgIdle();
  }

  // ── Game start ──────────────────────────────────────────────────────────

  void gameStartEffect() {
    _cancelAllStrobes();
    _runGameStartEffect();
  }

  Future<void> _runGameStartEffect() async {
    if (_mode == GameMode.single) {
      _send('startRaceRange A $_singleFrom $_singleTo 01');
      await Future.delayed(const Duration(seconds: 2));
      _send('stopRaceRange A $_singleFrom $_singleTo');
      await Future.delayed(const Duration(milliseconds: 20));
      _send('stopRaceFXRange $_singleFrom $_singleTo');
      await Future.delayed(const Duration(milliseconds: 20));
      setBgIdle();
    } else {
      _send('startRaceRange A 000 081 01');
      await Future.delayed(const Duration(seconds: 2));
      _send('stopRaceRange A 000 081');
      await Future.delayed(const Duration(milliseconds: 20));
      _send('stopRaceFXRange 000 081');
      await Future.delayed(const Duration(milliseconds: 20));
      setBgIdle();
    }
  }

  // ── Victory ─────────────────────────────────────────────────────────────

  void victoryEffect() {
    _cancelAllStrobes();
    _runVictoryEffect();
  }

  Future<void> _runVictoryEffect() async {
    await Future.delayed(Duration(milliseconds: _strobeHoldMs + 200));
    _send('stopFXRange 000 081');
    await Future.delayed(const Duration(milliseconds: 20));
    _send('stopRaceFXRange 000 081');
    await Future.delayed(const Duration(milliseconds: 20));
    _send('allOff');
    await Future.delayed(const Duration(milliseconds: 200));
    _send('discoRange 08 0050 A 000 081');
  }

  // ── Stop all ────────────────────────────────────────────────────────────

  void stopAll() {
    _cancelAllStrobes();
    _send('stopRaceRange A 000 081');
    _send('stopRaceFXRange 000 081');
    _send('stopFXRange 000 081');
    _send('allOff');
  }

  void _cancelAllStrobes() {
    for (final t in _strobeTimers.values) {
      t.cancel();
    }
    _strobeTimers.clear();
  }

  void dispose() {
    _cancelAllStrobes();
    _socket?.close();
    _socket = null;
  }
}