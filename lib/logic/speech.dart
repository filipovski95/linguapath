import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Pronounces words with the device's built-in text-to-speech engine.
///
/// Android ships offline voices for most languages; if a voice is missing the
/// app keeps working and the speaker buttons simply stay silent.
class Speech {
  Speech._();
  static final instance = Speech._();

  final FlutterTts _tts = FlutterTts();

  Future<void> speak(String text, String locale, {double rate = 0.45}) async {
    final clean = text.replaceAll('…', '').replaceAll('...', '').trim();
    if (clean.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(rate);
      await _tts.speak(clean);
    } catch (e) {
      debugPrint('Text-to-speech unavailable: $e');
    }
  }

  Future<bool> isAvailable(String locale) async {
    try {
      final result = await _tts.isLanguageAvailable(locale);
      return result == true || result == 1;
    } catch (_) {
      return false;
    }
  }
}
