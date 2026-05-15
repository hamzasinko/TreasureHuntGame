// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/game_controller.dart';
import 'services/rfid_service.dart';
import 'screens/menu_screen.dart';
import 'screens/countdown_screen.dart';
import 'screens/game_screen.dart';
import 'screens/victory_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force landscape for poolside tablets
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide status bar for full-screen kiosk feel
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    ChangeNotifierProvider(
      create: (_) => GameController()..init(),
      child: const PoolShellHuntApp(),
    ),
  );
}

class PoolShellHuntApp extends StatelessWidget {
  const PoolShellHuntApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shell Hunt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF020810),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF40B0FF),
          surface: const Color(0xFF0A1830),
        ),
      ),
      home: const _RootNavigator(),
    );
  }
}

/// Switches between screens based on GameController phase.
class _RootNavigator extends StatelessWidget {
  const _RootNavigator();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (_, gc, __) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: _screenFor(gc.phase),
        );
      },
    );
  }

  Widget _screenFor(GamePhase phase) {
    switch (phase) {
      case GamePhase.menu:      return const MenuScreen(key: ValueKey('menu'));
      case GamePhase.countdown: return const CountdownScreen(key: ValueKey('countdown'));
      case GamePhase.playing:   return const GameScreen(key: ValueKey('game'));
      case GamePhase.victory:   return const VictoryScreen(key: ValueKey('victory'));
    }
  }
}
