import 'package:flutter/material.dart';

import '../logic/app_state.dart';
import '../logic/speech.dart';
import 'onboarding_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _Header('Course'),
        ListTile(
          leading: Text(state.target.flag, style: const TextStyle(fontSize: 28)),
          title: Text('Learning ${state.target.name}'),
          subtitle: Text(_summary(state.progress)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const OnboardingScreen(fromSettings: true))),
        ),
        ListTile(
          leading: const Icon(Icons.translate),
          title: const Text('Explanations in'),
          subtitle: Text(state.native.name),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pickBase(context, state),
        ),
        _Header('Pronunciation'),
        if (state.target.romanization != null)
          SwitchListTile(
            title: Text('Show ${state.target.romanization}'),
            subtitle: const Text('Pronunciation guide under each word'),
            value: state.showRomanization,
            onChanged: state.setShowRomanization,
          ),
        SwitchListTile(
          title: const Text('Sound effects'),
          subtitle: const Text('Chimes for right and wrong answers'),
          value: state.soundOn,
          onChanged: state.setSoundOn,
        ),
        ListTile(
          leading: const Icon(Icons.record_voice_over_rounded),
          title: const Text('Voice'),
          subtitle: Text(state.voiceName ?? 'Automatic (most natural voice on this phone)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pickVoice(context, state),
        ),
        ListTile(
          title: const Text('Speech speed'),
          subtitle: Slider(
            value: state.speechRate,
            min: 0.2,
            max: 0.8,
            divisions: 6,
            label: state.speechRate.toStringAsFixed(1),
            onChanged: state.setSpeechRate,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Test voice',
            onPressed: () => state.say(state.target.entry('hello').text),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Words are spoken by your phone's text-to-speech voice. If you hear nothing, "
            'install the ${state.target.name} voice in Android Settings › Accessibility › '
            'Text-to-speech.',
            style: theme.textTheme.bodySmall,
          ),
        ),
        _Header('Data'),
        ListTile(
          leading: Icon(Icons.restart_alt, color: theme.colorScheme.error),
          title: const Text('Reset all progress'),
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Reset all progress?'),
                content: const Text('This deletes your XP, streak and learned words for every language.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reset')),
                ],
              ),
            );
            if (ok == true) state.resetProgress();
          },
        ),
        const AboutListTile(
          icon: Icon(Icons.info_outline),
          applicationName: 'LinguaPath',
          applicationVersion: '0.1.0',
          aboutBoxChildren: [
            Text('Learn languages offline. No account, no ads, no data leaves your phone.'),
          ],
        ),
      ],
    );
  }
}

Future<void> _pickVoice(BuildContext context, AppState state) async {
  final voices = await Speech.instance.voicesFor(state.target.ttsLocale);
  if (!context.mounted) return;
  final picked = await showDialog<String>(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text('${state.target.name} voice'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(c, ''),
          child: const Text('Automatic (recommended)', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        if (voices.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No voices found for this language. Install one in Android Settings › '
                'Accessibility › Text-to-speech › Install voice data.'),
          ),
        for (final v in voices)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, v.name),
            child: Row(
              children: [
                Expanded(child: Text(v.label)),
                IconButton(
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  tooltip: 'Preview',
                  onPressed: () => Speech.instance.speak(
                      state.target.entry('hello').text, state.target.ttsLocale,
                      rate: state.speechRate, voiceName: v.name),
                ),
              ],
            ),
          ),
      ],
    ),
  );
  if (picked != null) state.setVoice(picked.isEmpty ? null : picked);
}

Future<void> _pickBase(BuildContext context, AppState state) async {
  final code = await showDialog<String>(
    context: context,
    builder: (c) => SimpleDialog(
      title: const Text('Explanations in'),
      children: [
        for (final l in state.content.languages.values)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, l.code),
            child: Row(
              children: [
                Text(l.flag, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(child: Text(l.nativeName)),
                if (l.code == state.nativeCode) const Icon(Icons.check),
              ],
            ),
          ),
      ],
    ),
  );
  if (code != null) state.setBase(code);
}

String _summary(CourseProgress p) {
  String n(int count, String word) => '$count $word${count == 1 ? '' : 's'}';
  return '${n(p.completed.length, 'lesson')} · ${n(p.cards.length, 'word')} · ${p.xp} XP';
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(text,
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
      );
}
