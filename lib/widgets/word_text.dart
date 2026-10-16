import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../logic/app_state.dart';
import '../ui/palette.dart';

/// A word in the language being learned, with its romanization when enabled.
class WordText extends StatelessWidget {
  const WordText({super.key, required this.entry, this.size = 28, this.center = true, this.color});

  final Entry entry;
  final double size;
  final bool center;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final align = center ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(entry.text,
            textAlign: align,
            style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color, height: 1.15)),
        if (state.showRomanization && entry.roman != null)
          Text(entry.roman!,
              textAlign: align,
              style: TextStyle(
                  fontSize: size * 0.58,
                  fontWeight: FontWeight.w700,
                  color: color?.withValues(alpha: 0.7) ?? theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

/// A round, chunky "play" button that says a word in the course language.
class SpeakButton extends StatefulWidget {
  const SpeakButton({super.key, required this.text, this.size = 48, this.slow = false, this.filled = true});

  final String text;
  final double size;
  final bool slow;
  final bool filled;

  @override
  State<SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends State<SpeakButton> {
  bool _down = false;

  void _play() {
    HapticFeedback.selectionClick();
    AppScope.read(context).say(widget.text, slower: widget.slow ? 0.55 : 1);
  }

  @override
  Widget build(BuildContext context) {
    const face = Color(0xFF1CB0F6);
    const edge = Color(0xFF1290CC);
    final s = widget.size;
    if (!widget.filled) {
      return IconButton(
        onPressed: _play,
        tooltip: widget.slow ? 'Play slowly' : 'Listen',
        icon: Icon(widget.slow ? Icons.slow_motion_video_rounded : Icons.volume_up_rounded,
            color: face, size: s * 0.55),
      );
    }
    return Semantics(
      button: true,
      label: widget.slow ? 'Play slowly' : 'Listen',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          _play();
        },
        child: SizedBox(
          width: s,
          height: s + 4,
          child: Stack(
            children: [
              Positioned(top: 4, left: 0, right: 0, height: s,
                  child: DecoratedBox(decoration: BoxDecoration(color: edge, borderRadius: BorderRadius.circular(s * 0.3)))),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 60),
                top: _down ? 4 : 0,
                left: 0,
                right: 0,
                height: s,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: face, borderRadius: BorderRadius.circular(s * 0.3)),
                  child: Icon(
                    widget.slow ? Icons.slow_motion_video_rounded : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: s * 0.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small rounded pill used for stats in the top bar.
class StatPill extends StatelessWidget {
  const StatPill({super.key, required this.icon, required this.value, required this.color, this.tooltip, this.dim = false});

  final String icon;
  final String value;
  final Color color;
  final String? tooltip;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final w = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(opacity: dim ? 0.4 : 1, child: Text(icon, style: const TextStyle(fontSize: 20))),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w900, color: dim ? Palette.inkSoft : color)),
      ],
    );
    return tooltip == null ? w : Tooltip(message: tooltip!, child: w);
  }
}
