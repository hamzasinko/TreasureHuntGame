// lib/screens/menu_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_controller.dart';
import '../config/app_colors.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'settings_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> 
  with SingleTickerProviderStateMixin {
  final _bgKey = GlobalKey<_FadingBackgroundState>();
  late AnimationController _screenFade;
  late Animation<double> _screenOpacity;

  @override
  void initState() {
  super.initState();
    _screenFade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
    _screenOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _screenFade, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _screenFade.dispose();
    super.dispose();
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF2A1A0A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.orange.withOpacity(0.8), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HOW TO PLAY',
                  style: _heading.copyWith(fontSize: 20, color: AppColors.orange)),
              const SizedBox(height: 24),
              _helpItem(Symbols.pool, 'Dive into the pool and find the hidden shells.'),
              _helpItem(Symbols.sensors, 'Bring each shell to the correct box A or B on the poolside.'),
              _helpItem(Symbols.check_circle, 'Green light and a sound = correct antenna and the point is scored!'),
              _helpItem(Symbols.cancel, 'Red light and a buzzer = wrong box try again...'),
              _helpItem(Symbols.emoji_events, 'Find all 8 shells to win the game!'),
              const SizedBox(height: 8),
              const Divider(color: AppColors.orange),
              const SizedBox(height: 12),
              Text(
                'Shells 1–4 belong to Antenna A (left side).\n'
                'Shells 5–8 belong to Antenna B (right side).',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.sandDark,
                    height: 1.6),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('GOT IT', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpItem(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: AppColors.orange, size: 22),
      const SizedBox(width: 14),
      Expanded(
        child: Text(text,
            style: const TextStyle(
                color: AppColors.sandLight, fontSize: 14, height: 1.5)),
      ),
    ]),
  );

  static const _heading = TextStyle(
    fontFamily: 'monospace',
    fontWeight: FontWeight.w800,
    letterSpacing: 3,
    color: Color(0xFF40B0FF),
  );

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _screenOpacity,
      child: Scaffold(
        backgroundColor: AppColors.deepBrown,
        body: Stack(
          children: [
            _FadingBackground(key: _bgKey),   // ← keyed

            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/schatduiken.png',
                      width: 960,
                      fit: BoxFit.contain,
                    ),
                    

                    const SizedBox(height: 24),

                    // START button — fades image out first
                    Consumer<GameController>(
                      builder: (ctx, gc, child) => _GlowButton(
                        label: 'START GAME',
                        color: AppColors.green,
                        onTap: () {
                          _screenFade.forward().then((_) => gc.startCountdown());
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _GlowButton(
                      label: 'SETTINGS',
                      color: AppColors.sandDark,
                      onTap: () => showDialog(
                        context: context,
                        builder: (dialogCtx) => const SettingsScreen(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // HELP button — unchanged
                    _GlowButton(
                      label: 'HOW TO PLAY',
                      color: AppColors.blue,
                      onTap: () => _showHelp(context),
                    ),
                    const SizedBox(height: 12),
                    _GlowButton(
                      label: 'EXIT',
                      color: AppColors.error,
                      onTap: () async {
                      if (defaultTargetPlatform == TargetPlatform.windows ||
                          defaultTargetPlatform == TargetPlatform.linux ||
                          defaultTargetPlatform == TargetPlatform.macOS) {
                          await windowManager.close();
                        } else {
                          SystemNavigator.pop();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
    );
  }
}

// ── Background image ───────────────────────────────────────────────────────
class _FadingBackground extends StatefulWidget {
  const _FadingBackground({super.key});
  @override
  State<_FadingBackground> createState() => _FadingBackgroundState();
}

class _FadingBackgroundState extends State<_FadingBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _anim, curve: Curves.easeIn));
    _anim.forward(); // fade in on load
  }

  void fadeOut(VoidCallback onDone) {
    _anim.reverse().then((_) => onDone());
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SizedBox.expand(
        child: Image.asset(
          'assets/images/schatduiken-main.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// ── Glowing button ─────────────────────────────────────────────────────────

class _GlowButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GlowButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _glow;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 6, end: 18).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (glowCtx, glowChild) => GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: 280,
            height: 64,
            decoration: BoxDecoration(
              // Brown parchment background
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6B3A1A), AppColors.deepBrown, Color(0xFF2A1A0A)],
              ),
              borderRadius: BorderRadius.circular(6),
              // Jagged pirate border effect via multiple shadows
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withOpacity(0.7),
                  blurRadius: _glow.value,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: AppColors.orange.withOpacity(0.2),
                  blurRadius: _glow.value * 2.5,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: AppColors.orange,
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Corner skull decorations
                Positioned(left: 10, child: Icon(Symbols.skull, color: AppColors.orange, size: 20)),
                Positioned(right: 10, child: Icon(Symbols.skull, color: AppColors.orange, size: 20)),
                // Worn texture overlay
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: CustomPaint(
                    painter: _ParchmentPainter(),
                    child: const SizedBox.expand(),
                  ),
                ),
                // Button label
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Color(0xFFD4A017),
                    shadows: [
                      Shadow(
                        color: Color(0xFFD4A017),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Adds subtle worn parchment lines to the button background
class _ParchmentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orange.withOpacity(0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final y = size.height * (i + 1) / 9;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + (i % 2 == 0 ? 1.5 : -1.5)), paint);
    }
    // Corner notches
    final notch = Paint()
      ..color = AppColors.orange.withOpacity(0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 8), const Offset(8, 0), notch);
    canvas.drawLine(Offset(size.width - 8, 0), Offset(size.width, 8), notch);
    canvas.drawLine(Offset(0, size.height - 8), Offset(8, size.height), notch);
    canvas.drawLine(Offset(size.width - 8, size.height), Offset(size.width, size.height - 8), notch);
  }

  @override
  bool shouldRepaint(_ParchmentPainter old) => false;
}