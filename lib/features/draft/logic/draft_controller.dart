import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/draft_repository.dart';
import '../models/draft_pick.dart';
import '../models/prospect.dart';
import '../models/team.dart';
import 'draft_clock.dart';
import 'draft_state.dart';
import 'cpu_strategy.dart';
import 'trade_engine.dart';
import 'dart:async';

class DraftController extends StateNotifier<DraftState> {
  DraftController(this._repo) : super(DraftState.initial());

  final DraftRepository _repo;
  final DraftClock _clock = DraftClock();
  final CpuDraftStrategy _cpu = CpuDraftStrategy();
  final TradeEngine _trades = TradeEngine();
  Timer? _cpuTimer;
  int? _cpuScheduledIndex;


  int _clockSeconds = 600;

  Future<void> start({required int year, required List<String> userTeams, int clockSeconds = 600}) async {
    state = state.copyWith(loading: true, error: null, year: year, userTeams: userTeams);
    _clockSeconds = clockSeconds;

    try {
      final teams = await _repo.fetchTeams();
      final order = await _repo.fetchDraftOrder(year);
      final prospects = await _repo.fetchProspects(year);

      state = state.copyWith(
        loading: false,
        teams: teams,
        order: order..sort((a, b) => a.pickOverall.compareTo(b.pickOverall)),
        availableProspects: prospects,
        picksMade: [],
        currentIndex: 0,
        secondsRemaining: _clockSeconds,
        clockRunning: true,
      );

      _startClockForCurrentPick();
      _maybeScheduleCpuPick(); // if first pick is CPU, it should start thinking
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void pauseClock() {
  state = state.copyWith(clockRunning: false);
  _clock.pause();
  _cpuTimer?.cancel();
  _cpuScheduledIndex = null;
}


  void resumeClock() {
  if (state.isComplete) return;
  state = state.copyWith(clockRunning: true);
  _clock.resume();
  _maybeScheduleCpuPick();
}



  void _startClockForCurrentPick() {
  _clock.start(
    seconds: _clockSeconds,
    onTick: (remaining) {
      state = state.copyWith(secondsRemaining: remaining);
    },
    onExpired: () {
      if (state.isComplete) return;
      // prevent double-pick if CPU timer is about to fire
      _cpuTimer?.cancel();
      _cpuScheduledIndex = null;

      autoPick();
    },
  );
}

  Team? _teamByAbbr(String abbr) {
    final u = abbr.toUpperCase();
    for (final t in state.teams) {
      if (t.abbreviation.toUpperCase() == u || t.teamId.toUpperCase() == u) return t;
    }
    return null;
  }

  void draftProspect(Prospect p) {
    final pick = state.currentPick;
    if (pick == null) return;

    // Remove from available
    final updatedBoard = [...state.availableProspects]..removeWhere((x) => x.id == p.id);

    final result = PickResult(
      pick: pick,
      teamAbbr: pick.teamAbbr,
      prospect: p,
      madeAt: DateTime.now(),
    );

    final picksMade = [...state.picksMade, result];

    state = state.copyWith(
      availableProspects: updatedBoard,
      picksMade: picksMade,
      currentIndex: state.currentIndex + 1,
      secondsRemaining: _clockSeconds,
      clockRunning: true,
    );

    if (!state.isComplete) {
      _startClockForCurrentPick();
      _maybeScheduleCpuPick();
    } else {
      _clock.stop();
    }
  }

  void autoPick() {
    final pick = state.currentPick;
    if (pick == null) return;

    final team = _teamByAbbr(pick.teamAbbr);
    final chosen = _cpu.choose(team: team, board: state.availableProspects);

    draftProspect(chosen);
  }

  void _maybeScheduleCpuPick() {
  if (state.isComplete) return;
  if (state.isUserOnClock) {
    _cpuTimer?.cancel();
    _cpuScheduledIndex = null;
    return;
  }

  // Avoid scheduling twice for the same pick
  if (_cpuScheduledIndex == state.currentIndex) return;

  _cpuTimer?.cancel();
  _cpuScheduledIndex = state.currentIndex;

  // Simple "think time" – tune this later
  final thinkSeconds = 1 + (DateTime.now().millisecondsSinceEpoch % 3); // 1..3

  _cpuTimer = Timer(Duration(seconds: thinkSeconds), () {
    // If we've advanced or paused, don't pick
    if (state.isComplete) return;
    if (!state.clockRunning) return;
    if (state.currentIndex != _cpuScheduledIndex) return;

    autoPick();
  });
}

  /// Trade: swap ownership of picks (MVP uses pick swaps only)
  /// You’ll call this from a UI trade sheet.
  bool proposeTrade(TradeOffer offer) {
    if (!_trades.accept(offer)) return false;

    // Update order ownership for any picks in the offer lists
    final updatedOrder = state.order.map((p) {
      DraftPick updated = p;
      for (final give in offer.toAssets) {
        if (p.pickOverall == give.pickOverall && p.round == give.round) {
          // toAssets are given by toTeam -> fromTeam acquires them
          updated = DraftPick(
            year: p.year,
            round: p.round,
            pickOverall: p.pickOverall,
            pickInRound: p.pickInRound,
            teamAbbr: offer.fromTeam,
            team: p.team,
            originalTeamAbbr: p.originalTeamAbbr,
            isCompensatory: p.isCompensatory,
          );
        }
      }
      for (final get in offer.fromAssets) {
        if (p.pickOverall == get.pickOverall && p.round == get.round) {
          // fromAssets are given by fromTeam -> toTeam acquires them
          updated = DraftPick(
            year: p.year,
            round: p.round,
            pickOverall: p.pickOverall,
            pickInRound: p.pickInRound,
            teamAbbr: offer.toTeam,
            team: p.team,
            originalTeamAbbr: p.originalTeamAbbr,
            isCompensatory: p.isCompensatory,
          );
        }
      }
      return updated;
    }).toList();

    state = state.copyWith(order: updatedOrder);
    return true;
  }

  @override
  void dispose() {
    _cpuTimer?.cancel();
    _clock.stop();
    super.dispose();
  }
}

