import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_router.dart';
import './theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: WarRoomDraftApp()));
}

class WarRoomDraftApp extends StatelessWidget {
  const WarRoomDraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);

    final theme = base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.blue,
        secondary: AppColors.blue,
        surface: AppColors.surface,
      ),

      // Typography: slightly tighter + more “product” feel
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.25),
      ),

      // AppBar: flatter, cleaner, not “stock Android”
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: AppColors.text),
      ),

      // Buttons: pill-ish, clean, no heavy shadows
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.r16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.r16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.text,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),

      // Cards/surfaces: consistent rounded corners + subtle outline
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.r16),
        margin: EdgeInsets.zero,
      ),

      // Input fields: more “dashboard” look
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: AppColors.surface2,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: AppRadii.r16,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.r16,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.r16,
          borderSide: const BorderSide(color: AppColors.blue, width: 1.2),
        ),
      ),

      // Chips: clean, consistent
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface2,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
        shape: const StadiumBorder(),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
    );

    return MaterialApp.router(
      title: 'WarRoom Draft',
      theme: theme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
