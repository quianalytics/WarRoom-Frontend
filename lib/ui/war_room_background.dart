import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WarRoomBackground extends StatefulWidget {
  const WarRoomBackground({super.key, required this.child});

  final Widget child;

  @override
  State<WarRoomBackground> createState() => _WarRoomBackgroundState();
}

class _WarRoomBackgroundState extends State<WarRoomBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
    _t = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: AppGradients.background),
          ),
        ),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _t,
            builder: (context, _) {
              return CustomPaint(
                painter: _GridGlowPainter(t: _t.value),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _GridGlowPainter extends CustomPainter {
  _GridGlowPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0x14A9C7FF)
      ..strokeWidth = 1;
    const step = 48.0;
    final drift = (t - 0.5) * 18;

    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x + drift, 0),
        Offset(x + size.height + drift, size.height),
        linePaint,
      );
    }

    final glowPaint = Paint()
      ..color = const Color(0x222D7CFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
    canvas.drawCircle(
      Offset(size.width * 0.75 + drift * 0.6, size.height * 0.2),
      180,
      glowPaint,
    );

    final glowPaint2 = Paint()
      ..color = const Color(0x1A57F0FF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 140);
    canvas.drawCircle(
      Offset(size.width * 0.2 - drift * 0.4, size.height * 0.85),
      220,
      glowPaint2,
    );
  }

  @override
  bool shouldRepaint(covariant _GridGlowPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}
