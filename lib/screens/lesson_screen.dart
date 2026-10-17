import 'package:flutter/material.dart';

import '../data/models.dart';
import '../logic/app_state.dart';
import '../logic/exercises.dart';
import 'quiz_session.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  List<Exercise>? _exercises;
  Map<String, bool>? _results;
  int _xp = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppScope.read(context);
    _exercises ??= ExerciseBuilder(course: s.course, target: s.target, native: s.native, typing: s.typingOn)
        .forLesson(widget.lesson);
  }

  void _finish(Map<String, bool> answers) {
    final s = AppScope.read(context);
    final before = s.progress.xp;
    s.completeLesson(widget.lesson, answers);
    setState(() {
      _results = answers;
      _xp = s.progress.xp - before;
    });
  }

  Future<bool> _confirmQuit() async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Quit this lesson?'),
        content: const Text("Your progress in this lesson won't be saved."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep going')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Quit')),
        ],
      ),
    );
    return quit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final done = _results != null;
    return PopScope(
      canPop: done,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmQuit()) nav.pop();
      },
      child: Scaffold(
        body: SafeArea(
          child: done
              ? ResultsView(
                  title: widget.lesson.practice ? 'Unit practice complete!' : 'Lesson complete!',
                  answers: _results!,
                  xp: _xp,
                  onDone: () => Navigator.of(context).pop(),
                )
              : QuizSession(exercises: _exercises!, onFinished: _finish),
        ),
      ),
    );
  }
}
