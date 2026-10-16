/// Spaced repetition using Leitner boxes.
///
/// A word starts in box 0. Each successful review moves it up a box and pushes
/// the next review further out; a miss sends it back to box 0.
class SrsCard {
  const SrsCard({required this.box, required this.dueDay});

  factory SrsCard.fromJson(Map<String, dynamic> json) =>
      SrsCard(box: json['b'] as int, dueDay: json['d'] as int);

  /// 0 = brand new / just missed, [Srs.maxBox] = well known.
  final int box;

  /// Day number (see [Srs.dayNumber]) when the card is next due.
  final int dueDay;

  Map<String, dynamic> toJson() => {'b': box, 'd': dueDay};
}

enum ReviewGrade { again, good, easy }

class Srs {
  /// Days until the next review for each box.
  static const intervals = [0, 1, 2, 4, 8, 16, 32];
  static int get maxBox => intervals.length - 1;

  static int dayNumber(DateTime t) =>
      DateTime.utc(t.year, t.month, t.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  /// A word just learned in a lesson: review it tomorrow.
  static SrsCard introduce(int today) => SrsCard(box: 1, dueDay: today + 1);

  static SrsCard review(SrsCard card, ReviewGrade grade, int today) {
    final box = switch (grade) {
      ReviewGrade.again => 0,
      ReviewGrade.good => card.box + 1,
      ReviewGrade.easy => card.box + 2,
    }
        .clamp(0, maxBox);
    return SrsCard(box: box, dueDay: today + intervals[box]);
  }

  /// Answering a quiz question about a word nudges it the same way a review does.
  static SrsCard afterQuiz(SrsCard? card, bool correct, int today) {
    if (!correct) return SrsCard(box: 0, dueDay: today);
    return card ?? introduce(today);
  }

  static bool isDue(SrsCard card, int today) => card.dueDay <= today;
}
