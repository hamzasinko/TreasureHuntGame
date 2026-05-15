// lib/screens/menu_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_controller.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF050E1F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF1A5090), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('🐚', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Text('HOW TO PLAY',
                    style: _heading.copyWith(fontSize: 20, color: Colors.white)),
              ]),
              const SizedBox(height: 24),
              _helpItem('🏊', 'Dive into the pool and find the hidden shells.'),
              _helpItem('🎯', 'Bring each shell to the correct RFID antenna on the poolside.'),
              _helpItem('✅', 'Green light and a sound = correct antenna — point scored!'),
              _helpItem('❌', 'Red light and a buzzer = wrong antenna — try again.'),
              _helpItem('🏆', 'Find all 8 shells to win the game!'),
              const SizedBox(height: 8),
              const Divider(color: Color(0xFF1A3060)),
              const SizedBox(height: 12),
              Text(
                'Shells 1–4 belong to Antenna A (left side).\n'
                'Shells 5–8 belong to Antenna B (right side).',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.55),
                    height: 1.6),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF40B0FF),
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

  Widget _helpItem(String emoji, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 14),
      Expanded(
        child: Text(text,
            style: const TextStyle(
                color: Color(0xFFB0CCE8), fontSize: 14, height: 1.5)),
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
    return Scaffold(
      backgroundColor: const Color(0xFF030912),
      body: Stack(
        children: [
          // Animated background
          const _PoolBackground(),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / title
                const Text('🐚', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 16),
                Text(
                  'SHELL\nHUNT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    height: 1.0,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFF40C8FF), Color(0xFF0060D0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(const Rect.fromLTWH(0, 0, 300, 120)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'RFID POOL EDITION',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    letterSpacing: 5,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 60),

                // START button
                Consumer<GameController>(
                  builder: (_, gc, __) => _GlowButton(
                    label: 'START GAME',
                    color: const Color(0xFF00C055),
                    onTap: gc.startCountdown,
                  ),
                ),
                const SizedBox(height: 20),

                // HELP button
                _GlowButton(
                  label: 'HOW TO PLAY',
                  color: const Color(0xFF1A70C0),
                  onTap: () => _showHelp(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pool animated background ───────────────────────────────────────────────

class _PoolBackground extends StatefulWidget {
  const _PoolBackground();
  @override
  State<_PoolBackground> createState() => _PoolBackgroundState();
}

class _PoolBackgroundState extends State<_PoolBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _PoolPainter(_anim.value),
      ),
    );
  }
}

class _PoolPainter extends CustomPainter {
  final double t;
  _PoolPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Deep-water gradient
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF020810), Color(0xFF041530), Color(0xFF062050)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, bg);

    // Caustic light ripples
    final paint = Paint()
      ..color = const Color(0xFF0A4090).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 8; i++) {
      final cx = size.width * (0.1 + i * 0.12 + 0.04 * _sin(t * 2 + i));
      final cy = size.height * (0.15 + 0.12 * _sin(t * 1.3 + i * 1.1));
      final r  = size.width * (0.06 + 0.03 * _sin(t * 1.7 + i * 0.9));
      canvas.drawCircle(Offset(cx, cy), r, paint);
      canvas.drawCircle(Offset(cx, cy), r * 0.6, paint);
    }
  }

  double _sin(double x) => (x % (2 * 3.14159)).abs() < 3.14159
      ? x.abs() / 3.14159 * 2 - 1
      : 1 - x.abs() / 3.14159 * 2 + 1; // rough sine approx

  @override
  bool shouldRepaint(_PoolPainter old) => true;
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

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 8, end: 22).animate(
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
      builder: (_, child) => GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 260,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.color.withOpacity(0.15),
            border: Border.all(color: widget.color.withOpacity(0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: widget.color.withOpacity(0.4),
                  blurRadius: _glow.value,
                  spreadRadius: 0),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
