import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:saylark/data/models.dart';
import 'package:saylark/logic/exercises.dart';

void main() {
  Map<String, dynamic> read(String path) =>
      jsonDecode(File('assets/content/$path').readAsStringSync()) as Map<String, dynamic>;
  final course = Course.fromJson(read('course.json'));
  final zh = Language.fromJson(read('languages/zh.json'));
  final en = Language.fromJson(read('languages/en.json'));
  final de = Language.fromJson(read('languages/de.json'));
  final mk = Language.fromJson(read('languages/mk.json'));
  final fr = Language.fromJson(read('languages/fr.json'));
  final es = Language.fromJson(read('languages/es.json'));

  for (final (target, native) in [(zh, en), (de, zh), (en, de), (mk, en), (fr, mk), (es, fr)]) {
    test('${target.code} from ${native.code}: every lesson builds valid exercises', () {
      for (var seed = 0; seed < 20; seed++) {
        final b = ExerciseBuilder(course: course, target: target, native: native, random: Random(seed));
        for (final lesson in course.allLessons) {
          final ex = b.forLesson(lesson);
          expect(ex, isNotEmpty);
          for (final e in ex.whereType<ChoiceExercise>()) {
            expect(e.options, contains(e.conceptId));
            expect(e.options.length, ExerciseBuilder.optionCount);
            expect(e.options.toSet().length, e.options.length);
            final shown = e.mode == ChoiceMode.nativeToTarget ? target : native;
            final texts = e.options.map((id) => shown.entry(id).text.toLowerCase()).toSet();
            expect(texts.length, e.options.length, reason: 'two options look the same: ${e.options}');
            if (e.mode == ChoiceMode.listen) {
              final sounds = e.options.map((id) => target.entry(id).roman ?? target.entry(id).text).toSet();
              expect(sounds.length, e.options.length, reason: 'two options sound the same');
            }
          }
        }
      }
    });
  }

  test('a normal lesson starts by teaching every word', () {
    final lesson = course.allLessons.firstWhere((l) => !l.practice);
    final ex = ExerciseBuilder(course: course, target: zh, native: en, random: Random(1)).forLesson(lesson);
    final learn = ex.takeWhile((e) => e is LearnExercise).cast<LearnExercise>();
    expect(learn.map((e) => e.conceptId), lesson.conceptIds);
  });

  test('he and she never appear together in a Chinese listening question', () {
    final b = ExerciseBuilder(course: course, target: zh, native: en, random: Random(3));
    final people = course.units.firstWhere((u) => u.id == 'people');
    for (var i = 0; i < 50; i++) {
      for (final e in b.forLesson(people.lessons.last).whereType<ChoiceExercise>()) {
        if (e.mode == ChoiceMode.listen) {
          expect(e.options.contains('he') && e.options.contains('she'), isFalse);
        }
      }
    }
  });
}
