import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/answer_check.dart';
import '../logic/app_state.dart';
import '../logic/cheers.dart';
import '../logic/exercises.dart';
import '../logic/sounds.dart';
import '../ui/chunky_button.dart';
import '../ui/confetti.dart';
import '../ui/mascot.dart';
import '../ui/palette.dart';
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
  int _inARow = 0;

  String? _selected;
  String _typed = '';
  bool _checked = false;
  bool _right = false;
  String _cheer = '';
  bool _matchDone = false;

  Exercise get _current => _queue[_index];

  void _record(String id, bool correct) {
    _answers[id] = (_answers[id] ?? true) && correct;
  }

  void _check() {
    final e = _current;
    final state = AppScope.read(context);
    final String id;
    final bool correct;
    var almost = false;
    switch (e) {
      case ChoiceExercise():
        id = e.conceptId;
        correct = _selected == id;
      case TypeExercise():
        id = e.conceptId;
        final entry = state.target.entry(id);
        correct = AnswerCheck.matches(_typed, entry);
        almost = correct && !AnswerCheck.exact(_typed, entry);
        state.say(entry.text);
      default:
        return;
    }
    _right = correct;
    _record(id, correct);
    if (correct) {
      _inARow++;
      _cheer = almost
          ? 'Almost perfect! Watch the accents.'
          : _inARow >= 3 && _inARow % 3 == 0
              ? Cheers.streak(_inARow)
              : Cheers.correct();
      Sounds.instance.correct();
      HapticFeedback.lightImpact();
    } else {
      _inARow = 0;
      _cheer = Cheers.wrong();
      Sounds.instance.wrong();
      HapticFeedback.heavyImpact();
      if (_retried.add(e)) _queue.add(e);
    }
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
      _typed = '';
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
          padding: const EdgeInsets.fromLTRB(4, 8, 20, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 30, color: Palette.lockedDark),
                tooltip: 'Quit',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 4),
              Expanded(child: _ProgressBar(value: _index / _queue.length)),
              if (_inARow >= 3) ...[
                const SizedBox(width: 10),
                Text('🔥$_inARow',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Palette.flame, fontSize: 16)),
              ],
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(a),
                child: child,
              ),
            ),
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
                TypeExercise() => _TypeView(
                    exercise: e,
                    checked: _checked,
                    right: _right,
                    onChanged: (v) => setState(() => _typed = v),
                    onSubmit: () {
                      if (!_checked && _typed.trim().isNotEmpty) _check();
                    },
                  ),
                MatchExercise() => _MatchView(
                    exercise: e,
                    onMistake: (id) => _record(id, false),
                    onDone: () {
                      Sounds.instance.correct();
                      setState(() => _matchDone = true);
                    },
                  ),
              },
            ),
          ),
        ),
        _BottomBar(
          exercise: e,
          canCheck: e is TypeExercise ? _typed.trim().isNotEmpty : _selected != null,
          checked: _checked,
          right: _right,
          cheer: _cheer,
          matchDone: _matchDone,
          onCheck: _check,
          onContinue: _next,
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      decoration: BoxDecoration(color: Palette.locked, borderRadius: BorderRadius.circular(9)),
      child: LayoutBuilder(
        builder: (context, c) => Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            width: c.maxWidth * value.clamp(0.04, 1.0),
            decoration: BoxDecoration(color: Palette.green, borderRadius: BorderRadius.circular(9)),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                height: 4,
                decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.exercise,
    required this.canCheck,
    required this.checked,
    required this.right,
    required this.cheer,
    required this.matchDone,
    required this.onCheck,
    required this.onContinue,
  });

  final Exercise exercise;
  final bool canCheck;
  final bool checked;
  final bool right;
  final String cheer;
  final bool matchDone;
  final VoidCallback onCheck;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final e = exercise;
    Widget? feedback;
    Color background = Colors.transparent;
    var button = ChunkyButton(label: 'Continue', onPressed: onContinue, color: Palette.green, shadow: Palette.greenDark);

    switch (e) {
      case LearnExercise():
        break;
      case MatchExercise():
        button = ChunkyButton(
            label: 'Continue', onPressed: matchDone ? onContinue : null, color: Palette.green, shadow: Palette.greenDark);
      case ChoiceExercise(:final conceptId) || TypeExercise(:final conceptId):
        if (!checked) {
          button = ChunkyButton(
              label: 'Check', onPressed: canCheck ? onCheck : null, color: Palette.green, shadow: Palette.greenDark);
        } else {
          final fg = right ? Palette.greenDark : Palette.coralDark;
          background = right ? Palette.greenSoft : Palette.coralSoft;
          final t = state.target.entry(conceptId);
          final n = state.native.entry(conceptId);
          feedback = Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(right ? Icons.check_rounded : Icons.close_rounded, color: fg, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(right ? '✅ Correct!' : '❌ Not quite',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: fg)),
                    Text(cheer, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
                    const SizedBox(height: 2),
                    Text(
                      '${t.text}${t.roman != null && state.showRomanization ? ' (${t.roman})' : ''} = ${n.text}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: fg),
                    ),
                  ],
                ),
              ),
            ],
          );
          button = right
              ? ChunkyButton(label: 'Continue', onPressed: onContinue, color: Palette.green, shadow: Palette.greenDark)
              : ChunkyButton(label: 'Got it', onPressed: onContinue, color: Palette.coral, shadow: Palette.coralDark);
        }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: background,
        border: background == Colors.transparent
            ? const Border(top: BorderSide(color: Palette.line, width: 2))
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (feedback != null) ...[feedback, const SizedBox(height: 14)],
            button,
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
  late final String _intro = Cheers.newWord();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = AppScope.read(context);
      s.say(s.target.entry(widget.exercise.conceptId).text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final id = widget.exercise.conceptId;
    final t = state.target.entry(id);
    final n = state.native.entry(id);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Text('New word', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        MascotSays(text: _intro, mood: MascotMood.happy, size: 64),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: const Border(
              top: BorderSide(color: Palette.line, width: 2),
              left: BorderSide(color: Palette.line, width: 2),
              right: BorderSide(color: Palette.line, width: 2),
              bottom: BorderSide(color: Palette.line, width: 6),
            ),
          ),
          child: Column(
            children: [
              Text(state.course.concepts[id]?.emoji ?? '', style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 12),
              WordText(entry: t, size: 40, color: Palette.ink),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpeakButton(text: t.text, size: 56),
                  const SizedBox(width: 12),
                  SpeakButton(text: t.text, size: 44, slow: true),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Palette.violetSoft, borderRadius: BorderRadius.circular(12)),
                child: Text(n.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Palette.violetDark)),
              ),
              if (t.note != null) ...[
                const SizedBox(height: 14),
                Text('💡 ${t.note!}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Palette.inkSoft, fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ),
      ],
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
        s.say(s.target.entry(widget.exercise.conceptId).text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final e = widget.exercise;
    final t = state.target.entry(e.conceptId);
    // Small phones: shrink the prompt so all four answers fit above the bottom bar.
    final compact = MediaQuery.sizeOf(context).height < 720;

    final (String instruction, Widget prompt) = switch (e.mode) {
      ChoiceMode.targetToNative => (
          'What does this mean?',
          MascotSays(
            text: t.text,
            size: 72,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpeakButton(text: t.text, size: 40),
                const SizedBox(width: 12),
                Flexible(child: WordText(entry: t, size: 28, center: false)),
              ],
            ),
          ),
        ),
      ChoiceMode.nativeToTarget => (
          'How do you say this in ${state.target.name}?',
          Center(
            child: Column(children: [
              Text(state.course.concepts[e.conceptId]?.emoji ?? '', style: TextStyle(fontSize: compact ? 44 : 64)),
              const SizedBox(height: 4),
              Text(state.native.entry(e.conceptId).text,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: compact ? 24 : 28, fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
      ChoiceMode.listen => (
          'What did you hear?',
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SpeakButton(text: t.text, size: compact ? 76 : 96),
              const SizedBox(width: 16),
              SpeakButton(text: t.text, size: 60, slow: true),
            ],
          ),
        ),
    };

    final showTarget = e.mode == ChoiceMode.nativeToTarget;

    return ListView(
      key: ValueKey('answer:${e.conceptId}'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Text(instruction, style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: compact ? 12 : 20),
        prompt,
        SizedBox(height: compact ? 14 : 24),
        for (final id in e.options)
          Padding(
            key: ValueKey('option:$id'),
            padding: EdgeInsets.only(bottom: compact ? 8 : 12),
            child: _option(state, id, showTarget, compact),
          ),
      ],
    );
  }

  Widget _option(AppState state, String id, bool showTarget, bool compact) {
    final e = widget.exercise;
    final selected = widget.selected == id;
    final isAnswer = id == e.conceptId;
    final (Color border, Color fill, Color text) = !widget.checked
        ? selected
            ? (const Color(0xFF9C85FF), Palette.violetSoft, Palette.violetDark)
            : (Palette.line, Colors.white, Palette.ink)
        : isAnswer
            ? (Palette.green, Palette.greenSoft, Palette.greenDark)
            : selected
                ? (Palette.coral, Palette.coralSoft, Palette.coralDark)
                : (Palette.line, Colors.white, Palette.inkSoft);
    return ChunkyCard(
      border: border,
      fill: fill,
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: compact ? 10 : 14),
      onTap: widget.checked
          ? null
          : () {
              widget.onSelect(id);
              if (showTarget) state.say(state.target.entry(id).text);
            },
      child: showTarget
          ? WordText(entry: state.target.entry(id), size: 22, center: false, color: text)
          : Text(state.native.entry(id).text,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: text)),
    );
  }
}

class _TypeView extends StatefulWidget {
  const _TypeView({
    required this.exercise,
    required this.checked,
    required this.right,
    required this.onChanged,
    required this.onSubmit,
  });

  final TypeExercise exercise;
  final bool checked;
  final bool right;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  State<_TypeView> createState() => _TypeViewState();
}

class _TypeViewState extends State<_TypeView> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.exercise.listen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final s = AppScope.read(context);
        s.say(s.target.entry(widget.exercise.conceptId).text);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final e = widget.exercise;
    final t = state.target.entry(e.conceptId);
    final compact = MediaQuery.sizeOf(context).height < 720;
    final hint = switch (state.target.code) {
      'zh' => 'Characters or Pinyin are both fine',
      'mk' => 'Cyrillic or Latin letters are both fine',
      _ => null,
    };
    final border = !widget.checked
        ? Palette.line
        : widget.right
            ? Palette.green
            : Palette.coral;

    return ListView(
      key: ValueKey('type:${e.conceptId}'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Text(e.listen ? 'Type what you hear' : 'Write this in ${state.target.name}',
            style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: compact ? 12 : 20),
        if (e.listen)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SpeakButton(text: t.text, size: compact ? 76 : 96),
              const SizedBox(width: 16),
              SpeakButton(text: t.text, size: 60, slow: true),
            ],
          )
        else
          Center(
            child: Column(children: [
              Text(state.course.concepts[e.conceptId]?.emoji ?? '', style: TextStyle(fontSize: compact ? 44 : 64)),
              const SizedBox(height: 4),
              Text(state.native.entry(e.conceptId).text,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: compact ? 24 : 28, fontWeight: FontWeight.w900)),
            ]),
          ),
        SizedBox(height: compact ? 16 : 24),
        TextField(
          key: const ValueKey('type-answer'),
          controller: _controller,
          autofocus: true,
          readOnly: widget.checked,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Palette.ink),
          decoration: InputDecoration(
            hintText: 'Type in ${state.target.name}',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border, width: 2)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: widget.checked ? border : Palette.violet, width: 2.5)),
          ),
          onChanged: widget.onChanged,
          onSubmitted: (_) => widget.onSubmit(),
        ),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(hint, style: const TextStyle(color: Palette.inkSoft, fontWeight: FontWeight.w600)),
        ],
      ],
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
    if (left != null) s.say(s.target.entry(left).text);
    setState(() {
      _pickLeft = left ?? _pickLeft;
      _pickRight = right ?? _pickRight;
      _wrongLeft = _wrongRight = null;
      if (_pickLeft == null || _pickRight == null) return;
      if (_pickLeft == _pickRight) {
        _matched.add(_pickLeft!);
        HapticFeedback.lightImpact();
        if (_matched.length == _left.length) widget.onDone();
      } else {
        widget.onMistake(_pickLeft!);
        widget.onMistake(_pickRight!);
        _wrongLeft = _pickLeft;
        _wrongRight = _pickRight;
        HapticFeedback.heavyImpact();
      }
      _pickLeft = _pickRight = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    Widget tile(String id, bool left) {
      final matched = _matched.contains(id);
      final picked = left ? _pickLeft == id : _pickRight == id;
      final wrong = left ? _wrongLeft == id : _wrongRight == id;
      final entry = left ? state.target.entry(id) : state.native.entry(id);
      final (Color border, Color fill, Color text) = matched
          ? (Palette.line, Palette.background, Palette.lockedDark)
          : wrong
              ? (Palette.coral, Palette.coralSoft, Palette.coralDark)
              : picked
                  ? (const Color(0xFF9C85FF), Palette.violetSoft, Palette.violetDark)
                  : (Palette.line, Colors.white, Palette.ink);
      return Padding(
        key: ValueKey('${left ? 'left' : 'right'}:$id'),
        padding: const EdgeInsets.only(bottom: 12),
        child: ChunkyCard(
          border: border,
          fill: fill,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          onTap: matched ? null : () => left ? _tap(left: id) : _tap(right: id),
          child: SizedBox(
            height: 62,
            child: Center(
              child: left
                  ? FittedBox(child: WordText(entry: entry, size: 20, color: text))
                  : Text(entry.text,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: text)),
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Text('Tap the matching pairs', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20),
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
class ResultsView extends StatefulWidget {
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
  State<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<ResultsView> {
  @override
  void initState() {
    super.initState();
    Sounds.instance.complete();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final right = widget.answers.values.where((v) => v).length;
    final pct = widget.answers.isEmpty ? 100 : (right * 100 / widget.answers.length).round();
    final missed = widget.answers.entries.where((e) => !e.value).map((e) => e.key).toList();
    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              children: [
                const Spacer(),
                Mascot(mood: pct >= 80 ? MascotMood.cheer : MascotMood.happy, size: 150),
                const SizedBox(height: 16),
                Text(widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Palette.sunDark)),
                const SizedBox(height: 6),
                Text(Cheers.lessonDone(pct),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Palette.inkSoft)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _StatTile(label: 'Total XP', value: '⚡ ${widget.xp}', color: Palette.sun)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatTile(label: 'Accuracy', value: '🎯 $pct%', color: Palette.green)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatTile(label: 'Streak', value: '🔥 ${state.currentStreak}', color: Palette.flame)),
                  ],
                ),
                if (missed.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Words to practise',
                      style: TextStyle(fontWeight: FontWeight.w900, color: Palette.inkSoft)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final id in missed)
                        Chip(
                          side: const BorderSide(color: Palette.line, width: 2),
                          backgroundColor: Colors.white,
                          label: Text('${state.target.entry(id).text} · ${state.native.entry(id).text}',
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                    ],
                  ),
                ],
                const Spacer(),
                ChunkyButton(label: 'Continue', onPressed: widget.onDone, color: Palette.green, shadow: Palette.greenDark),
              ],
            ),
          ),
        ),
        const Positioned.fill(child: Confetti()),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(2.5),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(label.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.8)),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Text(value,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          ),
        ],
      ),
    );
  }
}
