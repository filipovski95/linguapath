/// A language the app can teach or translate into.
///
/// Each language lives in its own file under `assets/content/languages/`
/// and holds a translation for every concept in `course.json`.
class Language {
  Language({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.ttsLocale,
    required this.entries,
    this.romanization,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    final raw = json['entries'] as Map<String, dynamic>;
    return Language(
      code: json['code'] as String,
      name: json['name'] as String,
      nativeName: json['nativeName'] as String,
      flag: json['flag'] as String,
      ttsLocale: json['ttsLocale'] as String,
      romanization: json['romanization'] as String?,
      entries: raw.map(
        (id, e) => MapEntry(id, Entry.fromJson(e as Map<String, dynamic>)),
      ),
    );
  }

  final String code;
  final String name;
  final String nativeName;
  final String flag;

  /// BCP-47 locale handed to the device's text-to-speech engine.
  final String ttsLocale;

  /// Name of the romanization system shown under the text (e.g. Pinyin), if any.
  final String? romanization;

  final Map<String, Entry> entries;

  Entry entry(String conceptId) =>
      entries[conceptId] ?? Entry(text: '[$conceptId]');
}

/// One concept rendered in one language.
class Entry {
  const Entry({required this.text, this.roman, this.note});

  factory Entry.fromJson(Map<String, dynamic> json) => Entry(
        text: json['text'] as String,
        roman: json['roman'] as String?,
        note: json['note'] as String?,
      );

  final String text;

  /// Romanized pronunciation, e.g. Pinyin for Chinese.
  final String? roman;

  /// Usage hint shown on the learn card.
  final String? note;
}

class Concept {
  const Concept({required this.id, required this.emoji});
  final String id;
  final String emoji;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.conceptIds,
    this.practice = false,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'] as String,
        title: json['title'] as String,
        conceptIds: (json['concepts'] as List).cast<String>(),
        practice: json['practice'] as bool? ?? false,
      );

  final String id;
  final String title;
  final List<String> conceptIds;

  /// A practice lesson reviews the whole unit instead of introducing words.
  final bool practice;
}

class Unit {
  const Unit({
    required this.id,
    required this.title,
    required this.emoji,
    required this.lessons,
  });

  factory Unit.fromJson(Map<String, dynamic> json) => Unit(
        id: json['id'] as String,
        title: json['title'] as String,
        emoji: json['emoji'] as String,
        lessons: (json['lessons'] as List)
            .map((l) => Lesson.fromJson(l as Map<String, dynamic>))
            .toList(),
      );

  final String id;
  final String title;
  final String emoji;
  final List<Lesson> lessons;
}

/// The language-independent curriculum: units, lessons and concepts.
class Course {
  const Course({required this.concepts, required this.units});

  factory Course.fromJson(Map<String, dynamic> json) {
    final concepts = (json['concepts'] as Map<String, dynamic>).map(
      (id, c) => MapEntry(
        id,
        Concept(id: id, emoji: (c as Map<String, dynamic>)['emoji'] as String),
      ),
    );
    return Course(
      concepts: concepts,
      units: (json['units'] as List)
          .map((u) => Unit.fromJson(u as Map<String, dynamic>))
          .toList(),
    );
  }

  final Map<String, Concept> concepts;
  final List<Unit> units;

  List<Lesson> get allLessons => [for (final u in units) ...u.lessons];

  Lesson? lessonById(String id) {
    for (final l in allLessons) {
      if (l.id == id) return l;
    }
    return null;
  }
}

/// Everything loaded from `assets/content/`.
class ContentBundle {
  const ContentBundle({required this.course, required this.languages});

  final Course course;

  /// Keyed by language code, in manifest order.
  final Map<String, Language> languages;

  Language language(String code) => languages[code]!;
}
