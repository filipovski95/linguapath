import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguapath/data/models.dart';
import 'package:linguapath/logic/app_state.dart';
import 'package:linguapath/main.dart';
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

  setUp(() => now = DateTime(2026, 10, 16, 9));

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

  testWidgets('onboarding, then a full first lesson', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340); // a typical phone
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final s = await freshState();
    await tester.pumpWidget(LinguaPathApp(state: s));
    expect(find.text('Which language do you speak?'), findsOneWidget);

    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();
    expect(find.text('What do you want to learn?'), findsOneWidget);
    await tester.tap(find.text('German'));
    await tester.pumpAndSettle();

    expect(find.text('Start learning'), findsOneWidget);
    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();
    expect(find.text('New word'), findsOneWidget);

    // Play through by always choosing the right answer.
    for (var step = 0; step < 80; step++) {
      if (find.text('Lesson complete!').evaluate().isNotEmpty) break;
      final question = find.byWidgetPredicate(
          (w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('answer:'));
      if (question.evaluate().isNotEmpty) {
        final id = (question.evaluate().first.widget.key as ValueKey<String>).value.substring(7);
        await tester.ensureVisible(find.byKey(ValueKey('option:$id')));
        await tester.tap(find.byKey(ValueKey('option:$id')));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Check'));
        await tester.pumpAndSettle();
        expect(find.text('✅ Correct!'), findsOneWidget);
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
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Lesson complete!'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(s.progress.completed, hasLength(1));
    expect(find.text('Up next'), findsOneWidget);
  });
}

