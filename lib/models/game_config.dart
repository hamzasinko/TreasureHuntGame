// lib/models/game_config.dart
import '../config/env.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameConfig {
  // USB serial connection to XN-185
  // Windows: 'COM3', 'COM4', etc.  Linux/Mac: '/dev/ttyUSB0', '/dev/tty.usbserial-...'
  // Run RfidService.listPorts() at startup to print available ports to the console.
  static String _serialPort    = Env.serialPort;
  static int    _baudRate      = Env.baudRate;

  // UDP LED controller
  static String _ledHost       = Env.ledHost;
  static int    _ledPort       = Env.ledPort;

  // Countdown duration in seconds before game starts
  static int    _countdownSecs = 3;

  // Game duration (seconds). Set to 0 for unlimited.
  static int    _gameDuration  = 0;

  // Reader 1 handles shells 1–4  (antenna port X002)
  // Reader 2 handles shells 5–8  (antenna port X007)
  static const String reader1Prefix = 'X002';
  static const String reader2Prefix = 'X007';

  // Init commands sent once on connect
  static const String initReader1 = 'X002S[10:3]';
  static const String initReader2 = 'X007S[10:3]';

  // Total shells in game
  static const int totalShells = 8;

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

  static Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _serialPort       = prefs.getString('serialPort')             ?? Env.serialPort;
    _baudRate         = prefs.getInt('baudRate')                  ?? Env.baudRate;
    _ledHost          = prefs.getString('ledHost')                ?? Env.ledHost;
    _ledPort          = prefs.getInt('ledPort')                   ?? Env.ledPort;
    _gameDuration     = prefs.getInt('gameDuration')              ?? 0;
    _countdownSecs    = prefs.getInt('countdownSeconds')          ?? 3;
  }

  static String get xn185SerialPort      => _serialPort;
  static int    get xn185BaudRate        => _baudRate;
  static String get ledHost              => _ledHost;
  static int    get ledPort              => _ledPort;
  static int    get gameDurationSeconds  => _gameDuration;
  static int    get countdownSeconds     => _countdownSecs;
}
