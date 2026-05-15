// lib/screens/countdown_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_controller.dart';

class CountdownScreen extends StatelessWidget {
  const CountdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (_, gc, __) {
        return Scaffold(
          backgroundColor: const Color(0xFF020810),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'GET READY!',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22,
                    letterSpacing: 6,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 40),
                _CountdownNumber(value: gc.countdown),
                const SizedBox(height: 40),
                Text(
                  '🐚  FIND ALL THE SHELLS  🐚',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    letterSpacing: 3,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CountdownNumber extends StatefulWidget {
  final int value;
  const _CountdownNumber({required this.value});

  @override
  State<_CountdownNumber> createState() => _CountdownNumberState();
}

class _CountdownNumberState extends State<_CountdownNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  int _displayed = 0;

  @override
  void initState() {
    super.initState();
    _displayed = widget.value;
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scale = Tween<double>(begin: 1.6, end: 1.0).animate(
        CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void didUpdateWidget(covariant _CountdownNumber old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) {
      _displayed = widget.value;
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
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF40B0FF).withOpacity(0.6), width: 2),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF2080FF).withOpacity(0.4),
                    blurRadius: 40,
                    spreadRadius: 10),
              ],
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1040A0).withOpacity(0.4),
                  const Color(0xFF020810),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
                      _displayed == 0 ? 'GO!' : '$_displayed',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: _displayed == 0 ? 60 : 80,
                        fontWeight: FontWeight.w900,
                        color: _displayed == 0 ? const Color(0xFF00FF88) : const Color(0xFF80D0FF),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
