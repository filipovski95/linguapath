import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';
import 'sounds.dart';
import 'speech.dart';
import 'srs.dart';

/// Progress in one target language.
class CourseProgress {
  CourseProgress({Set<String>? completed, Map<String, SrsCard>? cards, this.xp = 0})
      : completed = completed ?? {},
        cards = cards ?? {};

  factory CourseProgress.fromJson(Map<String, dynamic> json) => CourseProgress(
        completed: (json['completed'] as List? ?? []).cast<String>().toSet(),
        xp: json['xp'] as int? ?? 0,
        cards: (json['cards'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, SrsCard.fromJson(v as Map<String, dynamic>)),
        ),
      );

  final Set<String> completed;
  final Map<String, SrsCard> cards;
  int xp;

  Map<String, dynamic> toJson() => {
        'completed': completed.toList(),
        'xp': xp,
        'cards': cards.map((k, v) => MapEntry(k, v.toJson())),
      };
}

/// App-wide state, saved on the device after every change.
class AppState extends ChangeNotifier {
  AppState(this.content, this._prefs, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _load();
  }

  static const _key = 'linguapath_state_v1';
  static const xpPerLesson = 10;
  static const xpPerReview = 1;

  final ContentBundle content;
  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  /// Language the app explains things in. English unless changed in Settings.
  static const defaultBase = 'en';
  String nativeCode = defaultBase;

  /// The one course being learned right now.
  String? targetCode;
  bool showRomanization = true;
  bool soundOn = true;

  /// Include exercises where the learner types the answer.
  bool typingOn = true;

  /// Voice chosen in Settings, per course language (empty = automatic).
  final Map<String, String> voices = {};
  double speechRate = 0.45;
  int streak = 0;
  int? _lastActiveDay;
  final Map<String, CourseProgress> _progress = {};

  bool get isSetUp => targetCode != null;
  Language get native => content.language(nativeCode);

  /// Languages that can be learned from the current base language.
  List<Language> get courses =>
      content.languages.values.where((l) => l.code != nativeCode).toList();
  Language get target => content.language(targetCode!);
  Course get course => content.course;
  int get today => Srs.dayNumber(_clock());

  CourseProgress get progress =>
      _progress.putIfAbsent(targetCode!, CourseProgress.new);

  CourseProgress progressFor(String code) =>
      _progress[code] ?? CourseProgress();

  /// Streak shown to the user: it lapses if a whole day was missed.
  int get currentStreak {
    final last = _lastActiveDay;
    if (last == null || today - last > 1) return 0;
    return streak;
  }

  bool get practicedToday => _lastActiveDay == today;

  // ---- Lessons ----

  bool isCompleted(Lesson lesson) => progress.completed.contains(lesson.id);

  /// Lessons unlock in order; the first one is always open.
  bool isUnlocked(Lesson lesson) {
    final all = course.allLessons;
    final i = all.indexWhere((l) => l.id == lesson.id);
    return i <= 0 || isCompleted(all[i - 1]) || isCompleted(lesson);
  }

  Lesson? get nextLesson {
    for (final l in course.allLessons) {
      if (!isCompleted(l)) return l;
    }
    return null;
  }

  /// Records a finished lesson. [answers] maps concept id to whether every
  /// question about it was answered right the first time.
  void completeLesson(Lesson lesson, Map<String, bool> answers) {
    final p = progress;
    final firstTime = p.completed.add(lesson.id);
    p.xp += firstTime ? xpPerLesson : xpPerLesson ~/ 2;
    for (final id in lesson.conceptIds) {
      final correct = answers[id];
      if (correct == null && p.cards.containsKey(id)) continue;
      p.cards[id] = Srs.afterQuiz(p.cards[id], correct ?? true, today);
    }
    _touch();
  }

  // ---- Review ----

  /// Words with a review card, skipping any a newer course no longer has.
  List<String> get learnedWords => progress.cards.keys.where(course.concepts.containsKey).toList();

  List<String> get dueWords {
    final t = today;
    final due = progress.cards.entries
        .where((e) => course.concepts.containsKey(e.key) && Srs.isDue(e.value, t))
        .map((e) => e.key)
        .toList();
    due.sort((a, b) => progress.cards[a]!.dueDay.compareTo(progress.cards[b]!.dueDay));
    return due;
  }

  /// A handful of learned words for extra practice when nothing is due.
  List<String> practiceWords(int count) =>
      (learnedWords..shuffle(Random())).take(count).toList();

  void review(String conceptId, ReviewGrade grade) {
    final card = progress.cards[conceptId] ?? Srs.introduce(today);
    progress.cards[conceptId] = Srs.review(card, grade, today);
    // "Again" keeps the card due, so it earns nothing; otherwise XP could be farmed.
    if (grade != ReviewGrade.again) progress.xp += xpPerReview;
    _touch();
  }

  // ---- Settings ----

  void setLanguages({required String native, required String target}) {
    nativeCode = native;
    targetCode = target;
    _save();
  }

  /// Switches to another course; progress in each course is kept separately.
  void setTarget(String code) {
    targetCode = code;
    _save();
  }

  /// Changes the base language. If it is the language being learned,
  /// the learner is asked to pick a new course.
  void setBase(String code) {
    nativeCode = code;
    if (targetCode == code) targetCode = null;
    _save();
  }

  void setShowRomanization(bool value) {
    showRomanization = value;
    _save();
  }

  String? get voiceName => voices[targetCode];

  /// Says [text] in the course language with the chosen voice.
  void say(String text, {double slower = 1}) => Speech.instance
      .speak(text, target.ttsLocale, rate: speechRate * slower, voiceName: voiceName);

  void setVoice(String? name) {
    if (name == null) {
      voices.remove(targetCode);
    } else {
      voices[targetCode!] = name;
    }
    _save();
  }

  void setSoundOn(bool value) {
    soundOn = value;
    Sounds.instance.enabled = value;
    _save();
  }

  void setTypingOn(bool value) {
    typingOn = value;
    _save();
  }

  void setSpeechRate(double value) {
    speechRate = value;
    _save();
  }

  void resetProgress() {
    _progress.clear();
    streak = 0;
    _lastActiveDay = null;
    _save();
  }

  // ---- Persistence ----

  void _touch() {
    final t = today;
    final last = _lastActiveDay;
    // A clock that moved back (flying west, a manual change) must not reset the streak.
    if (last == null || t > last) {
      streak = (last != null && t - last == 1) ? streak + 1 : 1;
      _lastActiveDay = t;
    }
    _save();
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final n = j['native'] as String?;
      final t = j['target'] as String?;
      // Ignore saved languages that a newer build no longer ships.
      if (n != null && content.languages.containsKey(n)) nativeCode = n;
      if (t != null && t != nativeCode && content.languages.containsKey(t)) targetCode = t;
      showRomanization = j['showRoman'] as bool? ?? true;
      soundOn = j['sound'] as bool? ?? true;
      Sounds.instance.enabled = soundOn;
      typingOn = j['typing'] as bool? ?? true;
      (j['voices'] as Map<String, dynamic>? ?? {}).forEach((k, v) => voices[k] = v as String);
      speechRate = (j['speechRate'] as num?)?.toDouble() ?? speechRate;
      streak = j['streak'] as int? ?? 0;
      _lastActiveDay = j['lastDay'] as int?;
      final p = j['progress'] as Map<String, dynamic>? ?? {};
      p.forEach((code, v) =>
          _progress[code] = CourseProgress.fromJson(v as Map<String, dynamic>));
    } catch (e) {
      debugPrint('Could not read saved progress: $e');
    }
  }

  void _save() {
    final j = {
      'native': nativeCode,
      'target': targetCode,
      'showRoman': showRomanization,
      'sound': soundOn,
      'typing': typingOn,
      'voices': voices,
      'speechRate': speechRate,
      'streak': streak,
      'lastDay': _lastActiveDay,
      'progress': _progress.map((k, v) => MapEntry(k, v.toJson())),
    };
    _prefs.setString(_key, jsonEncode(j));
    notifyListeners();
  }
}

/// Makes [AppState] available to every screen.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Reads the state without rebuilding when it changes (for callbacks).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
