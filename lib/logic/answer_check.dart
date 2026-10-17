import '../data/models.dart';

/// Decides whether a typed answer matches a word, forgiving the things a
/// beginner on a phone keyboard shouldn't be marked wrong for: capitals,
/// punctuation, spacing, a missing article, and missing accents or tone marks.
class AnswerCheck {
  static const _accents = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a', 'ǎ': 'a',
    'ç': 'c', 'č': 'c', 'ć': 'c',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ě': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i', 'ǐ': 'i',
    'ñ': 'n', 'ń': 'n',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ō': 'o', 'ǒ': 'o', 'œ': 'oe',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'ǔ': 'u', 'ǖ': 'u', 'ǘ': 'u', 'ǚ': 'u', 'ǜ': 'u',
    'ý': 'y', 'ÿ': 'y',
    'š': 's', 'ś': 's', 'ž': 'z', 'ź': 'z', 'đ': 'd', 'ǵ': 'g', 'ḱ': 'k', 'ß': 'ss', 'æ': 'ae',
  };

  static const _articles = {
    'the', 'a', 'an', 'to', // English, incl. "to" before verbs
    'der', 'die', 'das', 'ein', 'eine', // German
    'le', 'la', 'les', 'un', 'une', // French
    'el', 'los', 'las', 'una', // Spanish
    'o', 'os', 'as', 'um', 'uma', // Portuguese
  };

  /// Lower-cased, without punctuation, articles or spaces; accents kept.
  static String _bare(String s) {
    var t = s.toLowerCase().replaceAll('’', "'");
    t = t.replaceAll(RegExp(r"^l'"), '');
    t = t.replaceAll(RegExp(r"[.,!?¿¡…:;\-'。，？！…]"), ' ');
    final words = t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    while (words.length > 1 && _articles.contains(words.first)) {
      words.removeAt(0);
    }
    return words.join();
  }

  static String _plain(String s) => _bare(s).split('').map((c) => _accents[c] ?? c).join();

  /// The accepted spellings: each "A / B" alternative, and the romanization.
  static List<String> _forms(Entry e) => [
        ...e.text.split('/'),
        if (e.roman != null) ...e.roman!.split('/'),
      ];

  static final _han = RegExp(r'[\u4e00-\u9fff]');
  static final _cyrillic = RegExp(r'[\u0400-\u04ff]');

  /// How people type a romanization on a plain keyboard: Pinyin with tone
  /// numbers and "v" for "ü" (ni3 hao3, nv3), Macedonian Latin with
  /// digraphs instead of háčeks (kuche, kjerka).
  static String _keyboard(String plain, Entry e) {
    if (_han.hasMatch(e.text)) return plain.replaceAll(RegExp('[1-5]'), '').replaceAll('v', 'u');
    if (_cyrillic.hasMatch(e.text)) {
      return plain
          .replaceAll('dzh', 'dz')
          .replaceAll(RegExp('(?<=[kg])j'), '')
          .replaceAll(RegExp('(?<=[csz])h'), '');
    }
    return plain;
  }

  /// True if [typed] is an acceptable answer for [e].
  static bool matches(String typed, Entry e) {
    final t = _plain(typed);
    if (t.isEmpty) return false;
    if (_forms(e).any((f) => _plain(f) == t)) return true;
    // Only the romanization is typed with a plain keyboard's shortcuts.
    if (e.roman == null) return false;
    final k = _keyboard(t, e);
    return e.roman!.split('/').any((f) => _keyboard(_plain(f), e) == k);
  }

  /// True if [typed] matches with accents exactly right (or none were needed).
  static bool exact(String typed, Entry e) {
    final t = _bare(typed);
    return _forms(e).any((f) => _bare(f) == t);
  }
}
