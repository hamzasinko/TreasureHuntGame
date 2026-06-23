import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../models/game_config.dart';
import '../services/game_controller.dart';

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/schatduiken-main.jpg', fit: BoxFit.cover),
          Container(color: AppColors.deepBrown.withOpacity(0.78)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title image
                Image.asset(
                  'assets/images/schatduiken.png',
                  width: 480,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                Text(
                  'SELECT MODE',
                  style: GoogleFonts.pirataOne(
                    fontSize: 28,
                    color: AppColors.orange,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 40),

                // Mode cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ModeCard(
                      icon: Symbols.group,
                      title: 'SINGLE GROUP',
                      subtitle: 'All 8 shells\nOne team',
                      onTap: () => context
                          .read<GameController>()
                          .selectMode(GameMode.single),
                    ),
                    const SizedBox(width: 32),
                    _ModeCard(
                      icon: Symbols.groups,
                      title: 'TWO GROUPS',
                      subtitle: 'Group A: shells 1–4\nGroup B: shells 5–8',
                      onTap: () => context
                          .read<GameController>()
                          .selectMode(GameMode.twoGroups),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Back button
                TextButton.icon(
                  onPressed: () =>
                      context.read<GameController>().returnToMenu(),
                  icon: Icon(Symbols.arrow_back,
                      color: AppColors.sandDark, size: 18),
                  label: Text(
                    'BACK',
                    style: GoogleFonts.cinzel(
                      fontSize: 13,
                      letterSpacing: 3,
                      color: AppColors.sandDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard>
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
    _glow = Tween<double>(begin: 6, end: 20).animate(
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
      builder: (animCtx, animChild) => GestureDetector(
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
            width: 220,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6B3A1A),
                  AppColors.deepBrown,
                  Color(0xFF2A1A0A),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.orange, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withOpacity(0.4),
                  blurRadius: _glow.value,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Symbols.skull,
                        color: AppColors.orange.withOpacity(0.5), size: 16),
                    Icon(Symbols.anchor,
                        color: AppColors.orange.withOpacity(0.5), size: 16),
                  ],
                ),
                const SizedBox(height: 16),
                Icon(widget.icon, color: AppColors.orange, size: 48),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.pirataOne(
                    fontSize: 18,
                    color: AppColors.orange,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    fontSize: 11,
                    color: AppColors.sandDark,
                    letterSpacing: 1,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Symbols.anchor,
                        color: AppColors.orange.withOpacity(0.5), size: 16),
                    Icon(Symbols.skull,
                        color: AppColors.orange.withOpacity(0.5), size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}