import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/content_repository.dart';
import 'logic/app_state.dart';
import 'logic/web_media.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'ui/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final content = await ContentRepository().load();
  final prefs = await SharedPreferences.getInstance();
  runApp(SaylarkApp(state: AppState(content, prefs)));
}

class SaylarkApp extends StatelessWidget {
  const SaylarkApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final app = AppScope(
      state: state,
      child: MaterialApp(
        title: 'Saylark',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const _Root(),
      ),
    );
    // In the browser, the first tap unlocks speech and sound (needed on iPhone).
    if (!kIsWeb) return app;
    return Listener(onPointerDown: (_) => webUnlockMedia(), child: app);
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return state.isSetUp ? const HomeScreen() : const OnboardingScreen();
  }
}
