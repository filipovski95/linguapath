import 'package:flutter/material.dart';

import '../data/models.dart';
import '../logic/app_state.dart';

/// Picks the language the learner speaks and the one they want to learn.
///
/// Also used from Settings to switch languages, in which case it pops when done.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.fromSettings = false});

  final bool fromSettings;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _native;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    if (widget.fromSettings) _native = s.nativeCode;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final langs = state.content.languages.values.toList();
    final choosingTarget = _native != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: choosingTarget && !widget.fromSettings
            ? BackButton(onPressed: () => setState(() => _native = null))
            : null,
        title: widget.fromSettings ? const Text('Change languages') : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            if (!widget.fromSettings) ...[
              Text('LinguaPath', style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
              const SizedBox(height: 4),
            ],
            Text(
              choosingTarget ? 'What do you want to learn?' : 'Which language do you speak?',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              choosingTarget
                  ? 'You can add more languages any time.'
                  : 'Translations will be shown in this language.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            for (final l in langs)
              if (!choosingTarget || l.code != _native)
                _LanguageTile(
                  language: l,
                  selected: choosingTarget
                      ? l.code == state.targetCode && widget.fromSettings
                      : l.code == _native,
                  onTap: () => _pick(state, l),
                ),
            if (widget.fromSettings && choosingTarget) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _native = null),
                child: Text('I speak: ${state.content.language(_native!).name} (change)'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _pick(AppState state, Language l) {
    if (_native == null) {
      setState(() => _native = l.code);
      return;
    }
    state.setLanguages(native: _native!, target: l.code);
    if (widget.fromSettings) Navigator.of(context).pop();
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.language, required this.onTap, this.selected = false});

  final Language language;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Text(language.flag, style: const TextStyle(fontSize: 32)),
        title: Text(language.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(language.nativeName),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
