import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';
import 'game_controller.dart';
import 'screens.dart';
import 'app_scope.dart';
import 'models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final content = await const ContentRepository().load();
  final preferences = await SharedPreferences.getInstance();
  final controller = GameController(content: content, preferences: preferences);
  await controller.restore();
  runApp(GameScope(controller: controller, child: const SerialKillerApp()));
}

class SerialKillerApp extends StatefulWidget {
  const SerialKillerApp({super.key});
  @override
  State<SerialKillerApp> createState() => _SerialKillerAppState();
}

class _SerialKillerAppState extends State<SerialKillerApp> {
  Timer? _splashTimer;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Find a Serial Killer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0C1220),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE97964), brightness: Brightness.dark),
        fontFamily: 'Arial',
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: _showSplash ? const SplashScreen() : const GameShell(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B18),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: Image.asset(
                    'assets/splash_logo.jpg',
                    // width: 280,
                    height: 700,
                    fit: BoxFit.cover,
                    semanticLabel: 'Find a Serial Killer splash logo',
                  ),
                ),
                const SizedBox(height: 28),
                // const Text(
                //   'FIND A SERIAL KILLER',
                //   textAlign: TextAlign.center,
                //   style: TextStyle(
                //     color: Colors.white,
                //     fontSize: 21,
                //     fontWeight: FontWeight.w900,
                //     letterSpacing: 2.4,
                //   ),
                // ),
                const SizedBox(height: 10),
                const Text(
                  'Observe  ·  Compare  ·  Deduce',
                  style: TextStyle(color: Color(0xFF6ED5C8), letterSpacing: 1.2),
                ),
                const SizedBox(height: 10),
                const SizedBox(
                  width: 310,
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: Color(0xFFE97964),
                    backgroundColor: Colors.white12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GameShell extends StatelessWidget {
  const GameShell({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: _screenFor(controller.phase),
    );
  }

  Widget _screenFor(GamePhase phase) {
    switch (phase) {
      case GamePhase.mainMenu: return const MainMenuScreen(key: ValueKey('menu'));
      case GamePhase.genderSelection: return const GenderSelectionScreen(key: ValueKey('gender'));
      case GamePhase.briefing: return const BriefingScreen(key: ValueKey('briefing'));
      case GamePhase.profileReview: return const ProfileReviewScreen(key: ValueKey('review'));
      case GamePhase.messaging: return const InboxScreen(key: ValueKey('inbox'));
      case GamePhase.finalAccusation: return const AccusationScreen(key: ValueKey('accusation'));
      case GamePhase.levelWon: return const ResultScreen(won: true, key: ValueKey('won'));
      case GamePhase.levelFailed: return const ResultScreen(won: false, key: ValueKey('failed'));
    }
  }
}
