// lib/screens/countdown_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_controller.dart';
import '../config/app_colors.dart';

class CountdownScreen extends StatelessWidget {
  const CountdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (_, gc, __) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.asset(
                'assets/images/beach.jpg',
                fit: BoxFit.cover,
              ),
              // Dark overlay so the countdown numbers are readable
              Container(
                color: AppColors.deepBrown.withOpacity(0.65),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'GET READY!',
                        style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 42,
                        letterSpacing: 6,
                        color: AppColors.orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 60),
                    _CountdownNumber(value: gc.countdown),
                    const SizedBox(height: 60),
                    Text(
                      '   FIND ALL THE SHELLS   ',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 24,
                        letterSpacing: 3,
                        color: AppColors.sandLight.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ]
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
              border: Border.all(color: AppColors.orange.withOpacity(0.7), width: 2),
              boxShadow: [
                BoxShadow(
                    color: AppColors.orange.withOpacity(0.35),
                    blurRadius: 40,
                    spreadRadius: 10),
              ],
              gradient: RadialGradient(
                colors: [
                AppColors.deepBrown.withOpacity(0.8),
                Colors.black.withOpacity(0.6),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
                      _displayed <= 0 ? 'GO!' : '$_displayed',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: _displayed == 0 ? 60 : 80,
                        fontWeight: FontWeight.w900,
                        color: _displayed == 0 ? AppColors.orange : AppColors.orange,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
