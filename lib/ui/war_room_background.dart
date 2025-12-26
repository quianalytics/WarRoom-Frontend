import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WarRoomBackground extends StatelessWidget {
  const WarRoomBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: AppGradients.background),
          ),
        ),
        const Positioned.fill(child: _WarRoomAtmosphere()),
        child,
      ],
    );
  }
}

class _WarRoomAtmosphere extends StatelessWidget {
  const _WarRoomAtmosphere();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridGlowPainter(),
    );
  }
}

class _GridGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0x14A9C7FF)
      ..strokeWidth = 1;
    const step = 48.0;

    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), linePaint);
    }

    final glowPaint = Paint()
      ..color = const Color(0x222D7CFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.2), 180, glowPaint);

    final glowPaint2 = Paint()
      ..color = const Color(0x1A57F0FF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 140);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.85), 220, glowPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
