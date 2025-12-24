import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(12)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
