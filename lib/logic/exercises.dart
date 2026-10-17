import 'dart:math';

import '../data/models.dart';

sealed class Exercise {
  const Exercise();
}

/// Shows a new word with its translation and pronunciation.
class LearnExercise extends Exercise {
  const LearnExercise(this.conceptId);
  final String conceptId;
}

enum ChoiceMode {
  /// See the word in the language being learned, pick its meaning.
  targetToNative,

  /// See the meaning, pick the word in the language being learned.
  nativeToTarget,

  /// Hear the word, pick its meaning.
  listen,
}

class ChoiceExercise extends Exercise {
  const ChoiceExercise(this.conceptId, this.mode, this.options);
  final String conceptId;
  final ChoiceMode mode;

  /// Concept ids, the correct one included, in display order.
  final List<String> options;
}

/// Type the word in the language being learned, after seeing its meaning
/// or (with [listen]) hearing it.
class TypeExercise extends Exercise {
  const TypeExercise(this.conceptId, {this.listen = false});
  final String conceptId;
  final bool listen;
}

/// Tap the matching pairs between the two languages.
class MatchExercise extends Exercise {
  const MatchExercise(this.conceptIds);
  final List<String> conceptIds;
}

/// Builds the sequence of exercises for a lesson.
class ExerciseBuilder {
  ExerciseBuilder({
    required this.course,
    required this.target,
    required this.native,
    this.typing = true,
    Random? random,
  }) : _random = random ?? Random();

  final Course course;
  final Language target;
  final Language native;

  /// Whether to include exercises that need the keyboard.
  final bool typing;
  final Random _random;

  static const optionCount = 4;
  static const practiceLength = 10;

  List<Exercise> forLesson(Lesson lesson) {
    final ids = lesson.conceptIds;
    if (lesson.practice) {
      final picked = [...ids]..shuffle(_random);
      final quiz = [
        for (final id in picked.take(practiceLength)) _randomExercise(id, ids),
      ];
      return [...quiz, MatchExercise(picked.take(5).toList())];
    }
    final quiz = <Exercise>[
      for (final id in ids) ...[
        ChoiceExercise(id, ChoiceMode.targetToNative,
            _options(id, ids, native)),
        ChoiceExercise(id, ChoiceMode.nativeToTarget,
            _options(id, ids, target)),
      ],
      for (final id in [...ids]..shuffle(_random))
        if (_random.nextBool())
          ChoiceExercise(id, ChoiceMode.listen, _options(id, ids, native)),
    ]..shuffle(_random);
    // Typing comes last, once the words have been seen a few times.
    final typed = [...ids]..shuffle(_random);
    final typeQuiz = <Exercise>[
      if (typing && typed.isNotEmpty) TypeExercise(typed[0]),
      if (typing && typed.length > 1) TypeExercise(typed[1], listen: true),
    ];
    return [
      for (final id in ids) LearnExercise(id),
      ...quiz,
      if (ids.length >= 3) MatchExercise(ids.take(5).toList()),
      ...typeQuiz,
    ];
  }

  /// A short quiz over words the learner already knows (used by Review).
  List<Exercise> forWords(List<String> ids) {
    final picked = [...ids]..shuffle(_random);
    return [for (final id in picked) _randomExercise(id, ids)];
  }

  /// Mostly multiple choice, with about one in four typed when typing is on.
  Exercise _randomExercise(String id, List<String> pool) {
    if (typing && _random.nextInt(4) == 0) return TypeExercise(id, listen: _random.nextBool());
    return _randomChoice(id, pool);
  }

  ChoiceExercise _randomChoice(String id, List<String> pool) {
    final mode = ChoiceMode.values[_random.nextInt(ChoiceMode.values.length)];
    final shownIn = mode == ChoiceMode.nativeToTarget ? target : native;
    return ChoiceExercise(id, mode, _options(id, pool, shownIn));
  }

  /// The correct answer plus distractors, preferring words from [pool]
  /// and never two options that look or sound the same in [shownIn].
  List<String> _options(String id, List<String> pool, Language shownIn) {
    String key(String c) => shownIn.entry(c).text.toLowerCase();
    String sound(String c) => target.entry(c).roman ?? target.entry(c).text;
    final seen = {key(id)};
    final sounds = {sound(id)};
    final chosen = [id];
    final candidates = [
      ...([...pool]..shuffle(_random)),
      ...(course.concepts.keys.toList()..shuffle(_random)),
    ];
    for (final c in candidates) {
      if (chosen.length == optionCount) break;
      if (chosen.contains(c) || seen.contains(key(c))) continue;
      if (sounds.contains(sound(c))) continue;
      chosen.add(c);
      seen.add(key(c));
      sounds.add(sound(c));
    }
    return chosen..shuffle(_random);
  }
}
