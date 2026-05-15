// lib/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_config.dart';
import '../models/shell_model.dart';
import '../services/game_controller.dart';
import '../widgets/shell_card.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (_, gc, __) {
        final allFound = gc.shells.every((s) => s.isFound);
        return Scaffold(
          backgroundColor: const Color(0xFF020D1E),
          body: SafeArea(
            child: Column(
              children: [
                _Header(gc: gc),
                const SizedBox(height: 12),
                Expanded(child: _ShellGrid(shells: gc.shells)),
                const SizedBox(height: 12),
                _Footer(gc: gc),
                const SizedBox(height: 8),
              ],
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF030E22), Color(0xFF020D1E)],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1A3560), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Score
          _StatBox(
            label: 'SCORE',
            value: '$found / ${GameConfig.totalShells}',
            color: const Color(0xFF00C055),
          ),
          const Spacer(),
          // Title
          const Text(
            '🐚 SHELL HUNT',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: Color(0xFF60B0E0),
            ),
          ),
          const Spacer(),
          // Timer (only if limited game)
          if (GameConfig.gameDurationSeconds > 0)
            _StatBox(
              label: 'TIME',
              value: _formatTime(gc.secondsRemaining),
              color: gc.secondsRemaining < 30
                  ? const Color(0xFFFF4444)
                  : const Color(0xFF40B0FF),
            )
          else
            const SizedBox(width: 80),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                letterSpacing: 2,
                color: Colors.white.withOpacity(0.4))),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color)),
      ],
    );
  }
}

// ── Shell grid ─────────────────────────────────────────────────────────────

class _ShellGrid extends StatelessWidget {
  final List<ShellModel> shells;
  const _ShellGrid({required this.shells});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Antenna A label
          _AntennaLabel(label: 'ANTENNA  A', subtitle: 'Shells 1 – 4'),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: shells
                  .sublist(0, 4)
                  .map((s) => Expanded(
                      child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: ShellCard(shell: s))))
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFF1A3560), thickness: 1),
          const SizedBox(height: 10),
          // Antenna B label
          _AntennaLabel(label: 'ANTENNA  B', subtitle: 'Shells 5 – 8'),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: shells
                  .sublist(4, 8)
                  .map((s) => Expanded(
                      child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: ShellCard(shell: s))))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AntennaLabel extends StatelessWidget {
  final String label, subtitle;
  const _AntennaLabel({required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF2080FF),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: Color(0xFF4090C0))),
          Text(subtitle,
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  letterSpacing: 2,
                  color: Colors.white.withOpacity(0.3))),
        ]),
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
            icon: const Icon(Icons.close, size: 16),
            label: const Text('QUIT', style: TextStyle(letterSpacing: 2, fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }
}
