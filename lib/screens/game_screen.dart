import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../models/game_config.dart';
import '../models/shell_model.dart';
import '../services/game_controller.dart';
import '../widgets/shell_card.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (ctx, gc, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.asset(
                'assets/images/schatduiken-main.jpg',
                fit: BoxFit.cover,
              ),
              // Dark overlay
              Container(color: AppColors.deepBrown.withOpacity(0.75)),
              // Content
              SafeArea(
                child: Column(
                  children: [
                    _Header(gc: gc),
                    const SizedBox(height: 8),
                    Expanded(child: _AntennaRow(shells: gc.shells)),
                    const SizedBox(height: 8),
                    _Footer(gc: gc),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final GameController gc;
  const _Header({required this.gc});

  String _formatTime(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final found = gc.shells.where((s) => s.isFound).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.deepBrown.withOpacity(0.85),
        border: Border(
          bottom: BorderSide(color: AppColors.orange.withOpacity(0.4), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          _StatBox(
            icon: Symbols.emoji_events,
            label: 'SCORE',
            value: '$found / ${GameConfig.totalShells}',
            color: AppColors.success,
          ),
          const Spacer(),
          // Title image
          Image.asset(
            'assets/images/schatduiken.png',
            height: 40,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          if (GameConfig.gameDurationSeconds > 0)
            _StatBox(
              icon: Symbols.timer,
              label: 'TIME',
              value: _formatTime(gc.secondsRemaining),
              color: gc.secondsRemaining < 30
                  ? AppColors.error
                  : AppColors.orange,
            )
          else
            const SizedBox(width: 80),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.cinzel(
                    fontSize: 9,
                    letterSpacing: 2,
                    color: AppColors.sandDark)),
            Text(value,
                style: GoogleFonts.pirataOne(
                    fontSize: 22,
                    color: color)),
          ],
        ),
      ],
    );
  }
}

// ── Antenna row — side by side ─────────────────────────────────────────────

class _AntennaRow extends StatelessWidget {
  final List<ShellModel> shells;
  const _AntennaRow({required this.shells});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Antenna A — shells 1-4
          Expanded(
            child: _AntennaPanel(
              label: 'ANTENNA A',
              subtitle: 'Shells 1 – 4',
              shells: shells.sublist(0, 4),
            ),
          ),
          const SizedBox(width: 12),
          // Antenna B — shells 5-8
          Expanded(
            child: _AntennaPanel(
              label: 'ANTENNA B',
              subtitle: 'Shells 5 – 8',
              shells: shells.sublist(4, 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _AntennaPanel extends StatelessWidget {
  final String label, subtitle;
  final List<ShellModel> shells;
  const _AntennaPanel({
    required this.label,
    required this.subtitle,
    required this.shells,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepBrown.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.orange.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Antenna label
          Row(
            children: [
              Container(
                width: 4, height: 24,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.cinzel(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: AppColors.orange)),
                  Text(subtitle,
                      style: GoogleFonts.cinzel(
                          fontSize: 9,
                          letterSpacing: 2,
                          color: AppColors.sandDark)),
                ],
              ),
              const Spacer(),
              Icon(Symbols.sensors, color: AppColors.orange.withOpacity(0.6), size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: AppColors.orange.withOpacity(0.25), height: 1),
          const SizedBox(height: 8),
          // 2×2 grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              physics: const NeverScrollableScrollPhysics(),
              children: shells.map((s) => ShellCard(shell: s)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Footer ─────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final GameController gc;
  const _Footer({required this.gc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: gc.returnToMenu,
            icon: Icon(Symbols.logout, size: 16, color: AppColors.sandDark),
            label: Text(
              'QUIT',
              style: GoogleFonts.cinzel(
                letterSpacing: 2,
                fontSize: 12,
                color: AppColors.sandDark,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.sandDark,
            ),
          ),
        ],
      ),
    );
  }
}