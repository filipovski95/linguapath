import 'package:flutter/material.dart';

import '../logic/app_state.dart';
import '../logic/exercises.dart';
import '../logic/srs.dart';
import '../widgets/word_text.dart';
import '../ui/chunky_button.dart';
import '../ui/mascot.dart';
import '../ui/palette.dart';
import 'quiz_session.dart';

/// Flashcards for words that are due, using spaced repetition.
class ReviewTab extends StatefulWidget {
  const ReviewTab({super.key});

  @override
  State<ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends State<ReviewTab> {
  bool _flipped = false;
  int _reviewedThisSession = 0;

  void _grade(String id, ReviewGrade g) {
    AppScope.read(context).review(id, g);
    setState(() {
      _flipped = false;
      _reviewedThisSession++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final due = state.dueWords;
    final theme = Theme.of(context);

    if (due.isEmpty) {
      final learned = state.learnedWords.length;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Mascot(mood: learned == 0 ? MascotMood.thinking : MascotMood.cheer, size: 130),
              const SizedBox(height: 16),
              Text(
                learned == 0 ? 'No words yet' : 'All caught up!',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                learned == 0
                    ? 'Finish a lesson and its words will show up here for review.'
                    : 'You know $learned ${learned == 1 ? 'word' : 'words'}. '
                        'Come back tomorrow for the next review.',
                textAlign: TextAlign.center,
              ),
              if (learned >= 4) ...[
                const SizedBox(height: 24),
                ChunkyButton(
                  label: 'Quick practice',
                  icon: Icons.bolt_rounded,
                  onPressed: () => _openPractice(context, state),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final id = due.first;
    final t = state.target.entry(id);
    final n = state.native.entry(id);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${due.length} left · $_reviewedThisSession done',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_flipped) state.say(t.text);
                setState(() => _flipped = !_flipped);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: const Border(
                    top: BorderSide(color: Palette.line, width: 2),
                    left: BorderSide(color: Palette.line, width: 2),
                    right: BorderSide(color: Palette.line, width: 2),
                    bottom: BorderSide(color: Palette.line, width: 7),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      WordText(entry: t, size: 44, color: Palette.ink),
                      const SizedBox(height: 12),
                      SpeakButton(text: t.text, size: 52),
                      const SizedBox(height: 24),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        crossFadeState:
                            _flipped ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        firstChild: Text('Tap to reveal',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                        secondChild: Column(
                          children: [
                            Text(state.course.concepts[id]?.emoji ?? '',
                                style: const TextStyle(fontSize: 48)),
                            Text(n.text,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall),
                            if (t.note != null) ...[
                              const SizedBox(height: 8),
                              Text('💡 ${t.note!}', textAlign: TextAlign.center),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_flipped)
            Row(
              children: [
                Expanded(child: ChunkyButton(label: 'Again', color: Palette.coral, shadow: Palette.coralDark,
                    onPressed: () => _grade(id, ReviewGrade.again))),
                const SizedBox(width: 10),
                Expanded(child: ChunkyButton(label: 'Good', onPressed: () => _grade(id, ReviewGrade.good))),
                const SizedBox(width: 10),
                Expanded(child: ChunkyButton(label: 'Easy', color: Palette.green, shadow: Palette.greenDark,
                    onPressed: () => _grade(id, ReviewGrade.easy))),
              ],
            )
          else
            ChunkyButton(label: 'Show answer', onPressed: () => setState(() => _flipped = true)),
        ],
      ),
    );
  }

  void _openPractice(BuildContext context, AppState state) {
    final words = state.practiceWords(8);
    final exercises = ExerciseBuilder(course: state.course, target: state.target,
        native: state.native, typing: state.typingOn).forWords(words);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PracticeScreen(exercises: exercises),
    ));
  }
}

class _PracticeScreen extends StatefulWidget {
  const _PracticeScreen({required this.exercises});

  final List<Exercise> exercises;

  @override
  State<_PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<_PracticeScreen> {
  Map<String, bool>? _results;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _results != null
            ? ResultsView(
                title: 'Practice complete!',
                answers: _results!,
                xp: _results!.length * AppState.xpPerReview,
                onDone: () => Navigator.pop(context),
              )
            : QuizSession(
                exercises: widget.exercises,
                onFinished: (answers) {
                  final s = AppScope.read(context);
                  answers.forEach((id, ok) =>
                      s.review(id, ok ? ReviewGrade.good : ReviewGrade.again));
                  setState(() => _results = answers);
                },
              ),
      ),
    );
  }
}
