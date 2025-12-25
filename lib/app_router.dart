import 'package:go_router/go_router.dart';
import 'features/home/home_screen.dart';
import 'features/setup/setup_screen.dart';
import 'features/draft/ui/draft_room_screen.dart';
import 'features/draft/logic/draft_speed.dart';



final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/setup',
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
        final tradeFreqRaw = state.uri.queryParameters['tradeFreq'] ?? 'normal';
        final tradeStrictRaw =
            state.uri.queryParameters['tradeStrict'] ?? 'normal';
        final tradeFreq = switch (tradeFreqRaw) {
          'low' => 0.12,
          'high' => 0.35,
          _ => 0.22,
        };
        final tradeStrict = switch (tradeStrictRaw) {
          'lenient' => -0.03,
          'strict' => 0.04,
          _ => 0.0,
        };
        return DraftRoomScreen(
          year: year,
          controlledTeams: teams,
          resume: resume,
          speedPreset: speed,
          tradeFrequency: tradeFreq,
          tradeStrictness: tradeStrict,
        );
      },
    ),
  ],
);
