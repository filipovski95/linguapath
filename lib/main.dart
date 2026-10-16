import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/content_repository.dart';
import 'logic/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final content = await ContentRepository().load();
  final prefs = await SharedPreferences.getInstance();
  runApp(LinguaPathApp(state: AppState(content, prefs)));
}

class LinguaPathApp extends StatelessWidget {
  const LinguaPathApp({super.key, required this.state});

  final AppState state;

  static const seed = Color(0xFF1E88A8);

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'LinguaPath',
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: const _Root(),
      ),
    );
  }

  ThemeData _theme(Brightness b) => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: b),
        useMaterial3: true,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      );
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return state.isSetUp ? const HomeScreen() : const OnboardingScreen();
  }
}
