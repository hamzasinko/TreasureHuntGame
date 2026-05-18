import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
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
        vsync: this, duration: const Duration(milliseconds: 1000));
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _anim, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
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
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.asset(
              'assets/images/schatduiken-main.jpg',
              fit: BoxFit.cover,
            ),
            // Dark brown overlay
            Container(color: AppColors.deepBrown.withOpacity(0.78)),

            // Coin/particle effect
            const _CoinParticles(),

            // Main content
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 560,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 40),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1A0A).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.orange.withOpacity(0.8), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withOpacity(0.25),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Corner decorations
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Symbols.skull,
                                color: AppColors.orange.withOpacity(0.5),
                                size: 22),
                            Icon(Symbols.anchor,
                                color: AppColors.orange.withOpacity(0.5),
                                size: 22),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Trophy icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.orange.withOpacity(0.6),
                                width: 2),
                            color: AppColors.deepBrown,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.orange.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(Symbols.emoji_events,
                              color: AppColors.orange, size: 56),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'SCHAT GEVONDEN!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pirataOne(
                            fontSize: 38,
                            color: AppColors.orange,
                            shadows: [
                              Shadow(
                                color: AppColors.orange.withOpacity(0.5),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'ALL SHELLS DISCOVERED',
                          style: GoogleFonts.cinzel(
                            fontSize: 13,
                            letterSpacing: 5,
                            color: AppColors.sandDark,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Divider with anchors
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color:
                                        AppColors.orange.withOpacity(0.3))),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Symbols.anchor,
                                  color: AppColors.orange.withOpacity(0.5),
                                  size: 16),
                            ),
                            Expanded(
                                child: Divider(
                                    color:
                                        AppColors.orange.withOpacity(0.3))),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Shell row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            8,
                            (i) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text('🐚',
                                  style: TextStyle(
                                      fontSize: 24,
                                      shadows: [
                                        Shadow(
                                          color: AppColors.orange
                                              .withOpacity(0.6),
                                          blurRadius: 8,
                                        )
                                      ])),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Tap to continue
                        _PulsingText(text: 'TAP ANYWHERE TO CONTINUE'),

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Symbols.anchor,
                                color: AppColors.orange.withOpacity(0.5),
                                size: 22),
                            Icon(Symbols.skull,
                                color: AppColors.orange.withOpacity(0.5),
                                size: 22),
                          ],
                        ),
                      ],
                    ),
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
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.2, end: 1.0).animate(_anim);
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
      builder: (animCtx, animChild) => Opacity(
        opacity: _opacity.value,
        child: Text(
          widget.text,
          style: GoogleFonts.cinzel(
            fontSize: 12,
            letterSpacing: 4,
            color: AppColors.sandLight,
          ),
        ),
      ),
    );
  }
}

// ── Coin particles ─────────────────────────────────────────────────────────

class _CoinParticles extends StatefulWidget {
  const _CoinParticles();

  @override
  State<_CoinParticles> createState() => _CoinParticlesState();
}

class _CoinParticlesState extends State<_CoinParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
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
      builder: (confCtx, confChild) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _CoinPainter(_anim.value),
      ),
    );
  }
}

class _CoinPainter extends CustomPainter {
  final double t;
  _CoinPainter(this.t);

  static const _colors = [
    AppColors.orange,
    AppColors.sandLight,
    AppColors.warning,
    AppColors.sandDark,
    Color(0xFFFFD700),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 35; i++) {
      final seed  = i * 137.5;
      final x     = size.width  * ((seed * 0.618) % 1.0);
      final progress = (t + i / 35.0) % 1.0;
      final y     = size.height * (1.0 - progress);
      final col   = _colors[i % _colors.length].withOpacity(0.45);
      final paint = Paint()..color = col;
      final radius = 3.0 + (i % 4).toDouble();
      // Alternate between circles (coins) and small diamonds
      if (i % 3 == 0) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      } else {
        final path = Path()
          ..moveTo(x, y - radius)
          ..lineTo(x + radius * 0.6, y)
          ..lineTo(x, y + radius)
          ..lineTo(x - radius * 0.6, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CoinPainter old) => true;
}