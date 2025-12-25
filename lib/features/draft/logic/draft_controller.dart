import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/draft_repository.dart';
import '../models/draft_pick.dart';
import '../models/prospect.dart';
import '../models/team.dart';
import 'draft_clock.dart';
import 'draft_state.dart';
import 'cpu_strategy.dart';
import 'trade_engine.dart';
import '../models/trade.dart';
import 'dart:async';
import '../../../core/storage/local_store.dart';
import 'draft_speed.dart';

class DraftController extends StateNotifier<DraftState> {
  DraftController(this._repo) : super(DraftState.initial());

  final DraftRepository _repo;
  final DraftClock _clock = DraftClock();
  final CpuDraftStrategy _cpu = CpuDraftStrategy();
  final TradeEngine _trades = TradeEngine();
  Timer? _cpuTimer;
  int? _cpuScheduledIndex;

  DraftSpeedPreset _speedPreset = DraftSpeedPreset.normal;
  DraftSpeed _speed = DraftSpeed.forPreset(DraftSpeedPreset.normal);

  bool _runToNextUserPick = false;

  int _currentClockSeconds() =>
      state.isUserOnClock ? _speed.userClockSeconds : _speed.cpuClockSeconds;

  Future<void> start({
    required int year,
    required List<String> userTeams,
    DraftSpeedPreset speedPreset = DraftSpeedPreset.normal,

  }) async {
    _speedPreset = speedPreset;
    _speed = DraftSpeed.forPreset(speedPreset);

    state = state.copyWith(
      loading: true,
      error: null,
      year: year,
      userTeams: userTeams,
    );

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
        secondsRemaining: _currentClockSeconds(),
        clockRunning: true,
      );

      await saveNow(); // initial save
      _startClockForCurrentPick();
      _maybeScheduleCpuPick();
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void pauseClock() async {
    state = state.copyWith(clockRunning: false);
    _clock.pause();
    _cpuTimer?.cancel();
    _cpuScheduledIndex = null;
    await saveNow();
  }

  void resumeClock() {
    if (state.isComplete) return;
    state = state.copyWith(clockRunning: true);
    _clock.resume();
    _maybeScheduleCpuPick();
  }

  void _startClockForCurrentPick() {
    final seconds = _currentClockSeconds();

    _clock.start(
      seconds: seconds,
      onTick: (remaining) {
        state = state.copyWith(secondsRemaining: remaining);
      },
      onExpired: () {
        if (state.isComplete) return;
        _cpuTimer?.cancel();
        _cpuScheduledIndex = null;
        autoPick();
      },
    );
  }

  Team? _teamByAbbr(String abbr) {
    final u = abbr.toUpperCase();
    for (final t in state.teams) {
      if (t.abbreviation.toUpperCase() == u || t.teamId.toUpperCase() == u)
        return t;
    }
    return null;
  }

  Future<void> draftProspect(Prospect p) async {
    final pick = state.currentPick;
    if (pick == null) return;

    // Remove from available
    final updatedBoard = [...state.availableProspects]
      ..removeWhere((x) => x.id == p.id);

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
      secondsRemaining: _currentClockSeconds(),
      clockRunning: true,
    );

    if (!state.isComplete) {
      _startClockForCurrentPick();
      _maybeScheduleCpuPick();
      await saveNow();
    } else {
      _clock.stop();
    }
  }

  Future<void> autoPick() async {
    final pick = state.currentPick;
    if (pick == null) return;
    final team = _teamByAbbr(pick.teamAbbr);
    final chosen = _cpu.choose(team: team, board: state.availableProspects);
    await draftProspect(chosen);
  }

  void _maybeScheduleCpuPick() {
    if (state.isComplete) return;

    if (state.isUserOnClock) {
      _cpuTimer?.cancel();
      _cpuScheduledIndex = null;
      _runToNextUserPick = false; // stop fast-forward once user is up
      return;
    }

    // Avoid double scheduling for the same pick
    if (_cpuScheduledIndex == state.currentIndex) return;

    _cpuTimer?.cancel();
    _cpuScheduledIndex = state.currentIndex;

    // If we're running to next user pick or preset is instant, pick immediately
    final instant =
        _speedPreset == DraftSpeedPreset.instant || _runToNextUserPick;
    if (instant) {
      autoPick();
      return;
    }

    // Otherwise think 1..N seconds
    final min = _speed.cpuThinkMinSeconds;
    final max = _speed.cpuThinkMaxSeconds;
    final thinkSeconds = (max <= min)
        ? min
        : (min + (DateTime.now().millisecondsSinceEpoch % (max - min + 1)));

    _cpuTimer = Timer(Duration(seconds: thinkSeconds), () {
      if (state.isComplete) return;
      if (!state.clockRunning) return;
      if (state.currentIndex != _cpuScheduledIndex) return;

      autoPick();
    });
  }

  DraftSpeedPreset get speedPreset => _speedPreset;

  Future<void> resumeSavedDraft(int year) async {
    final saved = await LocalStore.loadDraft(year);
    if (saved == null) {
      state = state.copyWith(error: 'No saved draft found for $year');
      return;
    }
    _clock.stop();
    _cpuTimer?.cancel();
    _cpuScheduledIndex = null;

    state = DraftState.fromJson(saved);
    // When resuming, restart clock for current pick
    _startClockForCurrentPick();
    _maybeScheduleCpuPick();
  }

  Future<void> saveNow() async {
    if (state.order.isEmpty) return;
    await LocalStore.saveDraft(state.year, state.toJson());
  }

  Future<void> clearSavedDraft(int year) async {
    await LocalStore.clearDraft(year);
  }

  void setSpeedPreset(DraftSpeedPreset preset) {
    _speedPreset = preset;
    _speed = DraftSpeed.forPreset(preset);

    // Apply immediately to current pick:
    state = state.copyWith(secondsRemaining: _currentClockSeconds());
    _startClockForCurrentPick();
    _maybeScheduleCpuPick();
  }

  void runToNextUserPick() {
    _runToNextUserPick = true;
    // If CPU is on the clock, accelerate until next user pick.
    _maybeScheduleCpuPick();
  }

  /// Trade: swap ownership of picks (MVP uses pick swaps only)
  /// You’ll call this from a UI trade sheet.
  bool proposeTrade(TradeOffer offer) {
    final pick = _contextPickFor(offer) ?? state.currentPick;
    if (pick == null) return false;

    final context = TradeContext(
      currentPick: pick,
      fromTeam: _teamByAbbr(offer.fromTeam),
      toTeam: _teamByAbbr(offer.toTeam),
      availableProspects: state.availableProspects,
      currentYear: state.year,
    );

    if (!_trades.accept(offer, context: context)) return false;

    // Update order ownership for any picks in the offer lists
    final toAssets = offer.toAssets
        .where((a) => a.pick != null)
        .map((a) => a.pick!)
        .toList();
    final fromAssets = offer.fromAssets
        .where((a) => a.pick != null)
        .map((a) => a.pick!)
        .toList();

    final updatedOrder = state.order.map((p) {
      DraftPick updated = p;
      for (final give in toAssets) {
        if (_samePick(p, give)) {
          // toAssets are given by toTeam -> fromTeam acquires them
          updated = _withOwner(p, offer.fromTeam);
        }
      }
      for (final get in fromAssets) {
        if (_samePick(p, get)) {
          // fromAssets are given by fromTeam -> toTeam acquires them
          updated = _withOwner(p, offer.toTeam);
        }
      }
      return updated;
    }).toList();

    state = state.copyWith(order: updatedOrder);
    return true;
  }

  DraftPick? _contextPickFor(TradeOffer offer) {
    final toPicks = offer.toAssets
        .where((a) => a.pick != null)
        .map((a) => a.pick!)
        .where((p) => p.year == state.year)
        .toList();
    if (toPicks.isEmpty) return null;
    toPicks.sort((a, b) => a.pickOverall.compareTo(b.pickOverall));
    return toPicks.first;
  }

  bool _samePick(DraftPick a, DraftPick b) {
    return a.year == b.year &&
        a.round == b.round &&
        a.pickOverall == b.pickOverall &&
        a.pickInRound == b.pickInRound;
  }

  DraftPick _withOwner(DraftPick pick, String teamAbbr) {
    return DraftPick(
      year: pick.year,
      round: pick.round,
      pickOverall: pick.pickOverall,
      pickInRound: pick.pickInRound,
      teamAbbr: teamAbbr,
      team: pick.team,
      originalTeamAbbr: pick.originalTeamAbbr,
      isCompensatory: pick.isCompensatory,
    );
  }

  @override
  void dispose() {
    _cpuTimer?.cancel();
    _clock.stop();
    super.dispose();
  }
}
