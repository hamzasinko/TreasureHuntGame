// lib/widgets/shell_card.dart

import 'package:flutter/material.dart';
import '../models/shell_model.dart';

class ShellCard extends StatefulWidget {
  final ShellModel shell;
  const ShellCard({super.key, required this.shell});

  @override
  State<ShellCard> createState() => _ShellCardState();
}

class _ShellCardState extends State<ShellCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _anim, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(covariant ShellCard old) {
    super.didUpdateWidget(old);
    if (widget.shell.state != old.shell.state &&
        widget.shell.state != ShellState.hidden) {
      _anim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _gradient(),
          boxShadow: [
            BoxShadow(
              color: _glowColor().withOpacity(0.6),
              blurRadius: widget.shell.isHidden ? 4 : 24,
              spreadRadius: widget.shell.isHidden ? 0 : 4,
            )
          ],
          border: Border.all(
            color: _glowColor().withOpacity(0.8),
            width: widget.shell.isHidden ? 1 : 2.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle water texture overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CustomPaint(
                painter: _WaterPatternPainter(
                    color: Colors.white.withOpacity(0.03)),
                child: const SizedBox.expand(),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _icon(),
                const SizedBox(height: 8),
                Text(
                  'SHELL ${widget.shell.number}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: _textColor(),
                  ),
                ),
                if (!widget.shell.isHidden) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.shell.isFound ? 'FOUND!' : 'WRONG\nANTENNA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: _textColor().withOpacity(0.85),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _gradient() {
    switch (widget.shell.state) {
      case ShellState.found:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003D1A), Color(0xFF00893C), Color(0xFF00C055)],
        );
      case ShellState.wrong:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D0000), Color(0xFF8B0000), Color(0xFFD32F2F)],
        );
      case ShellState.hidden:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF0D2045), Color(0xFF122060)],
        );
    }
  }

  Color _glowColor() {
    switch (widget.shell.state) {
      case ShellState.found:  return const Color(0xFF00FF66);
      case ShellState.wrong:  return const Color(0xFFFF3333);
      case ShellState.hidden: return const Color(0xFF1A4080);
    }
  }

  Color _textColor() {
    switch (widget.shell.state) {
      case ShellState.found:  return const Color(0xFF80FFB0);
      case ShellState.wrong:  return const Color(0xFFFFAAAA);
      case ShellState.hidden: return const Color(0xFF6090C0);
    }
  }

  Widget _icon() {
    switch (widget.shell.state) {
      case ShellState.found:
        return const Text('🐚', style: TextStyle(fontSize: 32));
      case ShellState.wrong:
        return const Text('❌', style: TextStyle(fontSize: 28));
      case ShellState.hidden:
        return Text('?',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF2A5090).withOpacity(0.7)));
    }
  }
}

class _WaterPatternPainter extends CustomPainter {
  final Color color;
  _WaterPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1..style = PaintingStyle.stroke;
    for (int i = 0; i < 6; i++) {
      final y = size.height * (i + 1) / 7;
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x += 10) {
        path.quadraticBezierTo(x + 5, y - 4, x + 10, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WaterPatternPainter old) => false;
}
