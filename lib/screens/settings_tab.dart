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
        _Header('Languages'),
        ListTile(
          leading: Text(state.target.flag, style: const TextStyle(fontSize: 28)),
          title: Text('Learning ${state.target.name}'),
          subtitle: Text('Translations in ${state.native.name}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const OnboardingScreen(fromSettings: true))),
        ),
        _Header('My courses'),
        for (final l in state.content.languages.values)
          if (l.code != state.nativeCode && state.progressFor(l.code).completed.isNotEmpty)
            ListTile(
              leading: Text(l.flag, style: const TextStyle(fontSize: 24)),
              title: Text(l.name),
              subtitle: Text(_summary(state.progressFor(l.code))),
              trailing: l.code == state.targetCode
                  ? const Icon(Icons.check_circle)
                  : TextButton(
                      onPressed: () => state.setLanguages(native: state.nativeCode!, target: l.code),
                      child: const Text('Switch'),
                    ),
            ),
        _Header('Pronunciation'),
        if (state.target.romanization != null)
          SwitchListTile(
            title: Text('Show ${state.target.romanization}'),
            subtitle: const Text('Pronunciation guide under each word'),
            value: state.showRomanization,
            onChanged: state.setShowRomanization,
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
            onPressed: () => Speech.instance.speak(
                state.target.entry('hello').text, state.target.ttsLocale, rate: state.speechRate),
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
