// lib/screens/victory_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/game_controller.dart';

class VictoryScreen extends StatefulWidget {
  const VictoryScreen({super.key});

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _anim, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();

    // Listen for any key / tap to go back to menu
    ServicesBinding.instance.keyboard.addHandler(_onKey);
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      _goBack();
      return true;
    }
    return false;
  }

  void _goBack() {
    ServicesBinding.instance.keyboard.removeHandler(_onKey);
    context.read<GameController>().returnToMenu();
  }

  @override
  void dispose() {
    ServicesBinding.instance.keyboard.removeHandler(_onKey);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _goBack,
      child: Scaffold(
        backgroundColor: const Color(0xFF020810),
        body: Stack(
          children: [
            // Particle / confetti overlay
            const _ConfettiBackground(),

            Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 80)),
                      const SizedBox(height: 24),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: const Text(
                          'CONGRATULATIONS!',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ALL SHELLS FOUND',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          letterSpacing: 5,
                          color: Colors.white.withOpacity(0.55),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🐚', style: TextStyle(fontSize: 28)),
                          SizedBox(width: 8),
                          Text('🐚', style: TextStyle(fontSize: 28)),
                          SizedBox(width: 8),
                          Text('🐚', style: TextStyle(fontSize: 28)),
                          SizedBox(width: 8),
                          Text('🐚', style: TextStyle(fontSize: 28)),
                          SizedBox(width: 8),
                          Text('🐚', style: TextStyle(fontSize: 28)),
                          SizedBox(width: 8),
                          Text('🐚', style: TextStyle(fontSize: 28)),
                          SizedBox(width: 8),
                          Text('🐚', style: TextStyle(fontSize: 28)),
                          SizedBox(width: 8),
                          Text('🐚', style: TextStyle(fontSize: 28)),
                        ],
                      ),
                      const SizedBox(height: 48),
                      _PulsingText(
                        text: 'TAP ANYWHERE TO CONTINUE',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pulsing hint text ──────────────────────────────────────────────────────

class _PulsingText extends StatefulWidget {
  final String text;
  const _PulsingText({required this.text});

  @override
  State<_PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<_PulsingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.2, end: 0.8).animate(_anim);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Text(
          widget.text,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            letterSpacing: 4,
            color: Color(0xFF60A0D0),
          ),
        ),
      ),
    );
  }
}

// ── Confetti / bubbles background ─────────────────────────────────────────

class _ConfettiBackground extends StatefulWidget {
  const _ConfettiBackground();

  @override
  State<_ConfettiBackground> createState() => _ConfettiBackgroundState();
}

class _ConfettiBackgroundState extends State<_ConfettiBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
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
        painter: _ConfettiPainter(_anim.value),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);

  static const _colors = [
    Color(0xFFFFD700), Color(0xFF00C055), Color(0xFF40B0FF),
    Color(0xFFFF6600), Color(0xFFFF40A0), Color(0xFFAA60FF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 40; i++) {
      final seed = i * 137.5;
      final x = size.width  * ((seed * 0.618) % 1.0);
      final progress = (t + i / 40.0) % 1.0;
      final y = size.height * (1.0 - progress);
      final col = _colors[i % _colors.length].withOpacity(0.5);
      final paint = Paint()..color = col;
      canvas.drawCircle(Offset(x, y), 4 + (i % 4).toDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
