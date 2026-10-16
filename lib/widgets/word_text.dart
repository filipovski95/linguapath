import 'package:flutter/material.dart';

import '../data/models.dart';
import '../logic/app_state.dart';
import '../logic/speech.dart';

/// A word in the language being learned, with its romanization when enabled.
class WordText extends StatelessWidget {
  const WordText({super.key, required this.entry, this.size = 28, this.center = true});

  final Entry entry;
  final double size;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final align = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(entry.text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: TextStyle(fontSize: size, fontWeight: FontWeight.w700)),
        if (state.showRomanization && entry.roman != null)
          Text(entry.roman!,
              textAlign: center ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                  fontSize: size * 0.6, color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

/// Plays a word in the target language.
class SpeakButton extends StatelessWidget {
  const SpeakButton({super.key, required this.text, this.size = 28, this.filled = false});

  final String text;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    void play() {
      final s = AppScope.read(context);
      Speech.instance.speak(text, s.target.ttsLocale, rate: s.speechRate);
    }

    final icon = Icon(Icons.volume_up_rounded, size: size);
    return filled
        ? IconButton.filled(onPressed: play, icon: icon, tooltip: 'Listen')
        : IconButton(onPressed: play, icon: icon, tooltip: 'Listen');
  }
}
