import 'package:flutter/material.dart';

import '../logic/app_state.dart';
import '../ui/palette.dart';
import '../widgets/word_text.dart';
import 'learn_tab.dart';
import 'onboarding_screen.dart';
import 'review_tab.dart';
import 'settings_tab.dart';
import 'words_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final due = state.dueWords.length;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        titleSpacing: 12,
        title: Row(
          children: [
            Tooltip(
              message: 'Change course',
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const OnboardingScreen(fromSettings: true))),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Palette.line, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.target.flag, style: const TextStyle(fontSize: 22)),
                      const Icon(Icons.expand_more_rounded, size: 18, color: Palette.inkSoft),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Shrinks rather than overflows on narrow phones or with large text.
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatPill(
                      icon: '🔥',
                      value: '${state.currentStreak}',
                      color: Palette.flame,
                      dim: !state.practicedToday,
                      tooltip: state.practicedToday ? 'Day streak' : 'Do a lesson today to keep your streak',
                    ),
                    const SizedBox(width: 18),
                    StatPill(icon: '⚡', value: '${state.progress.xp}', color: Palette.sunDark, tooltip: 'Total XP'),
                    const SizedBox(width: 18),
                    StatPill(
                        icon: '📚', value: '${state.learnedWords.length}', color: Palette.violet, tooltip: 'Words learned'),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Divider(height: 2, thickness: 2, color: Palette.line),
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          LearnTab(onOpenReview: () => setState(() => _tab = 1)),
          // A new course or a reset starts a fresh review session.
          ReviewTab(key: ValueKey('${state.targetCode}:${state.learnedWords.isEmpty}')),
          const WordsTab(),
          const SettingsTab(),
        ],
      ),
      // The bar has a fixed height, so very large text would push its labels off screen.
      bottomNavigationBar: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: NavigationBar(
          selectedIndex: _tab,
          height: 68,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: [
            const NavigationDestination(icon: Text('🏠', style: TextStyle(fontSize: 24)), label: 'Learn'),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: due > 0,
                backgroundColor: Palette.coral,
                label: Text('$due'),
                child: const Text('🧠', style: TextStyle(fontSize: 24)),
              ),
              label: 'Review',
            ),
            const NavigationDestination(icon: Text('📖', style: TextStyle(fontSize: 24)), label: 'Words'),
            const NavigationDestination(icon: Text('⚙️', style: TextStyle(fontSize: 24)), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
