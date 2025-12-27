import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              gradient: AppGradients.panel,
              borderRadius: BorderRadius.circular(size),
              border: Border.all(color: AppColors.borderStrong),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Color(0x221FA1FF),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
          ),
          CircularProgressIndicator(
            strokeWidth: 3,
            backgroundColor: AppColors.borderStrong,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
          ),
        ],
      ),
    );
  }
}
