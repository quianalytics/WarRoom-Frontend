import 'package:flutter/material.dart';

class AppColors {
  static const blue = Color(0xFF4ED6FF);
  static const blueDeep = Color(0xFF2B6AF6);
  static const mint = Color(0xFF78FFC8);

  static const bg = Color(0xFF0A0E14);
  static const bgAlt = Color(0xFF0E1622);
  static const surface = Color(0xFF141D2A);
  static const surface2 = Color(0xFF101824);
  static const border = Color(0xFF243248);
  static const borderStrong = Color(0xFF2F4361);

  static const text = Color(0xFFE9F1FB);
  static const textMuted = Color(0xFF9DB2CC);
}

class AppGradients {
  static const background = LinearGradient(
    colors: [
      Color(0xFF0A0E14),
      Color(0xFF0F1826),
      Color(0xFF0B1421),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const panel = LinearGradient(
    colors: [
      Color(0xFF161F2D),
      Color(0xFF101824),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const pill = LinearGradient(
    colors: [
      Color(0xFF1B2737),
      Color(0xFF0E1622),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppRadii {
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
}

class AppSpacing {
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
}
