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
              Image.asset(
                'assets/images/beach.jpg',
                fit: BoxFit.cover,
              ),
              Container(color: AppColors.deepBrown.withOpacity(0.75)),
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
          Image.asset(
            'assets/images/schatduiken.png',
            height: 80,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
          style: GoogleFonts.cinzel(
            fontSize: 24,
            letterSpacing: 2,
            color: AppColors.sandDark)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 8),
            Text(value,
              style: GoogleFonts.pirataOne(
                fontSize: 24,
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
          Expanded(
            child: Consumer<GameController>(
              builder: (ctx, gc, child) => _AntennaPanel(
                label: gc.gameMode == GameMode.twoGroups ? 'GROUP A' : 'ANTENNA A',
                subtitle: 
                     'Shells 1 – 4',
                shells: gc.shells.sublist(0, 4),
                celebrating: gc.gameMode == GameMode.twoGroups && gc.group1Finished,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Consumer<GameController>(
              builder: (ctx, gc, child) => _AntennaPanel(
                label: gc.gameMode == GameMode.twoGroups ? 'GROUP B' : 'ANTENNA B',
                subtitle: 
                     'Shells 5 – 8',
                shells: gc.shells.sublist(4, 8),
                celebrating: gc.gameMode == GameMode.twoGroups && gc.group2Finished,
              ),
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
  final bool celebrating;
  const _AntennaPanel({
    required this.label,
    required this.subtitle,
    required this.shells,
    this.celebrating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
  children: [
    Container(
      decoration: BoxDecoration(
        color: celebrating
            ? AppColors.success.withOpacity(0.15)
            : AppColors.deepBrown.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: celebrating
              ? AppColors.success
              : AppColors.orange.withOpacity(0.4),
          width: celebrating ? 2.5 : 1.5,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 4, height: 24,
                decoration: BoxDecoration(
                  color: celebrating ? AppColors.success : AppColors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.cinzel(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: celebrating
                              ? AppColors.success
                              : AppColors.orange)),
                  Text(subtitle,
                      style: GoogleFonts.cinzel(
                          fontSize: 12,
                          letterSpacing: 2,
                          color: AppColors.sandDark)),
                ],
              ),
              const Spacer(),
              celebrating
                  ? Icon(Symbols.emoji_events,
                      color: AppColors.success, size: 22)
                  : Icon(Symbols.sensors,
                      color: AppColors.orange.withOpacity(0.6), size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Divider(
              color: celebrating
                  ? AppColors.success.withOpacity(0.4)
                  : AppColors.orange.withOpacity(0.25),
              height: 1),
          const SizedBox(height: 4),
          Expanded(
            child: Center(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.25,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: shells.map((s) => ShellCard(shell: s)).toList(),
              ),
            ),
          ),
        ],
      ),
    ),
    // Celebration banner
    if (celebrating)
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '🏆  ALL SHELLS FOUND!  🏆',
            style: GoogleFonts.pirataOne(
              fontSize: 14,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
  ],
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
                fontSize: 24,
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