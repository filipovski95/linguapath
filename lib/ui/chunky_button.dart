import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'palette.dart';

/// A big, tactile button with a solid "3D" lip that presses down when tapped.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = Palette.violet,
    this.shadow = Palette.violetDark,
    this.textColor = Colors.white,
    this.icon,
    this.height = 56,
  });

  /// The white "secondary" style with a grey lip.
  const ChunkyButton.light({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 56,
  })  : color = Colors.white,
        shadow = Palette.line,
        textColor = Palette.violet;

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color shadow;
  final Color textColor;
  final IconData? icon;
  final double height;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;
  static const lip = 5.0;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final face = enabled ? widget.color : Palette.locked;
    final edge = enabled ? widget.shadow : Palette.lockedDark;
    final fg = enabled ? widget.textColor : Palette.inkSoft;
    final pressed = _down && enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                HapticFeedback.selectionClick();
                widget.onPressed!();
              }
            : null,
        child: SizedBox(
          height: widget.height + lip,
          child: Stack(
            children: [
              Positioned.fill(
                top: lip,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: edge,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 60),
                left: 0,
                right: 0,
                top: pressed ? lip : 0,
                height: widget.height,
                child: Container(
                  decoration: BoxDecoration(
                    color: face,
                    borderRadius: BorderRadius.circular(16),
                    border: widget.color == Colors.white
                        ? Border.all(color: Palette.line, width: 2)
                        : null,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  // Long labels or large text shrink instead of overflowing.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: fg),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label.toUpperCase(),
                          style: TextStyle(
                            color: fg,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
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

/// A tappable card with the same pressable lip, used for answer options.
class ChunkyCard extends StatefulWidget {
  const ChunkyCard({
    super.key,
    required this.child,
    required this.onTap,
    this.border = Palette.line,
    this.fill = Colors.white,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color border;
  final Color fill;
  final EdgeInsets padding;

  @override
  State<ChunkyCard> createState() => _ChunkyCardState();
}

class _ChunkyCardState extends State<ChunkyCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final pressed = _down && widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _down = false);
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        margin: EdgeInsets.only(top: pressed ? 3 : 0),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.fill,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            top: BorderSide(color: widget.border, width: 2),
            left: BorderSide(color: widget.border, width: 2),
            right: BorderSide(color: widget.border, width: 2),
            bottom: BorderSide(color: widget.border, width: pressed ? 2 : 5),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
