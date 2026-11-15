import 'package:flutter/material.dart';

class SoulMark extends StatelessWidget {
  final double size;
  const SoulMark({super.key, this.size = 26});
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _Mark(Theme.of(context).colorScheme.primary)),
  );
}

class _Mark extends CustomPainter {
  final Color color;
  _Mark(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * .12,
            size.height * (.12 + i * .28),
            size.width * (.76 - i * .19),
            size.height * .17,
          ),
          Radius.circular(size.width * .035),
        ),
        p,
      );
    }
    canvas.drawCircle(
      Offset(size.width * .83, size.height * .765),
      size.width * .085,
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _Mark old) => old.color != color;
}
