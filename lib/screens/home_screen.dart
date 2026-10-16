import 'package:flutter/material.dart';

import '../logic/app_state.dart';
import 'learn_tab.dart';
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Text(state.target.flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(state.target.name, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        actions: [
          _Stat(
            icon: '🔥',
            value: state.currentStreak,
            tooltip: state.practicedToday ? 'Day streak' : 'Practice today to keep your streak',
            dim: !state.practicedToday,
          ),
          _Stat(icon: '⭐', value: state.progress.xp, tooltip: 'Total XP'),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          LearnTab(onOpenReview: () => setState(() => _tab = 1)),
          const ReviewTab(),
          const WordsTab(),
          const SettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school), label: 'Learn'),
          NavigationDestination(
            icon: Badge(isLabelVisible: due > 0, label: Text('$due'),
                child: const Icon(Icons.style_outlined)),
            selectedIcon: Badge(isLabelVisible: due > 0, label: Text('$due'),
                backgroundColor: theme.colorScheme.error,
                child: const Icon(Icons.style)),
            label: 'Review',
          ),
          const NavigationDestination(icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book), label: 'Words'),
          const NavigationDestination(icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.tooltip, this.dim = false});

  final String icon;
  final int value;
  final String tooltip;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: dim ? 0.5 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('$icon $value',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
