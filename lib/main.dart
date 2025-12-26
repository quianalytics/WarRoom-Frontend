import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_router.dart';
import './theme/app_theme.dart';
import './core/observability/error_reporter.dart';

void main() {
  FlutterError.onError = (details) {
    ErrorReporter.report(
      details.exception,
      details.stack,
      context: 'FlutterError',
    );
    FlutterError.presentError(details);
  };

  runZonedGuarded(() {
    runApp(const ProviderScope(child: WarRoomDraftApp()));
  }, (error, stack) {
    ErrorReporter.report(error, stack, context: 'Zone');
  });
}

class WarRoomDraftApp extends StatelessWidget {
  const WarRoomDraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );

    final theme = base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.blueDeep,
        secondary: AppColors.mint,
        surface: AppColors.surface,
      ),

      // Typography: slightly tighter + more “product” feel
      textTheme: textTheme.copyWith(
        displaySmall: textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.3),
      ),

      // AppBar: flatter, cleaner, not “stock Android”
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.text),
      ),

      // Buttons: pill-ish, clean, no heavy shadows
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blueDeep,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
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
            letterSpacing: 0.1,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.r16),
          side: const BorderSide(color: AppColors.borderStrong),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.text,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
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
          borderSide: const BorderSide(color: AppColors.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.r16,
          borderSide: const BorderSide(color: AppColors.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.r16,
          borderSide: const BorderSide(color: AppColors.blue, width: 1.4),
        ),
      ),

      // Chips: clean, consistent
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface2,
        side: const BorderSide(color: AppColors.borderStrong),
        labelStyle: const TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
        shape: const StadiumBorder(),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.borderStrong,
        thickness: 1,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.surface),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: AppRadii.r16),
          ),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.borderStrong),
          ),
          elevation: WidgetStateProperty.all(8),
        ),
        textStyle: const TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
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
