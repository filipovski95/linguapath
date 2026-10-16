import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

/// Loads the bundled course. Everything ships inside the app, so it works offline.
class ContentRepository {
  ContentRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  static const _root = 'assets/content';

  Future<ContentBundle> load() async {
    final manifest = await _json('$_root/manifest.json');
    final course = Course.fromJson(await _json('$_root/course.json'));
    final languages = <String, Language>{};
    for (final code in (manifest['languages'] as List).cast<String>()) {
      languages[code] =
          Language.fromJson(await _json('$_root/languages/$code.json'));
    }
    return ContentBundle(course: course, languages: languages);
  }

  Future<Map<String, dynamic>> _json(String path) async =>
      jsonDecode(await _bundle.loadString(path)) as Map<String, dynamic>;
}
