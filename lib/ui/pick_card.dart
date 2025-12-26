import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PickCard extends StatelessWidget {
  const PickCard({
    super.key,
    required this.child,
    this.glowColor,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final Color? glowColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final glow = glowColor ?? AppColors.blue;
    return Container(
      padding: padding,
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF182234),
            Color(0xFF111827),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.borderStrong),
        ),
        shadows: [
          const BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: glow.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
