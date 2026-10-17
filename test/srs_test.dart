import 'package:flutter_test/flutter_test.dart';
import 'package:saylark/logic/srs.dart';

void main() {
  const today = 20000;

  test('a new word is due tomorrow', () {
    final c = Srs.introduce(today);
    expect(Srs.isDue(c, today), isFalse);
    expect(Srs.isDue(c, today + 1), isTrue);
  });

  test('good moves up one box and spaces the review out', () {
    final c = Srs.review(const SrsCard(box: 2, dueDay: today), ReviewGrade.good, today);
    expect(c.box, 3);
    expect(c.dueDay, today + Srs.intervals[3]);
  });

  test('again sends the word back to the start, due today', () {
    final c = Srs.review(const SrsCard(box: 5, dueDay: today), ReviewGrade.again, today);
    expect(c.box, 0);
    expect(Srs.isDue(c, today), isTrue);
  });

  test('easy never goes past the top box', () {
    final c = Srs.review(SrsCard(box: Srs.maxBox, dueDay: today), ReviewGrade.easy, today);
    expect(c.box, Srs.maxBox);
  });

  test('a quiz miss resets a known word', () {
    final c = Srs.afterQuiz(const SrsCard(box: 4, dueDay: today + 8), false, today);
    expect(c.box, 0);
  });

  test('day numbers ignore the time of day', () {
    expect(Srs.dayNumber(DateTime(2026, 1, 2, 0, 1)), Srs.dayNumber(DateTime(2026, 1, 2, 23, 59)));
    expect(Srs.dayNumber(DateTime(2026, 1, 3)) - Srs.dayNumber(DateTime(2026, 1, 2)), 1);
  });
}
