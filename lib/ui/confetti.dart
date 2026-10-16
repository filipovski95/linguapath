import 'dart:math';

import 'package:flutter/material.dart';

import 'palette.dart';

/// A one-shot burst of confetti for celebrations.
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.pieces = 90});

  final int pieces;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..forward();
  late final List<_Piece> _pieces = List.generate(widget.pieces, (i) => _Piece(Random(i * 7 + 3)));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_pieces, _c.value)),
      ),
    );
  }
}

class _Piece {
  _Piece(Random r)
      : x = r.nextDouble(),
        vx = (r.nextDouble() - 0.5) * 0.5,
        vy = -(0.9 + r.nextDouble() * 0.7),
        spin = (r.nextDouble() - 0.5) * 18,
        size = 6 + r.nextDouble() * 7,
        color = [Palette.violet, Palette.sun, Palette.green, Palette.coral, const Color(0xFF1CB0F6), const Color(0xFFFF5FA2)][r.nextInt(6)],
        round = r.nextBool();

  final double x, vx, vy, spin, size;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      // Launched from the bottom centre area, then falling under gravity.
      final px = size.width * (p.x + p.vx * t);
      final py = size.height * (0.75 + p.vy * t + 1.3 * t * t);
      final paint = Paint()..color = p.color.withValues(alpha: (1 - t * t).clamp(0, 1));
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2.4, paint);
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
                const Radius.circular(2)),
            paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
