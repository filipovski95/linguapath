import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saylark/data/models.dart';

/// Guards the content files, so a new language can't ship with gaps.
void main() {
  final root = Directory('assets/content');
  Map<String, dynamic> read(String path) =>
      jsonDecode(File('${root.path}/$path').readAsStringSync()) as Map<String, dynamic>;

  final course = Course.fromJson(read('course.json'));
  final codes = (read('manifest.json')['languages'] as List).cast<String>();

  test('every lesson only uses known concepts', () {
    for (final lesson in course.allLessons) {
      for (final id in lesson.conceptIds) {
        expect(course.concepts, contains(id), reason: '${lesson.id} uses unknown "$id"');
      }
    }
  });

  test('lesson ids are unique', () {
    final ids = course.allLessons.map((l) => l.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  for (final code in codes) {
    group('language $code', () {
      final lang = Language.fromJson(read('languages/$code.json'));

      test('file code matches manifest', () => expect(lang.code, code));

      test('translates every concept', () {
        final missing = course.concepts.keys.where((id) => !lang.entries.containsKey(id));
        expect(missing, isEmpty, reason: 'Missing in $code.json: ${missing.join(', ')}');
      });

      test('has no entries for unknown concepts', () {
        final extra = lang.entries.keys.where((id) => !course.concepts.containsKey(id));
        expect(extra, isEmpty, reason: 'Unknown ids in $code.json: ${extra.join(', ')}');
      });

      test('no two concepts share the same text', () {
        // Two identical answers would make quiz and match questions ambiguous.
        final seen = <String, String>{};
        for (final e in lang.entries.entries) {
          final t = e.value.text.toLowerCase();
          expect(seen[t], isNull, reason: '$code: "${e.key}" and "${seen[t]}" are both "$t"');
          seen[t] = e.key;
        }
      });

      test('has no empty text', () {
        for (final e in lang.entries.entries) {
          expect(e.value.text.trim(), isNotEmpty, reason: '$code/${e.key}');
        }
      });

      if (lang.romanization != null) {
        test('every entry has ${lang.romanization}', () {
          for (final e in lang.entries.entries) {
            expect(e.value.roman, isNotNull, reason: '$code/${e.key}');
          }
        });
      }
    });
  }
}
