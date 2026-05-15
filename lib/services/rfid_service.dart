// lib/services/rfid_service.dart
//
// Connects to the XN-185 controller over USB serial (flutter_libserialport),
// sends the two init commands, then streams parsed tag events.
//
// Message format received from XN-185:
//   X002B[TD=LB1:SHELL1]   -> tag detected,  reader X002, label LB1, tag SHELL1
//   X002B[TR=LB1:SHELL1]   -> tag removed,   reader X002, label LB1, tag SHELL1

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../models/game_config.dart';

enum TagEventType { detected, removed }

class TagEvent {
  final TagEventType type;
  final String readerPrefix; // 'X002' or 'X007'
  final int labelIndex;      // 1-based (LB1 = 1)
  final String tagId;
  final int shellNumber;     // 1-8

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

  // Helper: print all available serial ports to the debug console.
  // Check here when first setting up to find the right port name.
  static void listPorts() {
    final ports = SerialPort.availablePorts;
    debugPrint('[RFID] Available serial ports: $ports');
  }

  // Connect and initialise the XN-185 over USB serial.
  Future<void> connect() async {
    listPorts();

    try {
      _port = SerialPort(GameConfig.xn185SerialPort);

      if (!_port!.openReadWrite()) {
        debugPrint('[RFID] Failed to open ${GameConfig.xn185SerialPort}: '
            '${SerialPort.lastError}');
        return;
      }

      // Configure to match XN-185 serial settings
      final config = SerialPortConfig()
        ..baudRate  = GameConfig.xn185BaudRate
        ..bits      = 8
        ..stopBits  = 1
        ..parity    = SerialPortParity.none
        ..setFlowControl(SerialPortFlowControl.none);
      _port!.config = config;

      debugPrint('[RFID] Opened ${GameConfig.xn185SerialPort} '
          '@ ${GameConfig.xn185BaudRate} baud');

      // Start listening to the incoming stream
      _reader = SerialPortReader(_port!);
      _sub = _reader!.stream.listen(
        _onData,
        onError: (e) => debugPrint('[RFID] Read error: $e'),
        cancelOnError: false,
      );

      // Wait briefly then send the two init commands so XN-185 switches
      // to label-reading mode on both reader ports.
      await Future.delayed(const Duration(milliseconds: 300));
      _send(GameConfig.initReader1); // X002S[10:3]
      await Future.delayed(const Duration(milliseconds: 100));
      _send(GameConfig.initReader2); // X007S[10:3]
    } catch (e) {
      debugPrint('[RFID] Connect exception: $e');
    }
  }

  // Write a command string to the serial port (appends CR+LF).
  void _send(String cmd) {
    if (_port == null || !_port!.isOpen) return;
    final bytes = Uint8List.fromList(ascii.encode('$cmd\r\n'));
    _port!.write(bytes);
    debugPrint('[RFID] Sent: $cmd');
  }

  // Accumulate incoming bytes into a string buffer and parse complete messages.
  void _onData(Uint8List data) {
    _buffer += ascii.decode(data, allowInvalid: true);
    // Each XN-185 message ends with ']'
    while (true) {
      final end = _buffer.indexOf(']');
      if (end == -1) break;
      final msg = _buffer.substring(0, end + 1).trim();
      _buffer = _buffer.substring(end + 1);
      if (msg.isNotEmpty) _parseMessage(msg);
    }
  }

  // Parses: X002B[TD=LB1:SHELL1]
  static final _msgRegex = RegExp(
    r'(X\d{3})B\[(TD|TR)=LB(\d+):([^\]]+)\]',
  );

  void _parseMessage(String msg) {
    final match = _msgRegex.firstMatch(msg);
    if (match == null) {
      debugPrint('[RFID] Unrecognised: $msg');
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
