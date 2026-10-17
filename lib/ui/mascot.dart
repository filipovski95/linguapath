import 'dart:math';

import 'package:flutter/material.dart';

import 'palette.dart';

enum MascotMood { idle, happy, cheer, sad, thinking }

/// Pip, Saylark's guide: a little speech-bubble creature.
/// Drawn in code so it stays crisp at any size and can bob and blink.
class Mascot extends StatefulWidget {
  const Mascot({super.key, this.mood = MascotMood.idle, this.size = 96, this.animate = true});

  final MascotMood mood;
  final double size;
  final bool animate;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.animate && !still) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = reduceMotion || !widget.animate ? 0.0 : _c.value;
          final bob = sin(t * 2 * pi) * (widget.mood == MascotMood.cheer ? 4 : 1.6);
          // Blink briefly once per cycle.
          final blink = (t > 0.92 && t < 0.97) ? 0.1 : 1.0;
          return CustomPaint(
            size: Size.square(widget.size),
            painter: MascotPainter(mood: widget.mood, bob: bob, blink: blink),
          );
        },
      ),
    );
  }
}

class MascotPainter extends CustomPainter {
  MascotPainter({required this.mood, this.bob = 0, this.blink = 1});

  final MascotMood mood;
  final double bob;
  final double blink;

  static const body = Palette.violet;
  static const bodyDark = Palette.violetDark;
  static const cheek = Color(0x99FF8FB5);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.scale(s);

    // Ground shadow (does not bob).
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 95), width: 48 - bob, height: 7),
        Paint()..color = const Color(0x22231C47));

    canvas.translate(0, -bob);
    final ink = Paint()..color = Palette.ink;
    final stroke = Paint()
      ..color = Palette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;

    // Arms
    final arm = Paint()..color = bodyDark;
    final armsUp = mood == MascotMood.cheer;
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(50 + side * 34, 60);
      canvas.rotate(side * (armsUp ? -2.3 : -0.35));
      canvas.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -4, 10, 20), const Radius.circular(5)), arm);
      canvas.restore();
    }

    // Antenna
    canvas.drawLine(const Offset(50, 22), const Offset(50, 10),
        Paint()
          ..color = bodyDark
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(const Offset(50, 8), 5.5, Paint()..color = const Color(0xFFFF5FA2));
    canvas.drawCircle(const Offset(48.3, 6.3), 1.6, Paint()..color = Colors.white70);

    // Body with speech-bubble tail
    final bodyRect = RRect.fromRectAndRadius(const Rect.fromLTRB(16, 20, 84, 84), const Radius.circular(30));
    final tail = Path()
      ..moveTo(28, 76)
      ..quadraticBezierTo(26, 88, 18, 94)
      ..quadraticBezierTo(34, 92, 44, 82)
      ..close();
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8468FF), body],
      ).createShader(const Rect.fromLTRB(16, 20, 84, 94));
    canvas.drawPath(tail, fill);
    canvas.drawRRect(bodyRect, fill);
    // Soft shine
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTRB(26, 25, 52, 31), const Radius.circular(4)),
        Paint()..color = Colors.white24);

    // Cheeks
    canvas.drawOval(Rect.fromCenter(center: const Offset(27, 60), width: 11, height: 7), Paint()..color = cheek);
    canvas.drawOval(Rect.fromCenter(center: const Offset(73, 60), width: 11, height: 7), Paint()..color = cheek);

    // Eyes
    if (mood == MascotMood.cheer) {
      for (final x in [37.0, 63.0]) {
        final p = Path()
          ..moveTo(x - 7, 49)
          ..quadraticBezierTo(x, 37, x + 7, 49);
        canvas.drawPath(p, stroke..color = Colors.white..strokeWidth = 4.2);
      }
      stroke
        ..color = Palette.ink
        ..strokeWidth = 3.4;
    } else {
      final look = switch (mood) {
        MascotMood.sad => const Offset(0, 3),
        MascotMood.thinking => const Offset(3, -3),
        _ => const Offset(1.2, 1.5),
      };
      for (final (x, dir) in [(37.0, 1.0), (63.0, -1.0)]) {
        canvas.drawOval(
            Rect.fromCenter(center: Offset(x, 46), width: 20, height: 23 * blink), Paint()..color = Colors.white);
        if (blink > 0.5) {
          final c = Offset(x + dir * look.dx.abs() * (mood == MascotMood.thinking ? -dir : 1), 47 + look.dy);
          canvas.drawCircle(c, 6, ink);
          canvas.drawCircle(c + const Offset(-2, -2.4), 2, Paint()..color = Colors.white);
        }
      }
      if (mood == MascotMood.sad) {
        canvas.drawLine(const Offset(29, 33), const Offset(41, 30), stroke);
        canvas.drawLine(const Offset(71, 33), const Offset(59, 30), stroke);
      }
    }

    // Mouth
    switch (mood) {
      case MascotMood.cheer:
      case MascotMood.happy:
        final m = Path()
          ..moveTo(41, 61)
          ..quadraticBezierTo(50, 61, 59, 61)
          ..quadraticBezierTo(58, 74, 50, 74)
          ..quadraticBezierTo(42, 74, 41, 61)
          ..close();
        canvas.drawPath(m, ink);
        canvas.drawOval(Rect.fromCenter(center: const Offset(50, 70.5), width: 9, height: 5),
            Paint()..color = const Color(0xFFFF7EA8));
      case MascotMood.sad:
        final m = Path()
          ..moveTo(43, 68)
          ..quadraticBezierTo(50, 61, 57, 68);
        canvas.drawPath(m, stroke);
      case MascotMood.thinking:
        canvas.drawOval(Rect.fromCenter(center: const Offset(54, 65), width: 6, height: 7), ink);
      case MascotMood.idle:
        final m = Path()
          ..moveTo(43, 62)
          ..quadraticBezierTo(50, 69, 57, 62);
        canvas.drawPath(m, stroke);
    }
  }

  @override
  bool shouldRepaint(MascotPainter old) => old.mood != mood || old.bob != bob || old.blink != blink;
}

/// Pip with a speech bubble beside it.
class MascotSays extends StatelessWidget {
  const MascotSays({super.key, required this.text, this.mood = MascotMood.idle, this.size = 72, this.child});

  final String text;
  final MascotMood mood;
  final double size;

  /// Optional content shown in the bubble instead of plain text.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Mascot(mood: mood, size: size),
        const SizedBox(width: 6),
        Flexible(
          child: Padding(
            padding: EdgeInsets.only(bottom: size * 0.3),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF221D44) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(color: dark ? Colors.white12 : Palette.line, width: 2),
              ),
              child: child ??
                  Text(text,
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: scheme.onSurface)),
            ),
          ),
        ),
      ],
    );
  }
}
