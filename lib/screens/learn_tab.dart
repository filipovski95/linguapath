import 'package:flutter/material.dart';

import '../data/models.dart';
import '../logic/app_state.dart';
import 'lesson_screen.dart';

class LearnTab extends StatelessWidget {
  const LearnTab({super.key, required this.onOpenReview});

  final VoidCallback onOpenReview;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final due = state.dueWords.length;
    final next = state.nextLesson;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (next != null) _ContinueCard(lesson: next),
        if (due > 0) ...[
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: ListTile(
              leading: const Text('🧠', style: TextStyle(fontSize: 28)),
              title: Text('$due ${due == 1 ? 'word' : 'words'} to review'),
              subtitle: const Text('A quick review keeps them in memory.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onOpenReview,
            ),
          ),
        ],
        for (final unit in state.course.units) _UnitSection(unit: unit),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final unit = state.course.units.firstWhere((u) => u.lessons.contains(lesson));
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(state.progress.completed.isEmpty ? 'Start here' : 'Up next',
                style: TextStyle(color: scheme.onPrimaryContainer)),
            const SizedBox(height: 4),
            Text('${unit.emoji} ${unit.title} · ${lesson.title}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => openLesson(context, lesson),
              child: Text(state.progress.completed.isEmpty ? 'Start learning' : 'Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitSection extends StatelessWidget {
  const _UnitSection({required this.unit});

  final Unit unit;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final done = unit.lessons.where(state.isCompleted).length;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(unit.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(unit.title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Text('$done/${unit.lessons.length}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: done / unit.lessons.length, minHeight: 6),
          ),
          const SizedBox(height: 8),
          for (final lesson in unit.lessons) _LessonTile(lesson: lesson),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final completed = state.isCompleted(lesson);
    final unlocked = state.isUnlocked(lesson);
    final preview = lesson.conceptIds
        .take(4)
        .map((id) => state.target.entry(id).text)
        .join(' · ');

    final Widget badge = CircleAvatar(
      radius: 22,
      backgroundColor: completed
          ? scheme.primary
          : unlocked
              ? scheme.secondaryContainer
              : scheme.surfaceContainerHighest,
      child: Icon(
        completed
            ? Icons.check_rounded
            : !unlocked
                ? Icons.lock_rounded
                : lesson.practice
                    ? Icons.fitness_center_rounded
                    : Icons.play_arrow_rounded,
        color: completed ? scheme.onPrimary : scheme.onSecondaryContainer,
      ),
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      enabled: unlocked,
      leading: badge,
      title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        lesson.practice ? 'Review the whole unit' : preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: unlocked ? () => openLesson(context, lesson) : null,
    );
  }
}

void openLesson(BuildContext context, Lesson lesson) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)),
  );
}
