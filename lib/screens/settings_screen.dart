import 'dart:typed_data';
import 'package:app_treasuregame/config/env.dart';
import 'package:app_treasuregame/screens/exit_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../config/app_colors.dart';
import '../services/audio_service.dart';

const String _settingsPin = '5055';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: _unlocked
          ? _SettingsForm(onClose: () => Navigator.of(context).pop())
          : _PinGate(onUnlocked: () => setState(() => _unlocked = true)),
    );
  }
}

class _PinGate extends StatefulWidget {
  final VoidCallback onUnlocked;
  const _PinGate({required this.onUnlocked});

  @override
  State<_PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<_PinGate>
    with SingleTickerProviderStateMixin {
  String _entered = '';
  bool _wrong = false;
  late AnimationController _shake;
  late Animation<double> _shakeAnim;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _shake, curve: Curves.elasticOut));
    // Auto-focus so keyboard events work immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _shake.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onKey(String digit) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += digit;
      _wrong = false;
    });
    if (_entered.length == 4) {
      Future.delayed(const Duration(milliseconds: 100), _check);
    }
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _check() {
    if (_entered == _settingsPin) {
      widget.onUnlocked();
    } else {
      setState(() {
        _wrong = true;
        _entered = '';
      });
      _shake.forward(from: 0);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    // Digits 0-9 via number row or numpad
    final digitKeys = {
      LogicalKeyboardKey.digit0: '0',
      LogicalKeyboardKey.digit1: '1',
      LogicalKeyboardKey.digit2: '2',
      LogicalKeyboardKey.digit3: '3',
      LogicalKeyboardKey.digit4: '4',
      LogicalKeyboardKey.digit5: '5',
      LogicalKeyboardKey.digit6: '6',
      LogicalKeyboardKey.digit7: '7',
      LogicalKeyboardKey.digit8: '8',
      LogicalKeyboardKey.digit9: '9',
      LogicalKeyboardKey.numpad0: '0',
      LogicalKeyboardKey.numpad1: '1',
      LogicalKeyboardKey.numpad2: '2',
      LogicalKeyboardKey.numpad3: '3',
      LogicalKeyboardKey.numpad4: '4',
      LogicalKeyboardKey.numpad5: '5',
      LogicalKeyboardKey.numpad6: '6',
      LogicalKeyboardKey.numpad7: '7',
      LogicalKeyboardKey.numpad8: '8',
      LogicalKeyboardKey.numpad9: '9',
    };

    if (digitKeys.containsKey(key)) {
      _onKey(digitKeys[key]!);
    } else if (key == LogicalKeyboardKey.backspace ||
               key == LogicalKeyboardKey.delete ||
               key == LogicalKeyboardKey.numpadDecimal) {
      _onDelete();
    } else if (key == LogicalKeyboardKey.enter ||
               key == LogicalKeyboardKey.numpadEnter) {
      if (_entered.length == 4) _check();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1A0A),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.orange.withOpacity(0.8), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withOpacity(0.2),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(Symbols.lock, color: AppColors.orange, size: 22),
              const SizedBox(width: 10),
              Text('ENTER PIN',
                  style: GoogleFonts.pirataOne(
                      fontSize: 22,
                      color: AppColors.orange,
                      letterSpacing: 3)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child:
                    Icon(Symbols.close, color: AppColors.sandDark, size: 20),
              ),
            ]),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (animCtx, animChild) => Transform.translate(
                offset: Offset(
                    _wrong
                        ? 8 * (0.5 - _shakeAnim.value).abs() * 4
                        : 0,
                    0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < _entered.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _wrong
                            ? AppColors.error
                            : filled
                                ? AppColors.orange
                                : Colors.transparent,
                        border: Border.all(
                          color: _wrong
                              ? AppColors.error
                              : AppColors.orange.withOpacity(0.6),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            if (_wrong) ...[
              const SizedBox(height: 10),
              Text('INCORRECT PIN',
                  style: GoogleFonts.cinzel(
                      fontSize: 11,
                      color: AppColors.error,
                      letterSpacing: 2)),
            ],
            const SizedBox(height: 28),
            ...[
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
            ].map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: row
                        .map((d) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child:
                                  _PinKey(digit: d, onTap: () => _onKey(d)),
                            ))
                        .toList(),
                  ),
                )),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 72),
                const SizedBox(width: 16),
                _PinKey(digit: '0', onTap: () => _onKey('0')),
                const SizedBox(width: 16),
                _DeleteKey(onTap: _onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PinKey extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;
  const _PinKey({required this.digit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.deepBrown,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: AppColors.orange.withOpacity(0.4), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(digit,
            style: GoogleFonts.pirataOne(
                fontSize: 24, color: AppColors.sandLight)),
      ),
    );
  }
}

class _DeleteKey extends StatelessWidget {
  final VoidCallback onTap;
  const _DeleteKey({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.deepBrown,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: AppColors.orange.withOpacity(0.4), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Icon(Symbols.backspace, color: AppColors.sandDark, size: 22),
      ),
    );
  }
}

// ── Settings form ──────────────────────────────────────────────────────────

class _SettingsForm extends StatefulWidget {
  final VoidCallback onClose;
  const _SettingsForm({required this.onClose});

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  final audioPlayer = AudioService();

  String _selectedPort = Env.serialPort;
  List<String> _availablePorts = [];

  late TextEditingController _baudRate;
  late TextEditingController _ledHost;
  late TextEditingController _ledPort;
  late TextEditingController _gameDuration;
  late TextEditingController _countdownSeconds;

  // SOUND SETTINGS
  double _generalVolume = 1.0;
  bool _soundApplied = false;


  bool _loading = true;
  bool _saved = false;
  bool _detecting = false;
  String _detectStatus = '';

  @override
  void initState() {
    super.initState();
    _baudRate         = TextEditingController();
    _ledHost          = TextEditingController();
    _ledPort          = TextEditingController();
    _gameDuration     = TextEditingController();
    _countdownSeconds = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Call availablePorts BEFORE any await
    final sysPorts = List<String>.from(SerialPort.availablePorts);

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('serialPort') ?? Env.serialPort;

    if (saved.isNotEmpty && !sysPorts.contains(saved)) {
      sysPorts.insert(0, saved);
    }

    setState(() {
      _selectedPort          = saved;
      _availablePorts        = sysPorts;
      _baudRate.text         = prefs.getInt('baudRate')?.toString()         ?? Env.baudRate.toString();
      _ledHost.text          = prefs.getString('ledHost')                   ?? Env.ledHost;
      _ledPort.text          = prefs.getInt('ledPort')?.toString()          ?? Env.ledPort.toString();
      _gameDuration.text     = prefs.getInt('gameDuration')?.toString()     ?? '0';
      _countdownSeconds.text = prefs.getInt('countdownSeconds')?.toString() ?? '3';
      _loading               = false;
      _generalVolume = prefs.getDouble('generalVolume') ?? 1.0;
    });
  }

  void _refreshPorts() {
    final sysPorts = List<String>.from(SerialPort.availablePorts);
    if (mounted) setState(() => _availablePorts = sysPorts);
  }

  Future<void> _detectPort() async {
    setState(() {
      _detecting = true;
      _detectStatus = 'Scanning ports...';
    });

    //final sysPorts = List<String>.from(SerialPort.availablePorts);

    _refreshPorts();

    if (_availablePorts.isEmpty) {
      setState(() {
        _detecting = false;
        _detectStatus = 'No serial ports found.';
      });
      return;
    }

    
    setState(() => _detectStatus = 'Trying $_selectedPort...');

    try {
      final port = SerialPort(_selectedPort);
      if (!port.openReadWrite()) {
        port.dispose();
        return;
      }

      final config = SerialPortConfig()
        ..baudRate = int.tryParse(_baudRate.text.trim()) ?? 115200
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none
        ..setFlowControl(SerialPortFlowControl.none);
      port.config = config;

      final reader = SerialPortReader(port);
      bool found = false;

      final sub = reader.stream.listen((data) {
        final msg = String.fromCharCodes(data);

        // XN185 tag events
        if (msg.contains('[TD=') || msg.contains('[TR=')) {
          found = true;
        }
      });

      // Tell user to scan a tag
      setState(() => _detectStatus = 'Port $_selectedPort opened — scan a tag...');

      // Send init commands BEFORE waiting
      port.write(Uint8List.fromList('X002S[10:3]\r\n'.codeUnits));
      await Future.delayed(const Duration(milliseconds: 200));

      port.write(Uint8List.fromList('X007S[10:3]\r\n'.codeUnits));
      await Future.delayed(const Duration(milliseconds: 200));

      // Wait up to 5 seconds for a scan
      const timeout = Duration(seconds: 5);
      final start = DateTime.now();

      while (!found && DateTime.now().difference(start) < timeout) {
        await Future.delayed(const Duration(milliseconds: 100));
      } 

      await sub.cancel();
      reader.close();
      port.close();
      port.dispose();

      if (found) {
        setState(() {
          _selectedPort = _selectedPort;
          _detecting = false;
          _detectStatus = 'XN-185 detected on $_selectedPort';
        });
        return;
      } else {
        setState(() => _detectStatus = 'No tag detected on $_selectedPort...');
      }

    } catch (e) {
      debugPrint('[Settings] Error on $_selectedPort: $e');
    }

    setState(() {
      _detecting = false;
      _detectStatus = 'Not detected. Try scanning a tag or select manually.';
    });
  }


  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('serialPort', _selectedPort);
    await prefs.setInt('baudRate', int.parse(_baudRate.text.trim()));
    await prefs.setString('ledHost', _ledHost.text.trim());
    await prefs.setInt('ledPort', int.parse(_ledPort.text.trim()));
    await prefs.setInt('gameDuration', int.parse(_gameDuration.text.trim()));
    await prefs.setInt('countdownSeconds', int.parse(_countdownSeconds.text.trim()));

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ExitSplashScreen()),
    );
  }

  @override
  void dispose() {
    _baudRate.dispose();
    _ledHost.dispose();
    _ledPort.dispose();
    _gameDuration.dispose();
    _countdownSeconds.dispose();
    super.dispose();
  }

  // Shared label height so dropdown and TextFormField top-align
  static const double _labelHeight = 20;
  static const double _fieldHeight = 56;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 520,
      decoration: BoxDecoration(
        color: const Color(0xFF2A1A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withOpacity(0.8), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withOpacity(0.2),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
        mainAxisSize: MainAxisSize.min,
          children: [

            // ── Header ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.deepBrown.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                border: Border(
                    bottom:
                        BorderSide(color: AppColors.orange.withOpacity(0.4))),
              ),
              child: Row(children: [
                Icon(Symbols.settings, color: AppColors.orange, size: 22),
                const SizedBox(width: 12),
                Text('SETTINGS',
                    style: GoogleFonts.pirataOne(
                        fontSize: 22,
                        color: AppColors.orange,
                        letterSpacing: 3)),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onClose,
                  child:
                      Icon(Symbols.close, color: AppColors.sandDark, size: 20),
                ),
              ]),
            ),

            Container(
              decoration: BoxDecoration(
                color: AppColors.deepBrown.withOpacity(0.8),
                border: Border(
                  bottom: BorderSide(color: AppColors.orange.withOpacity(0.4)),
                ),
              ),
              child: TabBar(
                indicatorColor: AppColors.orange,
                labelColor: AppColors.orange,
                unselectedLabelColor: AppColors.sandDark,
                tabs: [
                  Tab(child: Text("GENERAL", style: GoogleFonts.cinzel(letterSpacing: 2))),
                  Tab(child: Text("SOUND", style: GoogleFonts.cinzel(letterSpacing: 2))),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  // TAB 1 — GENERAL
                  _buildGeneralTab(),

                  // TAB 2 — SOUND
                  _buildSoundTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab() {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── LOADING ─────────────────────────────────────────────
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )

            // ── GENERAL SETTINGS ─────────────────────────────────────
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── RFID ────────────────────────────────────────────
                  _sectionLabel('RFID CONTROLLER'),
                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Serial Port Dropdown
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: _labelHeight,
                              child: Row(
                                children: [
                                  Text(
                                    'Serial Port',
                                    style: GoogleFonts.cinzel(
                                      fontSize: 11,
                                      color: AppColors.sandDark,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: _refreshPorts,
                                    child: Icon(
                                      Symbols.refresh,
                                      color: AppColors.orange.withOpacity(0.6),
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            Container(
                              height: _fieldHeight,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.deepBrown.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.orange.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _availablePorts.contains(_selectedPort)
                                      ? _selectedPort
                                      : null,
                                  hint: Text(
                                    _selectedPort.isNotEmpty
                                        ? _selectedPort
                                        : 'Select port',
                                    style: GoogleFonts.cinzel(
                                      fontSize: 13,
                                      color: AppColors.sandLight,
                                    ),
                                  ),
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF2A1A0A),
                                  icon: Icon(
                                    Symbols.expand_more,
                                    color: AppColors.orange,
                                    size: 18,
                                  ),
                                  items: _availablePorts
                                      .map(
                                        (p) => DropdownMenuItem(
                                          value: p,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Symbols.usb,
                                                color: AppColors.orange.withOpacity(0.7),
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                p,
                                                style: GoogleFonts.cinzel(
                                                  fontSize: 13,
                                                  color: AppColors.sandLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedPort = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Baud Rate
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 28),
                            _field(
                              controller: _baudRate,
                              label: 'Baud Rate',
                              hint: '115200',
                              icon: Symbols.speed,
                              numbersOnly: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Auto Detect Button
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _detecting ? null : _detectPort,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.deepBrown,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _detecting
                                  ? AppColors.sandDark
                                  : AppColors.blue.withOpacity(0.8),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _detecting
                                  ? SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.blue,
                                      ),
                                    )
                                  : Icon(
                                      Symbols.search,
                                      color: AppColors.blue,
                                      size: 16,
                                    ),
                              const SizedBox(width: 8),
                              Text(
                                _detecting ? 'DETECTING...' : 'AUTO-DETECT PORT',
                                style: GoogleFonts.cinzel(
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  color: _detecting
                                      ? AppColors.sandDark
                                      : AppColors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      if (_detectStatus.isNotEmpty)
                        Expanded(
                          child: Text(
                            _detectStatus,
                            style: GoogleFonts.cinzel(
                              fontSize: 10,
                              color: _detectStatus.contains('Found')
                                  ? AppColors.success
                                  : _detectStatus.contains('Not detected')
                                      ? AppColors.error
                                      : AppColors.sandDark,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // ── LED ──────────────────────────────────────────────
                  const SizedBox(height: 20),
                  _sectionLabel('LED CONTROLLER'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _field(
                          controller: _ledHost,
                          label: 'IP Address',
                          hint: '192.168.100.111',
                          icon: Symbols.wifi,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: _ledPort,
                          label: 'UDP Port',
                          hint: '7000',
                          icon: Symbols.lan,
                          numbersOnly: true,
                        ),
                      ),
                    ],
                  ),

                  // ── GAME ─────────────────────────────────────────────
                  const SizedBox(height: 20),
                  _sectionLabel('GAME'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: _gameDuration,
                          label: 'Game Duration (sec)',
                          hint: '0',
                          icon: Symbols.timer,
                          numbersOnly: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: _countdownSeconds,
                          label: 'Countdown (sec)',
                          hint: '3',
                          icon: Symbols.hourglass,
                          numbersOnly: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: GestureDetector(
                      onTap: _save,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: _saved
                              ? AppColors.success.withOpacity(0.2)
                              : AppColors.deepBrown,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _saved
                                ? AppColors.success
                                : AppColors.orange,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _saved ? Symbols.check_circle : Symbols.save,
                              color: _saved
                                  ? AppColors.success
                                  : AppColors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _saved ? 'SAVED!' : 'SAVE SETTINGS',
                              style: GoogleFonts.cinzel(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                                color: _saved
                                    ? AppColors.success
                                    : AppColors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Text(
                    'Changes take effect on next app restart.',
                    style: GoogleFonts.cinzel(
                      fontSize: 10,
                      color: AppColors.sandDark.withOpacity(0.6),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSoundTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel("GENERAL SOUND"),
          const SizedBox(height: 20),

          // Volume slider
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.deepBrown.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.orange.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(Symbols.volume_down, color: AppColors.sandLight, size: 18),
                  Expanded(
                    child: Slider(
                      value: _generalVolume,
                      min: 0,
                      max: 1,
                      divisions: 10,
                      activeColor: AppColors.orange,
                      inactiveColor: AppColors.sandDark.withOpacity(0.4),
                      onChanged: (v) async {
                        setState(() => _generalVolume = v);

                        // Play test sound
                        await _playTestSound(v);
                      },
                    ),
                  ),
                  Icon(Symbols.volume_up, color: AppColors.sandLight, size: 18),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Apply button
            GestureDetector(
              onTap: _applySoundSettings,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.deepBrown,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.orange.withOpacity(0.8),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.check, color: AppColors.orange, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "APPLY",
                      style: GoogleFonts.cinzel(
                        fontSize: 12,
                        letterSpacing: 2,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_soundApplied) ...[
              const SizedBox(height: 10),
              Text(
                "Sound settings applied!",
                style: GoogleFonts.cinzel(
                  fontSize: 11,
                  color: AppColors.success,
                  letterSpacing: 1,
                ),
              ),
            ],
        ],
      ),
    );
  }

  Future<void> _applySoundSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('generalVolume', _generalVolume);

    audioPlayer.setSfxVolume(_generalVolume);
    audioPlayer.setMusicVolume(_generalVolume);

    setState(() => _soundApplied = true);
  }

  Future<void> _playTestSound(double volume) async {
    audioPlayer.playTestSound(volume);
  }

  Widget _sectionLabel(String text) => Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(text,
              style: GoogleFonts.cinzel(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: AppColors.orange)),
        ],
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool numbersOnly = false,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType:
            numbersOnly ? TextInputType.number : TextInputType.text,
        inputFormatters: numbersOnly
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        style:
            GoogleFonts.cinzel(fontSize: 13, color: AppColors.sandLight),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon,
              color: AppColors.orange.withOpacity(0.7), size: 18),
          labelStyle: GoogleFonts.cinzel(
              fontSize: 11, color: AppColors.sandDark, letterSpacing: 1),
          hintStyle: GoogleFonts.cinzel(
              fontSize: 11,
              color: AppColors.sandDark.withOpacity(0.4)),
          filled: true,
          fillColor: AppColors.deepBrown.withOpacity(0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                BorderSide(color: AppColors.orange.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                BorderSide(color: AppColors.orange.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: AppColors.orange, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: AppColors.error),
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      );
}