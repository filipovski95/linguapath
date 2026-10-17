# Saylark

An offline-first language learning app for Android, built with Flutter.
It has **Chinese (Mandarin), English, German, Portuguese (Brazil), Spanish, French and Macedonian**, and a learner can study any of them from any of the others (for example German from Chinese).

## What's in the MVP

- **Onboarding**: pick the language you speak and the one you want to learn.
- **Course path**: 8 units, 29 lessons, 93 words and phrases (greetings, numbers, food, family, colors, travel, time, everyday verbs). Lessons unlock in order; each unit ends with a practice round.
- **Lessons**: new-word cards (emoji, word, Pinyin for Chinese, pronunciation, usage tips), then a shuffled quiz: meaning → word, word → meaning, listening, and match-the-pairs. Wrong answers come back at the end.
- **Review**: spaced-repetition flashcards (Leitner boxes: 1, 2, 4, 8, 16, 32 days). Missed quiz answers are due again the same day.
- **Words**: a searchable phrasebook with pronunciation and a memory-strength indicator.
- **Motivation**: XP, daily streak, per-language progress.
- **Settings**: switch languages (progress is kept per language), Pinyin on/off, speech speed, reset.
- **Offline and private**: all content ships in the app; progress is stored only on the phone; no account, no ads, no tracking. Pronunciation uses the phone's built-in text-to-speech voices.

## Project layout

```
assets/content/
  manifest.json          list of languages the app loads
  course.json            units, lessons and concept ids (language independent)
  languages/<code>.json  one file per language: a translation of every concept
lib/
  data/                  models + asset loading
  logic/                 app state & persistence, spaced repetition, exercise builder, speech
  screens/               onboarding, learn, lesson/quiz, review, words, settings
  widgets/               shared word + speaker widgets
test/                    content checks, SRS, exercise builder, full lesson walk-through
docs/                    publishing guide, privacy policy
store/                   Play Store icon, feature graphic, screenshots, listing text
```

## Adding a language

Content is keyed by **concept id** (`hello`, `water`, `to_eat`…), not by language pair, so one new file makes the language available to and from every other language.

1. Copy `assets/content/languages/en.json` to `assets/content/languages/<code>.json` (e.g. `es.json`).
2. Set `code`, `name`, `nativeName`, `flag` and `ttsLocale` (e.g. `es-ES`). Add `"romanization": "Romaji"` (or similar) if the script needs a reading aid, and give every entry a `roman` value.
3. Translate every `text`. Optional `note` adds a usage tip on the learning card.
4. Add the code to `assets/content/manifest.json`.
5. Run `flutter test`. The content tests fail if any concept is missing, empty, or unknown.

Adding words or lessons works the same way: add the concept to `course.json` (with an emoji and its lesson), then add it to every language file.

## Running it

Requires the Flutter SDK (3.47 or newer) and, for Android, Android Studio (which installs the Android SDK).

```bash
flutter pub get
flutter test                 # 35 tests
flutter run                  # on a connected phone or emulator
flutter run -d chrome        # quick preview in a browser
flutter build appbundle      # release .aab for Google Play (see docs/PUBLISHING.md)
```

The repo also has a GitHub Actions workflow (`.github/workflows/build.yml`) that runs the tests and builds the release bundle on every push, so you can build without installing Android Studio.

## Ideas for next versions

- More languages (Spanish, French, Japanese, Arabic, Hindi…) and more units per language.
- Sentence-building exercises (tap words in order) and typing answers.
- Recorded native audio instead of text-to-speech.
- App interface translated into each language (the UI is English for now).
- Daily reminder notifications, achievements, cloud backup.
- Chinese character stroke-order practice.
