import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../models/game_config.dart';

enum TagEventType { detected, removed }

class TagEvent {
  final TagEventType type;
  final String readerPrefix;
  final int labelIndex;
  final String tagId;
  final int shellNumber;

  TagEvent({
    required this.type,
    required this.readerPrefix,
    required this.labelIndex,
    required this.tagId,
    required this.shellNumber,
  });

  @override
  String toString() =>
      'TagEvent(${type.name}, reader=$readerPrefix, label=$labelIndex, '
      'tag=$tagId, shell=$shellNumber)';
}

class RfidService {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _sub;

  final _controller = StreamController<TagEvent>.broadcast();
  String _buffer = '';

  Stream<TagEvent> get events => _controller.stream;

  static void listPorts() {
    final ports = SerialPort.availablePorts;
    debugPrint('[RFID] Available serial ports: $ports');
  }

  Future<void> connect() async {
    listPorts();
    try {
      _port = SerialPort(GameConfig.xn185SerialPort);

      if (!_port!.openReadWrite()) {
        debugPrint('[RFID] Failed to open ${GameConfig.xn185SerialPort}: '
            '${SerialPort.lastError}');
        return;
      }

      final config = SerialPortConfig()
        ..baudRate  = GameConfig.xn185BaudRate
        ..bits      = 8
        ..stopBits  = 1
        ..parity    = SerialPortParity.none
        ..setFlowControl(SerialPortFlowControl.none);
      _port!.config = config;

      debugPrint('[RFID] Opened ${GameConfig.xn185SerialPort} '
          '@ ${GameConfig.xn185BaudRate} baud');

      _reader = SerialPortReader(_port!);
      _sub = _reader!.stream.listen(
        _onData,
        onError: (e) => debugPrint('[RFID] Read error: $e'),
        cancelOnError: false,
      );

      await Future.delayed(const Duration(milliseconds: 500));
      _send(GameConfig.initReader1);
      await Future.delayed(const Duration(milliseconds: 500));
      _send(GameConfig.initReader2);
      await Future.delayed(const Duration(milliseconds: 500));
      _send(GameConfig.initReader1);
      await Future.delayed(const Duration(milliseconds: 500));
      _send(GameConfig.initReader2);
    } catch (e) {
      debugPrint('[RFID] Connect exception: $e');
    }
  }

  Future<void> reinit() async {
    debugPrint('[RFID] Reinitialising readers...');
    await Future.delayed(const Duration(milliseconds: 200));
    _send(GameConfig.initReader1);
    await Future.delayed(const Duration(milliseconds: 200));
    _send(GameConfig.initReader2);
  }

  void _send(String cmd) {
    if (_port == null || !_port!.isOpen) return;
    final bytes = Uint8List.fromList(ascii.encode('$cmd\r\n'));
    _port!.write(bytes);
    debugPrint('[RFID] Sent: $cmd');
  }

  void _onData(Uint8List data) {
    _buffer += ascii.decode(data, allowInvalid: true);
    while (true) {
      final end = _buffer.indexOf(']');
      if (end == -1) break;
      final msg = _buffer.substring(0, end + 1).trim();
      _buffer = _buffer.substring(end + 1);
      if (msg.isNotEmpty) _parseMessage(msg);
    }
  }

  static final _msgRegex = RegExp(
    r'(X\d{3})B\[(TD|TR)=LB(\d+):([^\]]+)\]',
  );

  void _parseMessage(String msg) {
    final match = _msgRegex.firstMatch(msg);
    if (match == null) {
      debugPrint('[RFID] Unrecognised (not in label mode?): $msg');
      _send(GameConfig.initReader1);
      _send(GameConfig.initReader2);
      return;
    }

    final readerPrefix = match.group(1)!;
    final typeStr      = match.group(2)!;
    final labelIndex   = int.parse(match.group(3)!);
    final tagId        = match.group(4)!;

    final eventType   = typeStr == 'TD' ? TagEventType.detected : TagEventType.removed;
    final shellNumber = GameConfig.shellNumberFromTagId(tagId);

    if (shellNumber < 1 || shellNumber > GameConfig.totalShells) return;

    final event = TagEvent(
      type: eventType,
      readerPrefix: readerPrefix,
      labelIndex: labelIndex,
      tagId: tagId,
      shellNumber: shellNumber,
    );
    debugPrint('[RFID] Parsed: $event');
    _controller.add(event);
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    _reader?.close();
    _port?.close();
    _port?.dispose();
    _port = null;
    _reader = null;
    debugPrint('[RFID] Disconnected');
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}