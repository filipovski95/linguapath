import 'dart:math';

/// Pip's lines. Kept short and warm; one is picked at random each time.
class Cheers {
  static final _r = Random();
  static String _pick(List<String> l) => l[_r.nextInt(l.length)];

  static String correct() => _pick([
        'Nice!', 'Great job!', 'You got it!', 'Awesome!', 'Perfect!', 'Brilliant!',
        'Spot on!', 'Yes! Keep going!', 'Amazing!', 'Nailed it!',
      ]);

  static String streak(int inARow) => _pick([
        '$inARow in a row! 🔥', "You're on fire! $inARow in a row!", '$inARow correct in a row. Unstoppable!',
      ]);

  static String wrong() => _pick([
        'Almost! Here is the answer:', 'Not quite. You will get it next time!',
        "Don't worry, mistakes help you learn.", 'Close! Remember this one:',
      ]);

  static String newWord() => _pick([
        "Here's a new word!", 'New word for you!', 'Learn this one:', 'Try saying this:',
      ]);

  static String lessonDone(int accuracy) => accuracy == 100
      ? _pick(['Flawless! Every answer right!', 'Perfect lesson! I’m so proud!'])
      : accuracy >= 80
          ? _pick(['Lesson complete! Great work!', 'You did it! Well done!'])
          : _pick(['Lesson complete! Practice makes perfect.', 'Done! Every lesson makes you stronger.']);

  static String greeting(int hour) => hour < 12
      ? _pick(['Good morning! Ready to learn?', 'Morning! A quick lesson?'])
      : hour < 18
          ? _pick(['Hi there! Ready for a lesson?', "Let's learn something new!"])
          : _pick(['Good evening! One lesson before bed?', 'Evening practice keeps your streak alive!']);
}
