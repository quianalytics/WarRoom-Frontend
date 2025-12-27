import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class IconPill extends StatelessWidget {
  const IconPill({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          gradient: AppGradients.pill,
          borderRadius: AppRadii.r16,
          border: Border.all(color: AppColors.borderStrong),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Color(0x22002C4F),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
            BoxShadow(
              color: Color(0x221FA1FF),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, size: 15, color: AppColors.text),
      ),
    );
  }
}
