// lib/models/game_config.dart
import '../config/env.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameMode { single, twoGroups}

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

  // ── LED ranges ────────────────────────────────────────────────────────

  // Single mode: all LEDs 34–81
  static const int singleLedStart = 34;
  static const int singleLedEnd   = 81;

  // Two-group mode:
  // Group A (shells 1-4) → LEDs 58–81 (24 LEDs, 6 per shell)
  // Group B (shells 5-8) → LEDs 0–57  (58 LEDs, ~14 per shell)
  static const int groupALedStart = 58;
  static const int groupALedEnd   = 81;
  static const int groupBLedStart = 0;
  static const int groupBLedEnd   = 57;

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
  static int ledStartForShell(int shell, GameMode mode) {
    if (mode == GameMode.single) {
      // 4 shells per antenna, 12 LEDs each within 34-81
      final offset = (shell - 1) * 6;
      return singleLedStart + offset;
    } else {
      if (shell <= 4) {
        // Group A: 58-81, 6 LEDs per shell
        return groupALedStart + (shell - 1) * 6;
      } else {
        // Group B: 0-57, 14 LEDs per shell (shells 5-8 → index 0-3)
        return groupBLedStart + (shell - 5) * 14;
      }
    }
  }

  static int ledEndForShell(int shell, GameMode mode) {
    if (mode == GameMode.single) {
      return ledStartForShell(shell, mode) + 6;
    } else {
      if (shell <= 4) {
        return ledStartForShell(shell, mode) + 6;
      } else {
        return shell == 8 ? ledStartForShell(shell, mode) + 15 : ledStartForShell(shell, mode) + 14;
      }
    }
  }

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
