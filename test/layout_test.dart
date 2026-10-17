import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saylark/logic/app_state.dart';
import 'package:saylark/logic/sounds.dart';
import 'package:saylark/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show loadContent;

/// Plays through screens on a small phone with large text, failing on any
/// layout overflow.
/// Scrolls [f] to the middle of its list, clear of the bottom bar.
Future<void> show(WidgetTester tester, Finder f) async {
  await Scrollable.ensureVisible(tester.element(f), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  final content = loadContent();
  setUp(() => Sounds.instance.forceOff = true);

  for (final (w, h, scale) in [(320.0, 568.0, 1.3), (360.0, 740.0, 2.0), (320.0, 568.0, 2.0)]) {
    for (final code in ['zh', 'mk', 'de']) {
      testWidgets('${w.toInt()}x${h.toInt()} at ${scale}x text, $code', (tester) async {
        tester.view.physicalSize = Size(w * 2, h * 2);
        tester.view.devicePixelRatio = 2;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        SharedPreferences.setMockInitialValues({});
        final s = AppState(content, await SharedPreferences.getInstance());
        s.setLanguages(native: 'en', target: code);
        // Some progress so the stats, review banner and words list have content.
        for (final l in s.course.allLessons.take(3)) {
          s.completeLesson(l, {l.conceptIds.first: false});
        }
        s.progress.xp = 12345;
        await tester.pumpWidget(SaylarkApp(state: s));
        await tester.pumpAndSettle();

        for (final tab in ['Review', 'Words', 'Settings', 'Learn']) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
        }

        final lesson = s.course.allLessons[3];
        await tester.scrollUntilVisible(find.byKey(ValueKey('lesson:${lesson.id}')), 200,
            scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(of: find.byKey(ValueKey('lesson:${lesson.id}')), matching: find.byType(Icon)));
        await tester.pumpAndSettle();
        await show(tester, find.textContaining('+10 XP'));
        await tester.tap(find.textContaining('+10 XP'));
        await tester.pumpAndSettle();

        for (var step = 0; step < 80; step++) {
          if (find.textContaining('complete!').evaluate().isNotEmpty) break;
          final question = find.byWidgetPredicate(
              (w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('answer:'));
          if (question.evaluate().isNotEmpty) {
            final id = (question.evaluate().first.widget.key as ValueKey<String>).value.substring(7);
            // Answer wrong once in a while to show the red feedback panel.
            final wrong = find.byWidgetPredicate((w) =>
                w.key is ValueKey<String> &&
                (w.key as ValueKey<String>).value.startsWith('option:') &&
                (w.key as ValueKey<String>).value != 'option:$id');
            final pick = step % 4 == 0 && wrong.evaluate().isNotEmpty ? wrong.first : find.byKey(ValueKey('option:$id'));
            await tester.scrollUntilVisible(pick, 100,
                scrollable: find.descendant(of: question.first, matching: find.byType(Scrollable)).first);
            await show(tester, pick);
            await tester.tap(pick);
            await tester.pump();
            await tester.tap(find.text('CHECK'));
            await tester.pumpAndSettle();
          } else if (find.byWidgetPredicate((w) =>
              w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('type:')).evaluate().isNotEmpty) {
            // With very large text the field can start below the fold.
            await tester.scrollUntilVisible(find.byKey(const ValueKey('type-answer')), 100,
                scrollable: find.byType(Scrollable).last);
            await tester.enterText(find.byKey(const ValueKey('type-answer')), 'nope');
            await tester.pump();
            // Submit from the keyboard, like most learners do.
            await tester.testTextInput.receiveAction(TextInputAction.done);
            await tester.pumpAndSettle();
          } else if (find.text('Tap the matching pairs').evaluate().isNotEmpty) {
            for (final id in lesson.conceptIds) {
              if (find.byKey(ValueKey('left:$id')).evaluate().isEmpty) continue;
              await show(tester, find.byKey(ValueKey('left:$id')));
              await tester.tap(find.byKey(ValueKey('left:$id')));
              await tester.pump();
              await show(tester, find.byKey(ValueKey('right:$id')));
              await tester.tap(find.byKey(ValueKey('right:$id')));
              await tester.pump();
            }
            await tester.pumpAndSettle();
          }
          final next = find.text('CONTINUE').evaluate().isNotEmpty ? find.text('CONTINUE') : find.text('GOT IT');
          await tester.tap(next);
          await tester.pumpAndSettle();
        }
        expect(find.textContaining('complete!'), findsOneWidget);
        await tester.tap(find.text('CONTINUE'));
        await tester.pumpAndSettle();
      });
    }
  }
}
