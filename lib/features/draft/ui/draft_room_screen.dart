import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/draft_controller.dart';
import '../ui/widgets/clock_widget.dart';

final draftControllerProvider =
    StateNotifierProvider.autoDispose<DraftController, DraftUiState>((ref) {
  return DraftController();
});

class DraftRoomScreen extends ConsumerWidget {
  const DraftRoomScreen({super.key, required this.year, required this.controlledTeams});

  final int year;
  final List<String> controlledTeams;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(draftControllerProvider);
    final controller = ref.read(draftControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mock Draft $year'),
        actions: [
          IconButton(
            tooltip: 'Start',
            onPressed: () => controller.startDraft(year: year, controlledTeams: controlledTeams),
            icon: const Icon(Icons.play_arrow),
          ),
          IconButton(
            tooltip: state.clockRunning ? 'Pause' : 'Resume',
            onPressed: () => state.clockRunning ? controller.pauseClock() : controller.resumeClock(),
            icon: Icon(state.clockRunning ? Icons.pause : Icons.play_arrow),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DraftClockWidget(secondsRemaining: state.secondsRemaining),
            const SizedBox(height: 16),

            // Current pick header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  state.currentPickLabel,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  state.onTheClockTeam,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: Center(
                child: Text(
                  state.statusText,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
