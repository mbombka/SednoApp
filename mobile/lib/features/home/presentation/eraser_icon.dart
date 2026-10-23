import 'package:flutter/material.dart';

class EraserIcon extends StatelessWidget {
  const EraserIcon({super.key});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 28,
    child: CustomPaint(
      painter: _EraserPainter(IconTheme.of(context).color ?? Colors.black),
    ),
  );
}

class _EraserPainter extends CustomPainter {
  const _EraserPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(3, 14)
        ..lineTo(13, 4)
        ..quadraticBezierTo(14, 3, 15, 4)
        ..lineTo(21, 10)
        ..quadraticBezierTo(22, 11, 21, 12)
        ..lineTo(12, 21)
        ..lineTo(8, 21)
        ..lineTo(3, 16)
        ..quadraticBezierTo(2, 15, 3, 14)
        ..close()
        ..moveTo(8, 9)
        ..lineTo(16, 17)
        ..moveTo(12, 21)
        ..lineTo(22, 21),
      paint,
    );
  }

  @override
  bool shouldRepaint(_EraserPainter oldDelegate) => oldDelegate.color != color;
}
