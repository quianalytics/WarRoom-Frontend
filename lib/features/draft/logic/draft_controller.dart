import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DraftUiState {
  final bool initialized;
  final bool clockRunning;
  final int secondsRemaining;

  final String currentPickLabel; // "Pick 1 (R1.1)"
  final String onTheClockTeam;   // "NYG"
  final String statusText;

  const DraftUiState({
    required this.initialized,
    required this.clockRunning,
    required this.secondsRemaining,
    required this.currentPickLabel,
    required this.onTheClockTeam,
    required this.statusText,
  });

  factory DraftUiState.initial() => const DraftUiState(
        initialized: false,
        clockRunning: false,
        secondsRemaining: 600, // 10 min default (we'll make this configurable)
        currentPickLabel: 'Not started',
        onTheClockTeam: '--',
        statusText: 'Press Start to begin the mock draft.',
      );

  DraftUiState copyWith({
    bool? initialized,
    bool? clockRunning,
    int? secondsRemaining,
    String? currentPickLabel,
    String? onTheClockTeam,
    String? statusText,
  }) {
    return DraftUiState(
      initialized: initialized ?? this.initialized,
      clockRunning: clockRunning ?? this.clockRunning,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      currentPickLabel: currentPickLabel ?? this.currentPickLabel,
      onTheClockTeam: onTheClockTeam ?? this.onTheClockTeam,
      statusText: statusText ?? this.statusText,
    );
  }
}

class DraftController extends StateNotifier<DraftUiState> {
  DraftController() : super(DraftUiState.initial());

  Timer? _timer;

  Future<void> startDraft({required int year, required List<String> controlledTeams}) async {
    // Next step: load picks, teams, prospects from your API
    state = state.copyWith(
      initialized: true,
      currentPickLabel: 'Pick 1 (R1.1)',
      onTheClockTeam: 'NYG',
      statusText: 'Draft started. Next: load draft order + big board.',
    );

    _startClock(seconds: 600);
  }

  void _startClock({required int seconds}) {
    _timer?.cancel();
    state = state.copyWith(secondsRemaining: seconds, clockRunning: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.clockRunning) return;
      final next = state.secondsRemaining - 1;
      if (next <= 0) {
        // Next step: auto-pick + advance to next pick
        state = state.copyWith(
          secondsRemaining: 0,
          clockRunning: false,
          statusText: 'Clock expired. Next: auto-pick and advance.',
        );
        _timer?.cancel();
      } else {
        state = state.copyWith(secondsRemaining: next);
      }
    });
  }

  void pauseClock() => state = state.copyWith(clockRunning: false);
  void resumeClock() => state = state.copyWith(clockRunning: true);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
