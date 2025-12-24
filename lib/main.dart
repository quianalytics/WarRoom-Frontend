import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_router.dart';

void main() {
  runApp(const ProviderScope(child: WarRoomDraftApp()));
}

class WarRoomDraftApp extends StatelessWidget {
  const WarRoomDraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WarRoom Draft',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      routerConfig: appRouter,
    );
  }
}

