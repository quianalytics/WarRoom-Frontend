import 'package:flutter/material.dart';

class AppColors {
  static const blue = Color(0xFF4ED6FF);
  static const blueDeep = Color(0xFF2D7CFF);
  static const mint = Color(0xFF6DFFB4);
  static const accent = Color(0xFFFF6B1A);

  static const bg = Color(0xFF07080B);
  static const bgAlt = Color(0xFF0B0F16);
  static const surface = Color(0xFF121826);
  static const surface2 = Color(0xFF0E141F);
  static const border = Color(0xFF263146);
  static const borderStrong = Color(0xFF35506F);

  static const text = Color(0xFFF2F7FF);
  static const textMuted = Color(0xFF9CB0CB);
}

class AppGradients {
  static const background = LinearGradient(
    colors: [
      Color(0xFF0B0F16),
      Color(0xFF0A1423),
      Color(0xFF0B0F18),
      Color(0xFF09101C),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const vignette = RadialGradient(
    colors: [
      Color(0x00000000),
      Color(0xAA05070C),
    ],
    center: Alignment(0.0, -0.2),
    radius: 1.1,
  );

  static const panel = LinearGradient(
    colors: [
      Color(0xFF1A2232),
      Color(0xFF111827),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const panelSheen = LinearGradient(
    colors: [
      Color(0x22FFFFFF),
      Color(0x00FFFFFF),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const pill = LinearGradient(
    colors: [
      Color(0xFF1A2536),
      Color(0xFF0F1824),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentBar = LinearGradient(
    colors: [
      Color(0xFF4ED6FF),
      Color(0xFF6DFFB4),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
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
