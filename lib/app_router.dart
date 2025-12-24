import 'package:go_router/go_router.dart';
import 'features/setup/setup_screen.dart';
import 'features/draft/ui/draft_room_screen.dart';

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
        return DraftRoomScreen(year: year, controlledTeams: teams);
      },
    ),
  ],
);
