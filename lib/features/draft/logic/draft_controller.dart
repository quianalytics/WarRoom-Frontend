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
import 'dart:math';
import '../../../core/storage/local_store.dart';
import 'draft_speed.dart';
import '../../../core/observability/error_reporter.dart';

class DraftController extends StateNotifier<DraftState> {
  DraftController(this._repo) : super(DraftState.initial());

  final DraftRepository _repo;
  final DraftClock _clock = DraftClock();
  final CpuDraftStrategy _cpu = CpuDraftStrategy();
  final TradeEngine _trades = TradeEngine();
  Timer? _cpuTimer;
  int? _cpuScheduledIndex;
  int? _tradeScheduledIndex;
  final Random _rng = Random();
  double _cpuTradeFrequency = 0.22;
  double _cpuTradeStrictness = 0.0;

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
    _tradeScheduledIndex = null;

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
        pendingTrade: null,
        tradeInbox: const <TradeOffer>[],
        tradeLog: const <TradeLogEntry>[],
        tradeLogVersion: 0,
      );

      await saveNow(); // initial save
      _startClockForCurrentPick();
      _maybeOfferTrade();
      _maybeScheduleCpuPick();
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'DraftController.start');
      state = state.copyWith(
        loading: false,
        error: 'Unable to load draft data. Check your connection and try again.',
      );
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
      _maybeOfferTrade();
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
      _maybeOfferTrade();
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
    _tradeScheduledIndex = null;
    // When resuming, restart clock for current pick
    _startClockForCurrentPick();
    _maybeOfferTrade();
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

  void setTradeSettings({double? frequency, double? strictness}) {
    if (frequency != null) {
      _cpuTradeFrequency = frequency.clamp(0.0, 1.0);
    }
    if (strictness != null) {
      _cpuTradeStrictness = strictness.clamp(-0.1, 0.2);
    }
  }

  double get cpuTradeFrequency => _cpuTradeFrequency;
  double get cpuTradeStrictness => _cpuTradeStrictness;

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

    _applyTrade(offer, log: true);
    if (!state.isComplete) {
      state = state.copyWith(secondsRemaining: _currentClockSeconds());
      _startClockForCurrentPick();
      _maybeScheduleCpuPick();
    }
    state = state.copyWith(pendingTrade: null);
    return true;
  }

  bool acceptIncomingTrade(TradeOffer offer) {
    final ok = proposeTrade(offer);
    if (ok) {
      _removeFromInbox(offer);
      _advancePendingTrade();
    }
    return ok;
  }

  void declinePendingTrade() {
    if (state.pendingTrade == null) return;
    final offer = state.pendingTrade!;
    state = state.copyWith(pendingTrade: null);
    _removeFromInbox(offer);
    _advancePendingTrade();
  }

  void clearPendingTrade() {
    if (state.pendingTrade == null) return;
    state = state.copyWith(pendingTrade: null);
  }

  void declineTradeOffer(TradeOffer offer) {
    _removeFromInbox(offer);
    if (state.pendingTrade?.id == offer.id) {
      state = state.copyWith(pendingTrade: null);
      _advancePendingTrade();
    }
  }

  void _applyTrade(TradeOffer offer, {bool log = false}) {
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
    if (log) _recordTrade(offer);
  }

  void _queueTradeOffer(TradeOffer offer) {
    final inbox = [...state.tradeInbox];
    final id = offer.id ?? _tradeId();
    final normalized = offer.id == null
        ? TradeOffer(
            id: id,
            fromTeam: offer.fromTeam,
            toTeam: offer.toTeam,
            fromAssets: offer.fromAssets,
            toAssets: offer.toAssets,
          )
        : offer;
    final exists = inbox.any((o) => o.id == id);
    if (!exists) {
      inbox.add(normalized);
      state = state.copyWith(tradeInbox: inbox);
      if (state.pendingTrade == null) {
        state = state.copyWith(pendingTrade: normalized);
      }
    }
  }

  void _removeFromInbox(TradeOffer offer) {
    final inbox = [...state.tradeInbox]
      ..removeWhere((o) => (o.id ?? '') == (offer.id ?? ''));
    state = state.copyWith(tradeInbox: inbox);
  }

  void _advancePendingTrade() {
    if (state.pendingTrade != null) return;
    if (state.tradeInbox.isEmpty) return;
    state = state.copyWith(pendingTrade: state.tradeInbox.first);
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

  void _maybeOfferTrade() {
    if (state.isComplete) return;
    if (_tradeScheduledIndex == state.currentIndex) return;
    _tradeScheduledIndex = state.currentIndex;
    if (_rng.nextDouble() > _cpuTradeFrequency) return;

    final offersToTry = 1 + _rng.nextInt(3); // 1..3 offers per pick
    for (var i = 0; i < offersToTry; i++) {
      final offer = _generateTradeOffer();
      if (offer == null) continue;

      if (_tradeInvolvesUser(offer)) {
        _queueTradeOffer(offer);
        continue;
      }

      if (_cpuAccepts(offer) && _cpuAccepts(_swapOffer(offer))) {
        _applyTrade(offer, log: true);
      }
    }
  }

  TradeOffer? _generateTradeOffer() {
    if (state.order.isEmpty) return null;
    final teams =
        state.teams.map((t) => t.abbreviation.toUpperCase()).toList();
    if (teams.length < 2) return null;

    final isUserOffer = state.userTeams.isNotEmpty && _rng.nextDouble() < 0.45;
    final toTeam = isUserOffer
        ? state.userTeams[_rng.nextInt(state.userTeams.length)]
        : teams[_rng.nextInt(teams.length)];
    final partnerPool =
        teams.where((t) => t.toUpperCase() != toTeam.toUpperCase()).toList();
    if (partnerPool.isEmpty) return null;
    final fromTeam = partnerPool[_rng.nextInt(partnerPool.length)];

    final targetPick = _nextPickForTeam(toTeam);
    if (targetPick == null) return null;

    final laterPicks =
        _laterPicksForTeam(fromTeam, targetPick.pickOverall, 2);
    if (laterPicks.isEmpty) return null;

    final fromAssets = laterPicks.map((p) => TradeAsset.pick(p)).toList();
    if (fromAssets.length == 1) {
      fromAssets.add(
        TradeAsset.future(
          FuturePick(
            teamAbbr: fromTeam,
            year: state.year + 1,
            round: 2,
          ),
        ),
      );
    }

    final offer = TradeOffer(
      id: _tradeId(),
      fromTeam: fromTeam,
      toTeam: toTeam,
      fromAssets: fromAssets,
      toAssets: [TradeAsset.pick(targetPick)],
    );

    final contextPick = _contextPickFor(offer) ?? state.currentPick;
    if (contextPick == null) return null;
    final context = TradeContext(
      currentPick: contextPick,
      fromTeam: _teamByAbbr(offer.fromTeam),
      toTeam: _teamByAbbr(offer.toTeam),
      availableProspects: state.availableProspects,
      currentYear: state.year,
    );

    return _trades.accept(offer, context: context) ? offer : null;
  }

  DraftPick? _nextPickForTeam(String teamAbbr) {
    for (var i = state.currentIndex; i < state.order.length; i++) {
      final pick = state.order[i];
      if (pick.teamAbbr.toUpperCase() == teamAbbr.toUpperCase()) {
        return pick;
      }
    }
    return null;
  }

  List<DraftPick> _laterPicksForTeam(
    String teamAbbr,
    int afterOverall,
    int count,
  ) {
    final picks = <DraftPick>[];
    for (var i = state.currentIndex; i < state.order.length; i++) {
      final pick = state.order[i];
      if (pick.pickOverall <= afterOverall) continue;
      if (pick.teamAbbr.toUpperCase() != teamAbbr.toUpperCase()) continue;
      picks.add(pick);
      if (picks.length >= count) break;
    }
    return picks;
  }

  bool _tradeInvolvesUser(TradeOffer offer) {
    return state.userTeams
        .map((t) => t.toUpperCase())
        .contains(offer.toTeam.toUpperCase());
  }

  bool _cpuAccepts(TradeOffer offer) {
    final contextPick = _contextPickFor(offer) ?? state.currentPick;
    if (contextPick == null) return false;
    final context = TradeContext(
      currentPick: contextPick,
      fromTeam: _teamByAbbr(offer.fromTeam),
      toTeam: _teamByAbbr(offer.toTeam),
      availableProspects: state.availableProspects,
      currentYear: state.year,
    );
    return _trades.accept(
      offer,
      context: context,
      thresholdAdjustment: _cpuTradeStrictness,
    );
  }

  TradeOffer _swapOffer(TradeOffer offer) {
    return TradeOffer(
      id: offer.id,
      fromTeam: offer.toTeam,
      toTeam: offer.fromTeam,
      fromAssets: offer.toAssets,
      toAssets: offer.fromAssets,
    );
  }

  void _recordTrade(TradeOffer offer) {
    final fromList = offer.fromAssets.map(_assetLabel).join(', ');
    final toList = offer.toAssets.map(_assetLabel).join(', ');
    final summary = '${offer.fromTeam} → ${offer.toTeam}: $fromList for $toList';
    final log = [
      ...state.tradeLog,
      TradeLogEntry(
        summary: summary,
        fromTeam: offer.fromTeam,
        toTeam: offer.toTeam,
      ),
    ];
    state = state.copyWith(
      tradeLog: log,
      tradeLogVersion: state.tradeLogVersion + 1,
    );
  }

  String _assetLabel(TradeAsset asset) {
    final pick = asset.pick;
    if (pick != null) {
      return 'P${pick.pickOverall} (R${pick.round}.${pick.pickInRound}) ${pick.teamAbbr}';
    }
    final future = asset.futurePick!;
    return '${future.year} R${future.round} ${future.teamAbbr}';
  }

  String _tradeId() {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final salt = _rng.nextInt(1 << 32);
    return '${stamp}_$salt';
  }

  @override
  void dispose() {
    _cpuTimer?.cancel();
    _clock.stop();
    super.dispose();
  }
}
