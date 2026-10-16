import 'package:flutter/material.dart';

import '../logic/app_state.dart';
import '../logic/srs.dart';
import '../widgets/word_text.dart';

/// Phrasebook of every word in the course, grouped by unit.
class WordsTab extends StatefulWidget {
  const WordsTab({super.key});

  @override
  State<WordsTab> createState() => _WordsTabState();
}

class _WordsTabState extends State<WordsTab> {
  String _query = '';
  bool _learnedOnly = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final cards = state.progress.cards;
    final q = _query.trim().toLowerCase();
    final theme = Theme.of(context);

    bool matches(String id) {
      if (_learnedOnly && !cards.containsKey(id)) return false;
      if (q.isEmpty) return true;
      final t = state.target.entry(id);
      return t.text.toLowerCase().contains(q) ||
          (t.roman?.toLowerCase().contains(q) ?? false) ||
          state.native.entry(id).text.toLowerCase().contains(q);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search words',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FilterChip(
              label: Text('Learned (${cards.length})'),
              selected: _learnedOnly,
              onSelected: (v) => setState(() => _learnedOnly = v),
            ),
          ],
        ),
        for (final unit in state.course.units) ...[
          if (unit.lessons.last.conceptIds.any(matches)) ...[
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 4),
              child: Text('${unit.emoji} ${unit.title}', style: theme.textTheme.titleMedium),
            ),
            for (final id in unit.lessons.last.conceptIds.where(matches))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(state.course.concepts[id]?.emoji ?? '',
                    style: const TextStyle(fontSize: 26)),
                title: WordText(entry: state.target.entry(id), size: 18, center: false),
                subtitle: Text(state.native.entry(id).text),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (cards[id] != null) _Strength(box: cards[id]!.box),
                    SpeakButton(text: state.target.entry(id).text, size: 24),
                  ],
                ),
              ),
          ],
        ],
      ],
    );
  }
}

/// How well a word is known, as filled dots.
class _Strength extends StatelessWidget {
  const _Strength({required this.box});

  final int box;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const dots = 3;
    final filled = (box / Srs.maxBox * dots).ceil().clamp(0, dots);
    return Tooltip(
      message: 'Memory strength',
      child: Row(
        children: [
          for (var i = 0; i < dots; i++)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? scheme.primary : scheme.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }
}
