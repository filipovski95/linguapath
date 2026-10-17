import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'web_media.dart';

/// A voice installed on the phone.
class Voice {
  const Voice({required this.name, required this.locale, this.quality = 0, this.needsInternet = false});

  final String name;
  final String locale;
  final int quality;
  final bool needsInternet;

  /// A friendlier label than the engine's internal voice id.
  String get label {
    final kind = needsInternet ? 'Online voice' : 'Offline voice';
    final q = quality >= 400 ? ' · high quality' : '';
    return '$kind$q (${name.length > 28 ? '${name.substring(0, 28)}…' : name})';
  }
}

/// Pronounces words with the phone's text-to-speech engine.
///
/// Picks the most natural voice available for each language (preferring
/// high-quality voices that work offline), or the one chosen in Settings.
class Speech {
  Speech._();
  static final instance = Speech._();

  final FlutterTts _tts = FlutterTts();
  final Map<String, List<Voice>> _voices = {};
  String? _currentVoice;

  Future<List<Voice>> voicesFor(String locale) async {
    if (_voices.containsKey(locale)) return _voices[locale]!;
    final wanted = locale.toLowerCase();
    final lang = wanted.split('-').first;
    var list = <Voice>[];
    try {
      final raw = await _tts.getVoices as List? ?? [];
      for (final v in raw) {
        final m = Map<String, dynamic>.from(v as Map);
        final loc = (m['locale'] ?? '').toString().replaceAll('_', '-').toLowerCase();
        if (!loc.startsWith(lang)) continue;
        list.add(Voice(
          name: m['name'].toString(),
          locale: m['locale'].toString(),
          quality: int.tryParse('${m['quality'] ?? 0}') ?? 0,
          needsInternet: '${m['network_required']}' == '1' || m['network_required'] == true,
        ));
      }
      int score(Voice v) =>
          (v.locale.replaceAll('_', '-').toLowerCase() == wanted ? 1000 : 0) +
          (v.needsInternet ? 0 : 500) +
          v.quality;
      list.sort((a, b) => score(b).compareTo(score(a)));
    } catch (e) {
      debugPrint('Could not list voices: $e');
      list = [];
    }
    return _voices[locale] = list;
  }

  Future<void> speak(String text, String locale, {double rate = 0.45, String? voiceName}) async {
    final clean = text.replaceAll('…', '').replaceAll('...', '').trim();
    if (clean.isEmpty) return;
    if (kIsWeb && webSpeak(clean, locale, rate, voiceName)) return;
    try {
      await _tts.stop();
      await _tts.setLanguage(locale);
      final voices = await voicesFor(locale);
      final voice = voices.where((v) => v.name == voiceName).firstOrNull ?? voices.firstOrNull;
      if (voice != null && voice.name != _currentVoice) {
        await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
        _currentVoice = voice.name;
      }
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(1.05);
      await _tts.speak(clean);
    } catch (e) {
      debugPrint('Text-to-speech unavailable: $e');
    }
  }
}
