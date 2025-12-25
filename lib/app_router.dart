import 'package:go_router/go_router.dart';
import 'features/setup/setup_screen.dart';
import 'features/draft/ui/draft_room_screen.dart';
import 'features/draft/logic/draft_speed.dart';



final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const SetupScreen(),
    ),
    GoRoute(
      path: '/draft',
      builder: (_, state) {
        final year = int.parse(state.uri.queryParameters['year'] ?? '2026');
        final teams = (state.uri.queryParameters['teams'] ?? '').split(',').where((s) => s.isNotEmpty).toList();
        final resume = state.uri.queryParameters['resume'] == '1';
        final speedRaw = state.uri.queryParameters['speed'] ?? 'fast';
        final speed = DraftSpeedPreset.values.firstWhere(
          (s) => s.name == speedRaw,
          orElse: () => DraftSpeedPreset.fast,
        );
        return DraftRoomScreen(
          year: year,
          controlledTeams: teams,
          resume: resume,
          speedPreset: speed,
        );
      },
    ),
  ],
);
