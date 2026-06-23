// lib/main.dart

import 'package:app_treasuregame/config/app_colors.dart';
import 'package:app_treasuregame/screens/mode_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/game_controller.dart';
import 'screens/menu_screen.dart';
import 'screens/countdown_screen.dart';
import 'screens/game_screen.dart';
import 'screens/victory_screen.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart';
import 'screens/splash_screen.dart';
import 'models/game_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    await windowManager.ensureInitialized();
    await windowManager.setFullScreen(true);
  }

  await GameConfig.loadFromPrefs();

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
          primary: AppColors.blue,
          surface: AppColors.deepBrown,
        ),
      ),
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();
  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(
        onDone: () => setState(() => _splashDone = true),
      );
    }
    return const _RootNavigator();
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
      case GamePhase.modeSelect: return const ModeSelectScreen(key: ValueKey('mode'));
      case GamePhase.countdown: return const CountdownScreen(key: ValueKey('countdown'));
      case GamePhase.playing:   return const GameScreen(key: ValueKey('game'));
      case GamePhase.victory:   return const VictoryScreen(key: ValueKey('victory'));
    }
  }
}
