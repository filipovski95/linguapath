import 'package:flutter/material.dart';

import '../logic/app_state.dart';
import '../logic/exercises.dart';
import '../logic/speech.dart';
import '../widgets/word_text.dart';

/// Runs a list of exercises one at a time and reports the results.
///
/// A question answered wrong is asked again at the end, once.
class QuizSession extends StatefulWidget {
  const QuizSession({super.key, required this.exercises, required this.onFinished});

  final List<Exercise> exercises;

  /// Concept id → answered right every time.
  final void Function(Map<String, bool> answers) onFinished;

  @override
  State<QuizSession> createState() => _QuizSessionState();
}

class _QuizSessionState extends State<QuizSession> {
  late final List<Exercise> _queue = [...widget.exercises];
  final _retried = <Exercise>{};
  final _answers = <String, bool>{};
  int _index = 0;

  // Choice exercise state
  String? _selected;
  bool _checked = false;

  // Match exercise state
  bool _matchDone = false;

  Exercise get _current => _queue[_index];

  void _record(String id, bool correct) {
    _answers[id] = (_answers[id] ?? true) && correct;
  }

  void _check(ChoiceExercise e) {
    final correct = _selected == e.conceptId;
    _record(e.conceptId, correct);
    if (!correct && _retried.add(e)) _queue.add(e);
    setState(() => _checked = true);
  }

  void _next() {
    if (_index + 1 >= _queue.length) {
      widget.onFinished(_answers);
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _checked = false;
      _matchDone = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = _current;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Quit',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: _index / _queue.length),
                    duration: const Duration(milliseconds: 300),
                    builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey(_index),
              child: switch (e) {
                LearnExercise() => _LearnView(exercise: e),
                ChoiceExercise() => _ChoiceView(
                    exercise: e,
                    selected: _selected,
                    checked: _checked,
                    onSelect: (id) => setState(() => _selected = id),
                  ),
                MatchExercise() => _MatchView(
                    exercise: e,
                    onMistake: (id) => _record(id, false),
                    onDone: () => setState(() => _matchDone = true),
                  ),
              },
            ),
          ),
        ),
        _BottomBar(
          exercise: e,
          selected: _selected,
          checked: _checked,
          matchDone: _matchDone,
          onCheck: () => _check(e as ChoiceExercise),
          onContinue: _next,
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.exercise,
    required this.selected,
    required this.checked,
    required this.matchDone,
    required this.onCheck,
    required this.onContinue,
  });

  final Exercise exercise;
  final String? selected;
  final bool checked;
  final bool matchDone;
  final VoidCallback onCheck;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final e = exercise;

    Widget? feedback;
    Color? background;
    VoidCallback? action;
    var label = 'Continue';

    switch (e) {
      case LearnExercise():
        action = onContinue;
      case MatchExercise():
        action = matchDone ? onContinue : null;
      case ChoiceExercise():
        if (!checked) {
          label = 'Check';
          action = selected == null ? null : onCheck;
        } else {
          action = onContinue;
          final right = selected == e.conceptId;
          background = right ? Colors.green.withValues(alpha: 0.15) : scheme.errorContainer;
          final t = state.target.entry(e.conceptId);
          final n = state.native.entry(e.conceptId);
          feedback = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(right ? '✅ Correct!' : '❌ Not quite',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                '${t.text}${t.roman != null && state.showRomanization ? ' (${t.roman})' : ''} = ${n.text}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          );
        }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: background ?? Colors.transparent,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (feedback != null) ...[feedback, const SizedBox(height: 12)],
            FilledButton(onPressed: action, child: Text(label)),
          ],
        ),
      ),
    );
  }
}

class _LearnView extends StatefulWidget {
  const _LearnView({required this.exercise});

  final LearnExercise exercise;

  @override
  State<_LearnView> createState() => _LearnViewState();
}

class _LearnViewState extends State<_LearnView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  void _play() {
    if (!mounted) return;
    final s = AppScope.read(context);
    Speech.instance.speak(
        s.target.entry(widget.exercise.conceptId).text, s.target.ttsLocale, rate: s.speechRate);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final id = widget.exercise.conceptId;
    final t = state.target.entry(id);
    final n = state.native.entry(id);
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('New word', style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary)),
          const SizedBox(height: 16),
          Text(state.course.concepts[id]?.emoji ?? '', style: const TextStyle(fontSize: 88)),
          const SizedBox(height: 16),
          WordText(entry: t, size: 40),
          const SizedBox(height: 8),
          SpeakButton(text: t.text, size: 32, filled: true),
          const SizedBox(height: 16),
          Text(n.text, textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant)),
          if (t.note != null) ...[
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Text('💡 '),
                    Expanded(child: Text(t.note!)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceView extends StatefulWidget {
  const _ChoiceView({
    required this.exercise,
    required this.selected,
    required this.checked,
    required this.onSelect,
  });

  final ChoiceExercise exercise;
  final String? selected;
  final bool checked;
  final ValueChanged<String> onSelect;

  @override
  State<_ChoiceView> createState() => _ChoiceViewState();
}

class _ChoiceViewState extends State<_ChoiceView> {
  @override
  void initState() {
    super.initState();
    if (widget.exercise.mode != ChoiceMode.nativeToTarget) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final s = AppScope.read(context);
        Speech.instance.speak(s.target.entry(widget.exercise.conceptId).text,
            s.target.ttsLocale, rate: s.speechRate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final e = widget.exercise;
    final theme = Theme.of(context);
    final t = state.target.entry(e.conceptId);

    final (String instruction, Widget prompt) = switch (e.mode) {
      ChoiceMode.targetToNative => (
          'What does this mean?',
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpeakButton(text: t.text),
              Flexible(child: WordText(entry: t, size: 34)),
            ],
          ),
        ),
      ChoiceMode.nativeToTarget => (
          'How do you say this in ${state.target.name}?',
          Column(children: [
            Text(state.course.concepts[e.conceptId]?.emoji ?? '',
                style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            Text(state.native.entry(e.conceptId).text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          ]),
        ),
      ChoiceMode.listen => (
          'What did you hear?',
          Column(children: [
            SizedBox.square(
              dimension: 96,
              child: IconButton.filled(
                iconSize: 48,
                icon: const Icon(Icons.volume_up_rounded),
                tooltip: 'Play again',
                onPressed: () => Speech.instance.speak(t.text, state.target.ttsLocale,
                    rate: state.speechRate),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Speech.instance.speak(t.text, state.target.ttsLocale,
                  rate: state.speechRate * 0.6),
              child: const Text('🐢 Slower'),
            ),
          ]),
        ),
    };

    final showTarget = e.mode == ChoiceMode.nativeToTarget;

    return ListView(
      key: ValueKey('answer:${e.conceptId}'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        Text(instruction, style: theme.textTheme.titleMedium),
        const SizedBox(height: 24),
        Center(child: prompt),
        const SizedBox(height: 28),
        for (final id in e.options)
          _OptionCard(
            key: ValueKey('option:$id'),
            selected: widget.selected == id,
            state: !widget.checked
                ? null
                : id == e.conceptId
                    ? true
                    : widget.selected == id
                        ? false
                        : null,
            onTap: widget.checked ? null : () {
              widget.onSelect(id);
              if (showTarget) {
                Speech.instance.speak(state.target.entry(id).text, state.target.ttsLocale,
                    rate: state.speechRate);
              }
            },
            child: showTarget
                ? WordText(entry: state.target.entry(id), size: 22, center: false)
                : Text(state.native.entry(id).text, style: const TextStyle(fontSize: 18)),
          ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    super.key,
    required this.child,
    required this.selected,
    required this.onTap,
    this.state,
  });

  final Widget child;
  final bool selected;

  /// true = correct answer, false = chosen wrong answer, null = neutral.
  final bool? state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color border = switch (state) {
      true => Colors.green,
      false => scheme.error,
      null => selected ? scheme.primary : scheme.outlineVariant,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? scheme.primaryContainer.withValues(alpha: 0.5) : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: selected || state != null ? 2.5 : 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
        ),
      ),
    );
  }
}

class _MatchView extends StatefulWidget {
  const _MatchView({required this.exercise, required this.onMistake, required this.onDone});

  final MatchExercise exercise;
  final ValueChanged<String> onMistake;
  final VoidCallback onDone;

  @override
  State<_MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends State<_MatchView> {
  late final List<String> _left = [...widget.exercise.conceptIds]..shuffle();
  late final List<String> _right = [...widget.exercise.conceptIds]..shuffle();
  final _matched = <String>{};
  String? _pickLeft;
  String? _pickRight;
  String? _wrongLeft;
  String? _wrongRight;

  void _tap({String? left, String? right}) {
    final s = AppScope.read(context);
    if (left != null) {
      Speech.instance.speak(s.target.entry(left).text, s.target.ttsLocale, rate: s.speechRate);
    }
    setState(() {
      _pickLeft = left ?? _pickLeft;
      _pickRight = right ?? _pickRight;
      _wrongLeft = _wrongRight = null;
      if (_pickLeft == null || _pickRight == null) return;
      if (_pickLeft == _pickRight) {
        _matched.add(_pickLeft!);
        if (_matched.length == _left.length) widget.onDone();
      } else {
        widget.onMistake(_pickLeft!);
        widget.onMistake(_pickRight!);
        _wrongLeft = _pickLeft;
        _wrongRight = _pickRight;
      }
      _pickLeft = _pickRight = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;

    Widget tile(String id, bool left) {
      final matched = _matched.contains(id);
      final picked = left ? _pickLeft == id : _pickRight == id;
      final wrong = left ? _wrongLeft == id : _wrongRight == id;
      final entry = left ? state.target.entry(id) : state.native.entry(id);
      return Padding(
        key: ValueKey('${left ? 'left' : 'right'}:$id'),
        padding: const EdgeInsets.only(bottom: 10),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: matched ? 0.35 : 1,
          child: Material(
            color: matched
                ? Colors.green.withValues(alpha: 0.15)
                : picked
                    ? scheme.primaryContainer
                    : scheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: wrong ? scheme.error : picked ? scheme.primary : scheme.outlineVariant,
                width: wrong || picked ? 2.5 : 1.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: matched ? null : () => left ? _tap(left: id) : _tap(right: id),
              child: SizedBox(
                height: 64,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: left
                        ? FittedBox(child: WordText(entry: entry, size: 20))
                        : Text(entry.text, textAlign: TextAlign.center,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        Text('Tap the matching pairs', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(children: [for (final id in _left) tile(id, true)])),
            const SizedBox(width: 12),
            Expanded(child: Column(children: [for (final id in _right) tile(id, false)])),
          ],
        ),
      ],
    );
  }
}

/// Shown at the end of a lesson or practice round.
class ResultsView extends StatelessWidget {
  const ResultsView({
    super.key,
    required this.title,
    required this.answers,
    required this.xp,
    required this.onDone,
  });

  final String title;
  final Map<String, bool> answers;
  final int xp;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final right = answers.values.where((v) => v).length;
    final pct = answers.isEmpty ? 100 : (right * 100 / answers.length).round();
    final missed = answers.entries.where((e) => !e.value).map((e) => e.key).toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Text(pct >= 80 ? '🎉' : '💪', style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ResultChip(label: 'XP', value: '+$xp'),
                const SizedBox(width: 12),
                _ResultChip(label: 'Accuracy', value: '$pct%'),
                const SizedBox(width: 12),
                _ResultChip(label: 'Streak', value: '🔥 ${state.currentStreak}'),
              ],
            ),
            if (missed.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Words to practise', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final id in missed)
                    Chip(label: Text('${state.target.entry(id).text} · ${state.native.entry(id).text}')),
                ],
              ),
            ],
            const Spacer(),
            FilledButton(onPressed: onDone, child: const Text('Continue')),
          ],
        ),
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

