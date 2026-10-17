import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saylark/data/models.dart';
import 'package:saylark/logic/app_state.dart';
import 'package:saylark/logic/sounds.dart';
import 'package:saylark/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

ContentBundle loadContent() {
  Map<String, dynamic> read(String p) =>
      jsonDecode(File('assets/content/$p').readAsStringSync()) as Map<String, dynamic>;
  final codes = (read('manifest.json')['languages'] as List).cast<String>();
  return ContentBundle(
    course: Course.fromJson(read('course.json')),
    languages: {for (final c in codes) c: Language.fromJson(read('languages/$c.json'))},
  );
}

void main() {
  final content = loadContent();
  var now = DateTime(2026, 10, 16, 9);

  Future<AppState> freshState([Map<String, Object> saved = const {}]) async {
    SharedPreferences.setMockInitialValues(saved);
    return AppState(content, await SharedPreferences.getInstance(), clock: () => now);
  }

  setUp(() {
    now = DateTime(2026, 10, 16, 9);
    Sounds.instance.forceOff = true;
  });

  group('AppState', () {
    test('only the first lesson starts unlocked', () async {
      final s = await freshState();
      s.setLanguages(native: 'en', target: 'zh');
      final lessons = s.course.allLessons;
      expect(s.isUnlocked(lessons[0]), isTrue);
      expect(s.isUnlocked(lessons[1]), isFalse);
      s.completeLesson(lessons[0], {});
      expect(s.isUnlocked(lessons[1]), isTrue);
      expect(s.progress.xp, AppState.xpPerLesson);
      expect(s.learnedWords, unorderedEquals(lessons[0].conceptIds));
    });

    test('missed words are due right away, others tomorrow', () async {
      final s = await freshState();
      s.setLanguages(native: 'en', target: 'de');
      final l = s.course.allLessons.first;
      s.completeLesson(l, {l.conceptIds.first: false});
      expect(s.dueWords, [l.conceptIds.first]);
      now = now.add(const Duration(days: 1));
      expect(s.dueWords.length, l.conceptIds.length);
    });

    test('streak grows on consecutive days and lapses after a gap', () async {
      final s = await freshState();
      s.setLanguages(native: 'en', target: 'pt');
      final l = s.course.allLessons.first;
      s.completeLesson(l, {});
      expect(s.currentStreak, 1);
      now = now.add(const Duration(days: 1));
      s.completeLesson(l, {});
      expect(s.currentStreak, 2);
      now = now.add(const Duration(days: 3));
      expect(s.currentStreak, 0);
    });

    test('a clock that moves back a day keeps the streak', () async {
      final s = await freshState();
      s.setLanguages(native: 'en', target: 'es');
      final l = s.course.allLessons.first;
      s.completeLesson(l, {});
      now = now.add(const Duration(days: 1));
      s.completeLesson(l, {});
      expect(s.currentStreak, 2);
      now = now.subtract(const Duration(days: 1)); // e.g. flying west over midnight
      s.completeLesson(l, {});
      now = now.add(const Duration(days: 1));
      expect(s.currentStreak, 2);
    });

    test('streak survives midnight but not a skipped day', () async {
      final s = await freshState();
      s.setLanguages(native: 'en', target: 'fr');
      now = DateTime(2026, 10, 16, 23, 59);
      s.completeLesson(s.course.allLessons.first, {});
      now = DateTime(2026, 10, 17, 0, 1);
      expect(s.currentStreak, 1);
      expect(s.practicedToday, isFalse);
      now = DateTime(2026, 10, 19, 0, 1);
      expect(s.currentStreak, 0);
    });

    test('reset clears progress in every course', () async {
      final s = await freshState();
      s.setLanguages(native: 'en', target: 'zh');
      s.completeLesson(s.course.allLessons.first, {});
      s.setTarget('de');
      s.completeLesson(s.course.allLessons.first, {});
      s.resetProgress();
      expect(s.progress.completed, isEmpty);
      expect(s.progressFor('zh').completed, isEmpty);
      expect(s.currentStreak, 0);
      final reloaded = AppState(content, await SharedPreferences.getInstance(), clock: () => now);
      expect(reloaded.progressFor('zh').cards, isEmpty);
      expect(reloaded.targetCode, 'de');
    });

    test('words a newer course dropped are not offered for review', () async {
      final s = await freshState({
        'linguapath_state_v1': jsonEncode({
          'native': 'en',
          'target': 'de',
          'progress': {
            'de': {
              'completed': [],
              'xp': 0,
              'cards': {
                'hello': {'b': 0, 'd': 0},
                'no_longer_taught': {'b': 0, 'd': 0},
              },
            },
          },
        }),
      });
      expect(s.dueWords, ['hello']);
      expect(s.learnedWords, ['hello']);
    });

    test('changing the base to the course language asks for a new course', () async {
      final s = await freshState();
      s.setTarget('de');
      expect(s.isSetUp, isTrue);
      s.setBase('de');
      expect(s.isSetUp, isFalse);
      expect(s.courses.map((l) => l.code), contains('en'));
      expect(s.courses.map((l) => l.code), isNot(contains('de')));
    });

    test('progress survives a restart and is kept per language', () async {
      final s = await freshState();
      s.setLanguages(native: 'en', target: 'zh');
      s.completeLesson(s.course.allLessons.first, {});
      final prefs = await SharedPreferences.getInstance();
      final reloaded = AppState(content, prefs, clock: () => now);
      expect(reloaded.targetCode, 'zh');
      expect(reloaded.progress.completed, hasLength(1));
      reloaded.setLanguages(native: 'en', target: 'de');
      expect(reloaded.progress.completed, isEmpty);
    });
  });

  testWidgets('choosing the course language as the base returns to onboarding', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final s = await freshState();
    s.setLanguages(native: 'en', target: 'fr');
    await tester.pumpWidget(SaylarkApp(state: s));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explanations in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Which language do you want to learn?'), findsOneWidget);
    expect(find.text('French'), findsNothing);
    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();
    expect(s.targetCode, 'en');
    expect(find.text('START'), findsOneWidget);
  });

  testWidgets('switching course from the top bar keeps each course apart', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final s = await freshState();
    s.setLanguages(native: 'en', target: 'zh');
    s.completeLesson(s.course.allLessons.first, {});
    await tester.pumpWidget(SaylarkApp(state: s));
    await tester.tap(find.byTooltip('Change course'));
    await tester.pumpAndSettle();
    expect(find.text('1 lesson done'), findsOneWidget);
    await tester.tap(find.text('Spanish'));
    await tester.pumpAndSettle();
    expect(s.targetCode, 'es');
    expect(find.text('START'), findsOneWidget);
    expect(s.progressFor('zh').completed, hasLength(1));
  });

  testWidgets('onboarding, then a full first lesson', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340); // a typical phone
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final s = await freshState();
    await tester.pumpWidget(SaylarkApp(state: s));
    expect(find.textContaining('Which language do you want to learn?'), findsOneWidget);
    expect(s.nativeCode, 'en');
    expect(find.text('English'), findsNothing, reason: 'the base language is not offered as a course');

    await tester.tap(find.text('German'));
    await tester.pumpAndSettle();
    expect(find.text('START'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('lesson:greetings_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('START +10 XP'));
    await tester.pumpAndSettle();
    expect(find.text('New word'), findsOneWidget);

    // Play through by always choosing the right answer.
    var typedSome = false;
    for (var step = 0; step < 80; step++) {
      if (find.text('Lesson complete!').evaluate().isNotEmpty) break;
      final question = find.byWidgetPredicate(
          (w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('answer:'));
      if (question.evaluate().isNotEmpty) {
        final id = (question.evaluate().first.widget.key as ValueKey<String>).value.substring(7);
        await tester.ensureVisible(find.byKey(ValueKey('option:$id')));
        await tester.tap(find.byKey(ValueKey('option:$id')));
        await tester.pump();
        await tester.tap(find.text('CHECK'));
        await tester.pumpAndSettle();
        expect(find.text('✅ Correct!'), findsOneWidget);
      } else if (find.byKey(const ValueKey('type-answer')).evaluate().isNotEmpty) {
        final typing = find.byWidgetPredicate(
            (w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('type:'));
        final id = (typing.evaluate().first.widget.key as ValueKey<String>).value.substring(5);
        // Lower case and without punctuation still counts.
        final answer = s.target.entry(id).text.toLowerCase().replaceAll(RegExp(r'[!?.,]'), '');
        await tester.enterText(find.byKey(const ValueKey('type-answer')), answer);
        await tester.pump();
        await tester.tap(find.text('CHECK'));
        await tester.pumpAndSettle();
        expect(find.text('✅ Correct!'), findsOneWidget);
        typedSome = true;
      } else if (find.text('Tap the matching pairs').evaluate().isNotEmpty) {
        for (final id in s.course.allLessons.first.conceptIds) {
          if (find.byKey(ValueKey('left:$id')).evaluate().isEmpty) continue;
          await tester.ensureVisible(find.byKey(ValueKey('left:$id')));
          await tester.tap(find.byKey(ValueKey('left:$id')));
          await tester.pump();
          await tester.ensureVisible(find.byKey(ValueKey('right:$id')));
          await tester.tap(find.byKey(ValueKey('right:$id')));
          await tester.pump();
        }
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Lesson complete!'), findsOneWidget);
    expect(typedSome, isTrue, reason: 'lessons include typing exercises');
    expect(find.text('🎯 100%'), findsOneWidget);
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(s.progress.completed, hasLength(1));
    expect(find.text('NEXT'), findsOneWidget);
  });
}
