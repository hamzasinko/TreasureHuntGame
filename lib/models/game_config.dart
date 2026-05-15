// lib/models/game_config.dart
import '../config/env.dart';

class GameConfig {
  // USB serial connection to XN-185
  // Windows: 'COM3', 'COM4', etc.  Linux/Mac: '/dev/ttyUSB0', '/dev/tty.usbserial-...'
  // Run RfidService.listPorts() at startup to print available ports to the console.
  static const String xn185SerialPort = Env.serialPort;  // change to your port
  static const int    xn185BaudRate   = Env.baudRate;  // check XN-185 manual (typically 115200 or 9600)

  // UDP LED controller
  static const String ledHost = Env.ledHost;
  static const int ledPort = Env.ledPort;

  // Total shells in game
  static const int totalShells = 8;

  // Reader 1 handles shells 1–4  (antenna port X002)
  // Reader 2 handles shells 5–8  (antenna port X007)
  static const String reader1Prefix = 'X002';
  static const String reader2Prefix = 'X007';

  // Init commands sent once on connect
  static const String initReader1 = 'X002S[10:3]';
  static const String initReader2 = 'X007S[10:3]';

  // Map label index (LB1..LB8) → shell number 1-8.
  // Reader 1 (X002): LB1=shell1 … LB4=shell4
  // Reader 2 (X007): LB1=shell5 … LB4=shell8
  static int shellNumberFromTagId(String tagId) {
    final match = RegExp(r'SHELL(\d+)', caseSensitive: false).firstMatch(tagId);
    if (match == null) return -1;
    return int.parse(match.group(1)!);
  }

  // LED lane positions per shell (0-based LED index start, length 10 each lane)
  // Adjust to match your physical setup
  static int ledStartForShell(int shell) => (shell - 1) * 10;
  static int ledEndForShell(int shell)   => ledStartForShell(shell) + 9;

  // Countdown duration in seconds before game starts
  static const int countdownSeconds = 3;

  // Game duration (seconds). Set to 0 for unlimited.
  static const int gameDurationSeconds = 0;
}
