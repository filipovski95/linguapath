import 'package:flutter/material.dart';

import '../data/models.dart';
import '../logic/app_state.dart';
import '../ui/chunky_button.dart';
import '../ui/mascot.dart';
import '../ui/palette.dart';

/// Picks the one language to learn. Explanations are in the base language
/// (English unless changed in Settings).
///
/// Also used from Settings to switch course, in which case it pops when done.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, this.fromSettings = false});

  final bool fromSettings;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: fromSettings ? AppBar(title: const Text('Choose a course')) : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            if (!fromSettings) ...[
              Center(
                child: Text('LinguaPath',
                    style: theme.textTheme.headlineMedium?.copyWith(color: Palette.violet, letterSpacing: -0.5)),
              ),
              const SizedBox(height: 16),
            ],
            const MascotSays(
              mood: MascotMood.happy,
              size: 96,
              text: "Hi, I'm Pip! Which language do you want to learn?",
            ),
            const SizedBox(height: 8),
            Text('Learn one language at a time. You can switch courses whenever you like.',
                style: theme.textTheme.bodyMedium?.copyWith(color: Palette.inkSoft)),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth > 520 ? 3 : 2;
              const gap = 12.0;
              final w = (c.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final l in state.courses)
                    SizedBox(
                      width: w,
                      child: _CourseCard(
                        language: l,
                        selected: fromSettings && l.code == state.targetCode,
                        progress: state.progressFor(l.code).completed.length,
                        onTap: () {
                          state.setTarget(l.code);
                          if (fromSettings) Navigator.of(context).pop();
                        },
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.language,
    required this.onTap,
    required this.progress,
    this.selected = false,
  });

  final Language language;
  final VoidCallback onTap;
  final int progress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: language.name,
      excludeSemantics: true,
      child: ChunkyCard(
        onTap: onTap,
        border: selected ? const Color(0xFF9C85FF) : Palette.line,
        fill: selected ? Palette.violetSoft : Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
        child: Column(
          children: [
            Text(language.flag, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 6),
            Text(language.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Palette.ink)),
            Text(
              progress > 0 ? '$progress ${progress == 1 ? 'lesson' : 'lessons'} done' : language.nativeName,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: progress > 0 ? Palette.green : Palette.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
