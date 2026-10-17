import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../logic/app_state.dart';
import '../logic/cheers.dart';
import '../ui/chunky_button.dart';
import '../ui/mascot.dart';
import '../ui/palette.dart';
import 'lesson_screen.dart';

/// The course path: units as colored banners, lessons as round stepping stones.
class LearnTab extends StatelessWidget {
  const LearnTab({super.key, required this.onOpenReview});

  final VoidCallback onOpenReview;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final due = state.dueWords.length;
    final units = state.course.units;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        MascotSays(
          mood: state.progress.completed.isEmpty ? MascotMood.happy : MascotMood.idle,
          text: state.progress.completed.isEmpty
              ? "Hi, I'm Pip! Tap the first circle to start learning ${state.target.name}."
              : Cheers.greeting(DateTime.now().hour),
        ),
        if (due > 0) ...[
          const SizedBox(height: 12),
          _ReviewBanner(count: due, onTap: onOpenReview),
        ],
        for (var i = 0; i < units.length; i++) _UnitPath(unit: units[i], index: i),
      ],
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChunkyCard(
      onTap: onTap,
      border: const Color(0xFFFFD98A),
      fill: const Color(0xFFFFF6DF),
      child: Row(
        children: [
          const Text('🧠', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count ${count == 1 ? 'word' : 'words'} to review',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Palette.ink)),
                const Text('A quick review keeps them fresh.',
                    style: TextStyle(color: Palette.inkSoft, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Palette.sunDark),
        ],
      ),
    );
  }
}

class _UnitPath extends StatelessWidget {
  const _UnitPath({required this.unit, required this.index});

  final Unit unit;
  final int index;

  // Horizontal offsets that make the path wind left and right.
  static const _wave = [0.0, 0.45, 0.7, 0.45, 0.0, -0.45, -0.7, -0.45];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final (color, shade) = Palette.unit(index);
    final done = unit.lessons.where(state.isCompleted).length;
    final next = state.nextLesson;
    final direction = index.isEven ? 1.0 : -1.0;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          // Unit banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
              border: Border(bottom: BorderSide(color: shade, width: 5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UNIT ${index + 1} · $done/${unit.lessons.length}',
                          style: const TextStyle(
                              color: Colors.white70, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(unit.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                    ],
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: Text(unit.emoji, style: const TextStyle(fontSize: 28)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(builder: (context, c) {
            final half = (c.maxWidth - 84) / 2;
            return Stack(
              children: [
                Column(
                  children: [
                    for (var i = 0; i < unit.lessons.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          left: max(0, half + _wave[i % _wave.length] * direction * half * 0.75),
                          right: max(0, half - _wave[i % _wave.length] * direction * half * 0.75),
                          bottom: 14,
                        ),
                        child: _LessonNode(
                          lesson: unit.lessons[i],
                          color: color,
                          shade: shade,
                          isNext: next?.id == unit.lessons[i].id,
                        ),
                      ),
                  ],
                ),
                // Pip keeps the learner company beside the current unit.
                if (unit.lessons.any((l) => l.id == next?.id))
                  Positioned(
                    top: 40,
                    left: direction > 0 ? 4 : null,
                    right: direction > 0 ? null : 4,
                    child: const Mascot(size: 90, mood: MascotMood.happy),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _LessonNode extends StatefulWidget {
  const _LessonNode({required this.lesson, required this.color, required this.shade, required this.isNext});

  final Lesson lesson;
  final Color color;
  final Color shade;
  final bool isNext;

  @override
  State<_LessonNode> createState() => _LessonNodeState();
}

class _LessonNodeState extends State<_LessonNode> with SingleTickerProviderStateMixin {
  bool _down = false;
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  void _syncPulse() {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.isNext && !still) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else if (_pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(_LessonNode old) {
    super.didUpdateWidget(old);
    _syncPulse();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final lesson = widget.lesson;
    final done = state.isCompleted(lesson);
    final open = state.isUnlocked(lesson);
    final face = open ? widget.color : Palette.locked;
    final edge = open ? widget.shade : Palette.lockedDark;
    final icon = !open
        ? Icons.lock_rounded
        : done
            ? (lesson.practice ? Icons.emoji_events_rounded : Icons.check_rounded)
            : lesson.practice
                ? Icons.fitness_center_rounded
                : Icons.star_rounded;

    final node = GestureDetector(
      onTapDown: open ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        HapticFeedback.selectionClick();
        if (open) {
          _showLessonSheet(context, lesson, widget.color, widget.shade);
        } else {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Finish the lessons before this one to unlock it.')));
        }
      },
      child: SizedBox(
        width: 84,
        height: 84,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isNext)
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, _) => Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: widget.color.withValues(alpha: 0.25 + 0.35 * _pulse.value), width: 5),
                  ),
                ),
              ),
            SizedBox(
              width: 68,
              height: 74,
              child: Stack(
                children: [
                  Positioned(top: 6, left: 0, right: 0, height: 66,
                      child: DecoratedBox(decoration: BoxDecoration(color: edge, shape: BoxShape.circle))),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 60),
                    top: _down ? 6 : 0,
                    left: 0,
                    right: 0,
                    height: 66,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: face, shape: BoxShape.circle),
                      child: Icon(icon, size: 34, color: open ? Colors.white : Palette.lockedDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      key: ValueKey('lesson:${lesson.id}'),
      button: true,
      label: '${lesson.title}${done ? ', completed' : open ? '' : ', locked'}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isNext)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Palette.line, width: 2),
              ),
              child: Text(state.progress.completed.isEmpty ? 'START' : 'NEXT',
                  style: TextStyle(color: widget.color, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          node,
        ],
      ),
    );
  }
}

void _showLessonSheet(BuildContext context, Lesson lesson, Color color, Color shade) {
  final state = AppScope.read(context);
  final done = state.isCompleted(lesson);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    // Lets a long word list scroll instead of overflowing on small phones.
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) => Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border(bottom: BorderSide(color: shade, width: 6)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lesson.practice ? 'Unit practice' : lesson.title,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                lesson.practice
                    ? 'Mix of everything from this unit.'
                    : lesson.conceptIds.map((id) => state.target.entry(id).text).join(' · '),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              ChunkyButton(
                label: done ? 'Practice again +5 XP' : 'Start +10 XP',
                color: Colors.white,
                shadow: const Color(0x33000000),
                textColor: color,
                onPressed: () {
                  Navigator.pop(sheet);
                  openLesson(context, lesson);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void openLesson(BuildContext context, Lesson lesson) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)),
  );
}
