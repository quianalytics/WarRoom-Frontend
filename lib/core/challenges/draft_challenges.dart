import '../../features/draft/logic/draft_state.dart';
import '../../features/draft/models/trade.dart';

enum ChallengeDifficulty { easy, medium, hard, elite }

class DraftChallenge {
  final String id;
  final String title;
  final String description;
  final ChallengeDifficulty difficulty;
  final bool Function(DraftState state) isComplete;

  const DraftChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.isComplete,
  });
}

class DraftChallenges {
  static const List<DraftChallenge> all = [
    DraftChallenge(
      id: 'first_pick',
      title: 'First Strike',
      description: 'Make your first user pick.',
      difficulty: ChallengeDifficulty.easy,
      isComplete: _firstPick,
    ),
    DraftChallenge(
      id: 'finish_draft',
      title: 'Finish the Job',
      description: 'Complete a full draft.',
      difficulty: ChallengeDifficulty.easy,
      isComplete: _finishDraft,
    ),
    DraftChallenge(
      id: 'trade_once',
      title: 'Deal Maker',
      description: 'Complete a trade involving your team.',
      difficulty: ChallengeDifficulty.easy,
      isComplete: _tradeOnce,
    ),
    DraftChallenge(
      id: 'trade_three',
      title: 'Wheeler & Dealer',
      description: 'Complete 3 trades involving your team.',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _tradeThree,
    ),
    DraftChallenge(
      id: 'trade_five',
      title: 'Trade Typhoon',
      description: 'Complete 5 trades involving your team.',
      difficulty: ChallengeDifficulty.hard,
      isComplete: _tradeFive,
    ),
    DraftChallenge(
      id: 'trade_seven',
      title: 'Trade Tornado',
      description: 'Complete 7 trades involving your team.',
      difficulty: ChallengeDifficulty.elite,
      isComplete: _tradeSeven,
    ),
    DraftChallenge(
      id: 'trade_up',
      title: 'Aggressive Climb',
      description: 'Trade up to an earlier pick.',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _tradeUp,
    ),
    DraftChallenge(
      id: 'trade_down',
      title: 'Value Hunter',
      description: 'Trade down and add assets.',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _tradeDown,
    ),
    DraftChallenge(
      id: 'steal_10',
      title: 'Steal of the Draft',
      description: 'Draft a player ranked 10+ spots higher than the pick.',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _steal10,
    ),
    DraftChallenge(
      id: 'steal_20',
      title: 'Grand Theft',
      description: 'Draft a player ranked 20+ spots higher than the pick.',
      difficulty: ChallengeDifficulty.hard,
      isComplete: _steal20,
    ),
    DraftChallenge(
      id: 'steal_30',
      title: 'Heist of the Year',
      description: 'Draft a player ranked 30+ spots higher than the pick.',
      difficulty: ChallengeDifficulty.elite,
      isComplete: _steal30,
    ),
    DraftChallenge(
      id: 'reach_10',
      title: 'Bold Swing',
      description: 'Draft a player 10+ spots earlier than their rank.',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _reach10,
    ),
    DraftChallenge(
      id: 'reach_20',
      title: 'Big Reach',
      description: 'Draft a player 20+ spots earlier than their rank.',
      difficulty: ChallengeDifficulty.hard,
      isComplete: _reach20,
    ),
    DraftChallenge(
      id: 'need_round1',
      title: 'Need It Now',
      description: 'Draft a top need in Round 1.',
      difficulty: ChallengeDifficulty.easy,
      isComplete: _needRound1,
    ),
    DraftChallenge(
      id: 'need_two_rounds',
      title: 'Needs Locked',
      description: 'Fill two team needs in the first two rounds.',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _needTwoRounds,
    ),
    DraftChallenge(
      id: 'qb_round1',
      title: 'Signal Caller',
      description: 'Draft a QB in Round 1.',
      difficulty: ChallengeDifficulty.easy,
      isComplete: _qbRound1,
    ),
    DraftChallenge(
      id: 'trenches_round1',
      title: 'Build the Wall',
      description: 'Draft a trench player in Round 1 (OT/IOL/DL/EDGE).',
      difficulty: ChallengeDifficulty.easy,
      isComplete: _trenchesRound1,
    ),
    DraftChallenge(
      id: 'trenches_two_rounds',
      title: 'Wall Builder',
      description: 'Draft trench players in both Round 1 and Round 2.',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _trenchesTwoRounds,
    ),
    DraftChallenge(
      id: 'db_round1',
      title: 'No Fly Zone',
      description: 'Draft a CB or S in Round 1.',
      difficulty: ChallengeDifficulty.easy,
      isComplete: _dbRound1,
    ),
    DraftChallenge(
      id: 'db_double',
      title: 'Shut Down',
      description: 'Draft two defensive backs in the first two rounds.',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _dbDouble,
    ),
    DraftChallenge(
      id: 'double_dip',
      title: 'Double Dip',
      description: 'Make two picks within a single round.',
      difficulty: ChallengeDifficulty.hard,
      isComplete: _doubleDip,
    ),
    DraftChallenge(
      id: 'two_firsts',
      title: 'Extra First',
      description: 'Hold 2+ first-round picks.',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _twoFirsts,
    ),
    DraftChallenge(
      id: 'four_picks_top_100',
      title: 'Top 100 Fleet',
      description: 'Make four picks inside the top 100.',
      difficulty: ChallengeDifficulty.hard,
      isComplete: _top100Fleet,
    ),
    DraftChallenge(
      id: 'round1_spree',
      title: 'Round 1 Spree',
      description: 'Hold 3+ first-round picks.',
      difficulty: ChallengeDifficulty.elite,
      isComplete: _round1Spree,
    ),
    DraftChallenge(
      id: 'value_class',
      title: 'Value Class',
      description: 'Finish with an average value grade of B+ or better.',
      difficulty: ChallengeDifficulty.hard,
      isComplete: _valueClass,
    ),
    DraftChallenge(
      id: 'no_trades',
      title: 'Stand Pat',
      description: 'Finish the draft with zero user trades.',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _noTrades,
    ),
    DraftChallenge(
      id: 'five_picks',
      title: 'Deep Class',
      description: 'Make 5 or more user picks.',
      difficulty: ChallengeDifficulty.easy,
      isComplete: _fivePicks,
    ),
    DraftChallenge(
      id: 'seven_picks',
      title: 'Full Haul',
      description: 'Make 7 or more user picks.',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _sevenPicks,
    ),
    DraftChallenge(
      id: 'top50_triplet',
      title: 'Top 50 Trio',
      description: 'Make three picks inside the top 50.',
      difficulty: ChallengeDifficulty.hard,
      isComplete: _top50Triplet,
    ),
    DraftChallenge(
      id: 'position_diversity',
      title: 'Balanced Board',
      description: 'Draft 5 different positions.',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _positionDiversity,
    ),
    DraftChallenge(
      id: 'position_diversity_plus',
      title: 'Deep Variety',
      description: 'Draft 7 different positions.',
      difficulty: ChallengeDifficulty.hard,
      isComplete: _positionDiversityPlus,
    ),
    DraftChallenge(
      id: 'two_steals',
      title: 'Double Steal',
      description: 'Draft two players ranked 10+ spots higher than the pick.',
      difficulty: ChallengeDifficulty.hard,
      isComplete: _twoSteals,
    ),
    DraftChallenge(
      id: 'three_needs',
      title: 'Needs Master',
      description: 'Fill three team needs across the draft.',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _threeNeeds,
    ),
    DraftChallenge(
      id: 'no_need_misses',
      title: 'Needs Perfect',
      description: 'Fill every listed need for your team.',
      difficulty: ChallengeDifficulty.elite,
      isComplete: _noNeedMisses,
    ),
    DraftChallenge(
      id: 'needs_four',
      title: 'Needs Overload',
      description: 'Fill four team needs across the draft.',
      difficulty: ChallengeDifficulty.hard,
      isComplete: _needsFour,
    ),
    DraftChallenge(
      id: 'two_trenches',
      title: 'Trench Warfare',
      description: 'Draft two trench players (OT/IOL/DL/EDGE).',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _twoTrenches,
    ),
    DraftChallenge(
      id: 'three_defense',
      title: 'Defensive Draft',
      description: 'Draft three defensive players.',
      difficulty: ChallengeDifficulty.easy,
      isComplete: _threeDefense,
    ),
    DraftChallenge(
      id: 'three_offense',
      title: 'Offensive Focus',
      description: 'Draft three offensive players.',
      difficulty: ChallengeDifficulty.easy,
      isComplete: _threeOffense,
    ),
    DraftChallenge(
      id: 'offense_surge',
      title: 'Offense Surge',
      description: 'Draft five offensive players.',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _offenseSurge,
    ),
    DraftChallenge(
      id: 'qb_and_wr',
      title: 'New Duo',
      description: 'Draft a QB and a WR in the same class.',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _qbAndWr,
    ),
    DraftChallenge(
      id: 'secondary_double',
      title: 'Lockdown',
      description: 'Draft two DBs (CB/S).',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _secondaryDouble,
    ),
    DraftChallenge(
      id: 'secondary_triple',
      title: 'Air Tight',
      description: 'Draft three DBs (CB/S).',
      difficulty: ChallengeDifficulty.hard,
      isComplete: _secondaryTriple,
    ),
    DraftChallenge(
      id: 'value_round1_2',
      title: 'Hot Start',
      description: 'Average a B+ or better across Rounds 1–2.',
      difficulty: ChallengeDifficulty.hard,
      isComplete: _valueRound1_2,
    ),
    DraftChallenge(
      id: 'late_steal',
      title: 'Late Gem',
      description: 'Draft a player ranked 30+ spots higher in Round 4+.',
      difficulty: ChallengeDifficulty.elite,
      isComplete: _lateSteal,
    ),
    DraftChallenge(
      id: 'late_round_specialist',
      title: 'Day 3 Gem',
      description: 'Draft a Round 6+ player ranked 25+ spots higher.',
      difficulty: ChallengeDifficulty.elite,
      isComplete: _lateRoundSpecialist,
    ),
    DraftChallenge(
      id: 'two_teams',
      title: 'Two-Front GM',
      description: 'Control 2+ teams and complete their first-round picks.',
      difficulty: ChallengeDifficulty.elite,
      isComplete: _twoTeams,
    ),
    DraftChallenge(
      id: 'first_round_value',
      title: 'Round 1 Win',
      description: 'Draft a Round 1 player ranked 8+ spots higher.',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _firstRoundValue,
    ),
    DraftChallenge(
      id: 'late_round_lock',
      title: 'Late Round Lock',
      description: 'Draft a Round 5+ player ranked 20+ spots higher.',
      difficulty: ChallengeDifficulty.hard,
      isComplete: _lateRoundLock,
    ),
    DraftChallenge(
      id: 'late_round_double',
      title: 'Day 3 Double',
      description: 'Draft two Round 5+ players ranked 15+ spots higher.',
      difficulty: ChallengeDifficulty.hard,
      isComplete: _lateRoundDouble,
    ),
    DraftChallenge(
      id: 'positional_run_survive',
      title: 'Run Survivor',
      description: 'Draft 2+ needs after a position run (last 6 picks).',
      difficulty: ChallengeDifficulty.elite,
      isComplete: _runSurvivor,
    ),
    DraftChallenge(
      id: 'zero_reaches',
      title: 'No Reaches',
      description: 'Complete the draft with no picks 10+ spots early.',
      difficulty: ChallengeDifficulty.hard,
      isComplete: _zeroReaches,
    ),
    DraftChallenge(
      id: 'back_to_back',
      title: 'Back-to-Back',
      description: 'Make consecutive picks in the draft order.',
      difficulty: ChallengeDifficulty.hard,
      isComplete: _backToBack,
    ),
    DraftChallenge(
      id: 'three_rounds_in_a_row',
      title: 'Round Regular',
      description: 'Make picks in three consecutive rounds.',
      difficulty: ChallengeDifficulty.medium,
      isComplete: _threeRoundsInRow,
    ),
  ];

  static DraftChallenge dailyChallengeFor(DateTime date) {
    final start = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(start).inDays + 1;
    return all[dayOfYear % all.length];
  }

  static DraftChallenge? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  static Set<String> evaluate(DraftState state) {
    return all
        .where((c) => c.isComplete(state))
        .map((c) => c.id)
        .toSet();
  }

  static Set<String> _userTeams(DraftState state) =>
      state.userTeams.map((t) => t.toUpperCase()).toSet();

  static List<PickResult> _userPicks(DraftState state) {
    final users = _userTeams(state);
    return state.picksMade
        .where((p) => users.contains(p.teamAbbr.toUpperCase()))
        .toList();
  }

  static List<TradeLogEntry> _userTrades(DraftState state) {
    final users = _userTeams(state);
    return state.tradeLog
        .where((t) =>
            users.contains(t.fromTeam.toUpperCase()) ||
            users.contains(t.toTeam.toUpperCase()))
        .toList();
  }

  static bool _firstPick(DraftState state) => _userPicks(state).isNotEmpty;
  static bool _finishDraft(DraftState state) => state.isComplete;
  static bool _tradeOnce(DraftState state) => _userTrades(state).isNotEmpty;
  static bool _tradeThree(DraftState state) => _userTrades(state).length >= 3;
  static bool _tradeFive(DraftState state) => _userTrades(state).length >= 5;
  static bool _tradeSeven(DraftState state) => _userTrades(state).length >= 7;

  static bool _tradeUp(DraftState state) {
    return _userTrades(state).any((trade) {
      final to = trade.toTeam.toUpperCase();
      final from = trade.fromTeam.toUpperCase();
      final userTeams = _userTeams(state);
      if (!userTeams.contains(to) && !userTeams.contains(from)) return false;
      final incoming = userTeams.contains(to) ? trade.fromAssets : trade.toAssets;
      final outgoing = userTeams.contains(to) ? trade.toAssets : trade.fromAssets;
      if (incoming.isEmpty || outgoing.isEmpty) return false;
      final bestIncoming = _minOverall(incoming);
      final bestOutgoing = _minOverall(outgoing);
      return bestIncoming < bestOutgoing;
    });
  }

  static bool _tradeDown(DraftState state) {
    return _userTrades(state).any((trade) {
      final to = trade.toTeam.toUpperCase();
      final from = trade.fromTeam.toUpperCase();
      final userTeams = _userTeams(state);
      if (!userTeams.contains(to) && !userTeams.contains(from)) return false;
      final incoming = userTeams.contains(to) ? trade.fromAssets : trade.toAssets;
      final outgoing = userTeams.contains(to) ? trade.toAssets : trade.fromAssets;
      if (incoming.isEmpty || outgoing.isEmpty) return false;
      final bestIncoming = _minOverall(incoming);
      final bestOutgoing = _minOverall(outgoing);
      return bestIncoming > bestOutgoing;
    });
  }

  static bool _steal10(DraftState state) =>
      _userPicks(state).any((p) => _delta(p) >= 10);
  static bool _steal20(DraftState state) =>
      _userPicks(state).any((p) => _delta(p) >= 20);
  static bool _steal30(DraftState state) =>
      _userPicks(state).any((p) => _delta(p) >= 30);
  static bool _reach10(DraftState state) =>
      _userPicks(state).any((p) => _delta(p) <= -10);
  static bool _reach20(DraftState state) =>
      _userPicks(state).any((p) => _delta(p) <= -20);

  static bool _needRound1(DraftState state) {
    final users = _userTeams(state);
    for (final pr in _userPicks(state)) {
      if (pr.pick.round != 1) continue;
      final team = state.teams.firstWhere(
        (t) => t.abbreviation.toUpperCase() == pr.teamAbbr.toUpperCase(),
        orElse: () => state.teams.first,
      );
      final needs = (team.needs ?? []).map((e) => e.toUpperCase()).toList();
      if (needs.contains(pr.prospect.position.toUpperCase())) {
        return true;
      }
    }
    return false;
  }

  static bool _needTwoRounds(DraftState state) {
    final users = _userTeams(state);
    final early = _userPicks(state)
        .where((p) => p.pick.round <= 2)
        .toList();
    var matches = 0;
    for (final pr in early) {
      final team = state.teams.firstWhere(
        (t) => t.abbreviation.toUpperCase() == pr.teamAbbr.toUpperCase(),
        orElse: () => state.teams.first,
      );
      final needs = (team.needs ?? []).map((e) => e.toUpperCase()).toList();
      if (needs.contains(pr.prospect.position.toUpperCase())) {
        matches += 1;
      }
    }
    return matches >= 2;
  }

  static bool _qbRound1(DraftState state) =>
      _userPicks(state)
          .any((p) => p.pick.round == 1 && p.prospect.position.toUpperCase() == 'QB');

  static bool _trenchesRound1(DraftState state) {
    const trenches = {'OT', 'IOL', 'DL', 'EDGE', 'OL', 'DT'};
    return _userPicks(state).any(
      (p) => p.pick.round == 1 && trenches.contains(p.prospect.position.toUpperCase()),
    );
  }

  static bool _trenchesTwoRounds(DraftState state) {
    const trenches = {'OT', 'IOL', 'DL', 'EDGE', 'OL', 'DT'};
    final r1 = _userPicks(state)
        .where((p) => p.pick.round == 1)
        .any((p) => trenches.contains(p.prospect.position.toUpperCase()));
    final r2 = _userPicks(state)
        .where((p) => p.pick.round == 2)
        .any((p) => trenches.contains(p.prospect.position.toUpperCase()));
    return r1 && r2;
  }

  static bool _dbRound1(DraftState state) {
    const db = {'CB', 'S'};
    return _userPicks(state).any(
      (p) => p.pick.round == 1 && db.contains(p.prospect.position.toUpperCase()),
    );
  }

  static bool _dbDouble(DraftState state) {
    const db = {'CB', 'S'};
    final early = _userPicks(state).where((p) => p.pick.round <= 2);
    final count =
        early.where((p) => db.contains(p.prospect.position.toUpperCase())).length;
    return count >= 2;
  }

  static bool _doubleDip(DraftState state) {
    final picks = _userPicks(state);
    final counts = <int, int>{};
    for (final pr in picks) {
      counts[pr.pick.round] = (counts[pr.pick.round] ?? 0) + 1;
    }
    return counts.values.any((v) => v >= 2);
  }

  static bool _twoFirsts(DraftState state) {
    final count = _userPicks(state).where((p) => p.pick.round == 1).length;
    return count >= 2;
  }

  static bool _round1Spree(DraftState state) {
    final count = _userPicks(state).where((p) => p.pick.round == 1).length;
    return count >= 3;
  }

  static bool _top100Fleet(DraftState state) {
    final count =
        _userPicks(state).where((p) => p.pick.pickOverall <= 100).length;
    return count >= 4;
  }

  static bool _valueClass(DraftState state) {
    final picks = _userPicks(state);
    if (picks.isEmpty || !state.isComplete) return false;
    final avgDelta =
        picks.fold<double>(0, (s, p) => s + _delta(p)) / picks.length;
    return avgDelta >= 3;
  }

  static bool _noTrades(DraftState state) {
    if (!state.isComplete) return false;
    return _userTrades(state).isEmpty;
  }

  static bool _fivePicks(DraftState state) => _userPicks(state).length >= 5;
  static bool _sevenPicks(DraftState state) => _userPicks(state).length >= 7;

  static bool _top50Triplet(DraftState state) {
    final count =
        _userPicks(state).where((p) => p.pick.pickOverall <= 50).length;
    return count >= 3;
  }

  static bool _positionDiversity(DraftState state) {
    final positions = _userPicks(state)
        .map((p) => p.prospect.position.toUpperCase())
        .toSet();
    return positions.length >= 5;
  }

  static bool _positionDiversityPlus(DraftState state) {
    final positions = _userPicks(state)
        .map((p) => p.prospect.position.toUpperCase())
        .toSet();
    return positions.length >= 7;
  }

  static bool _twoSteals(DraftState state) {
    final steals =
        _userPicks(state).where((p) => _delta(p) >= 10).length;
    return steals >= 2;
  }

  static bool _threeNeeds(DraftState state) {
    var matches = 0;
    for (final pr in _userPicks(state)) {
      final team = state.teams.firstWhere(
        (t) => t.abbreviation.toUpperCase() == pr.teamAbbr.toUpperCase(),
        orElse: () => state.teams.first,
      );
      final needs = (team.needs ?? []).map((e) => e.toUpperCase()).toList();
      if (needs.contains(pr.prospect.position.toUpperCase())) {
        matches += 1;
      }
    }
    return matches >= 3;
  }

  static bool _noNeedMisses(DraftState state) {
    final needs = _userTeams(state)
        .map((abbr) => state.teams.firstWhere(
              (t) => t.abbreviation.toUpperCase() == abbr,
              orElse: () => state.teams.first,
            ))
        .expand((t) => t.needs ?? const <String>[])
        .map((n) => n.toUpperCase())
        .toSet();
    if (needs.isEmpty) return false;
    final drafted = _userPicks(state)
        .map((p) => p.prospect.position.toUpperCase())
        .toSet();
    return needs.difference(drafted).isEmpty;
  }

  static bool _needsFour(DraftState state) {
    var matches = 0;
    for (final pr in _userPicks(state)) {
      final team = state.teams.firstWhere(
        (t) => t.abbreviation.toUpperCase() == pr.teamAbbr.toUpperCase(),
        orElse: () => state.teams.first,
      );
      final needs = (team.needs ?? []).map((e) => e.toUpperCase()).toList();
      if (needs.contains(pr.prospect.position.toUpperCase())) {
        matches += 1;
      }
    }
    return matches >= 4;
  }

  static bool _twoTrenches(DraftState state) {
    const trenches = {'OT', 'IOL', 'DL', 'EDGE', 'OL', 'DT'};
    final count = _userPicks(state)
        .where((p) => trenches.contains(p.prospect.position.toUpperCase()))
        .length;
    return count >= 2;
  }

  static bool _threeDefense(DraftState state) {
    const defense = {'CB', 'S', 'LB', 'DL', 'DT', 'EDGE'};
    final count = _userPicks(state)
        .where((p) => defense.contains(p.prospect.position.toUpperCase()))
        .length;
    return count >= 3;
  }

  static bool _threeOffense(DraftState state) {
    const offense = {'QB', 'RB', 'WR', 'TE', 'OT', 'IOL', 'OL'};
    final count = _userPicks(state)
        .where((p) => offense.contains(p.prospect.position.toUpperCase()))
        .length;
    return count >= 3;
  }

  static bool _offenseSurge(DraftState state) {
    const offense = {'QB', 'RB', 'WR', 'TE', 'OT', 'IOL', 'OL'};
    final count = _userPicks(state)
        .where((p) => offense.contains(p.prospect.position.toUpperCase()))
        .length;
    return count >= 5;
  }

  static bool _qbAndWr(DraftState state) {
    var hasQb = false;
    var hasWr = false;
    for (final pr in _userPicks(state)) {
      final pos = pr.prospect.position.toUpperCase();
      if (pos == 'QB') hasQb = true;
      if (pos == 'WR') hasWr = true;
    }
    return hasQb && hasWr;
  }

  static bool _secondaryDouble(DraftState state) {
    const secondary = {'CB', 'S'};
    final count = _userPicks(state)
        .where((p) => secondary.contains(p.prospect.position.toUpperCase()))
        .length;
    return count >= 2;
  }

  static bool _secondaryTriple(DraftState state) {
    const secondary = {'CB', 'S'};
    final count = _userPicks(state)
        .where((p) => secondary.contains(p.prospect.position.toUpperCase()))
        .length;
    return count >= 3;
  }

  static bool _valueRound1_2(DraftState state) {
    final picks = _userPicks(state)
        .where((p) => p.pick.round <= 2)
        .toList();
    if (picks.isEmpty) return false;
    final avgDelta =
        picks.fold<double>(0, (s, p) => s + _delta(p)) / picks.length;
    return avgDelta >= 3;
  }

  static bool _lateSteal(DraftState state) {
    return _userPicks(state).any((p) {
      if (p.pick.round < 4) return false;
      return _delta(p) >= 30;
    });
  }

  static bool _lateRoundSpecialist(DraftState state) {
    return _userPicks(state).any((p) {
      if (p.pick.round < 6) return false;
      return _delta(p) >= 25;
    });
  }

  static bool _twoTeams(DraftState state) {
    if (state.userTeams.length < 2) return false;
    final firstRound = _userPicks(state)
        .where((p) => p.pick.round == 1)
        .map((p) => p.teamAbbr.toUpperCase())
        .toSet();
    return firstRound.containsAll(
      state.userTeams.map((t) => t.toUpperCase()).toSet(),
    );
  }

  static bool _firstRoundValue(DraftState state) {
    return _userPicks(state).any(
      (p) => p.pick.round == 1 && _delta(p) >= 8,
    );
  }

  static bool _lateRoundLock(DraftState state) {
    return _userPicks(state).any(
      (p) => p.pick.round >= 5 && _delta(p) >= 20,
    );
  }

  static bool _lateRoundDouble(DraftState state) {
    final count = _userPicks(state)
        .where((p) => p.pick.round >= 5 && _delta(p) >= 15)
        .length;
    return count >= 2;
  }

  static bool _runSurvivor(DraftState state) {
    final recent = state.picksMade.reversed.take(6).toList();
    if (recent.length < 4) return false;
    final counts = <String, int>{};
    for (final pr in recent) {
      final pos = pr.prospect.position.toUpperCase();
      counts[pos] = (counts[pos] ?? 0) + 1;
    }
    final hottest = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (hottest.isEmpty || hottest.first.value < 3) return false;
    final hotPos = hottest.first.key;
    final needs = _userTeams(state)
        .map((abbr) => state.teams.firstWhere(
              (t) => t.abbreviation.toUpperCase() == abbr,
              orElse: () => state.teams.first,
            ))
        .expand((t) => t.needs ?? const <String>[])
        .map((n) => n.toUpperCase())
        .toSet();
    if (!needs.contains(hotPos)) return false;
    final needMatches = _userPicks(state)
        .where((p) => needs.contains(p.prospect.position.toUpperCase()))
        .length;
    return needMatches >= 2;
  }

  static bool _zeroReaches(DraftState state) {
    if (!state.isComplete) return false;
    return _userPicks(state).every((p) => _delta(p) > -10);
  }

  static bool _backToBack(DraftState state) {
    final picks = _userPicks(state)
        .map((p) => p.pick.pickOverall)
        .toList()
      ..sort();
    for (var i = 1; i < picks.length; i += 1) {
      if (picks[i] == picks[i - 1] + 1) return true;
    }
    return false;
  }

  static bool _threeRoundsInRow(DraftState state) {
    final rounds = _userPicks(state)
        .map((p) => p.pick.round)
        .toSet()
        .toList()
      ..sort();
    var streak = 1;
    for (var i = 1; i < rounds.length; i += 1) {
      if (rounds[i] == rounds[i - 1] + 1) {
        streak += 1;
        if (streak >= 3) return true;
      } else {
        streak = 1;
      }
    }
    return false;
  }

  static int _delta(PickResult pr) {
    final rank = pr.prospect.rank;
    if (rank == null) return 0;
    return pr.pick.pickOverall - rank;
  }

  static int _minOverall(List<TradeAsset> assets) {
    final values = assets
        .map((a) => a.pickOverall ?? 999999)
        .toList();
    values.sort();
    return values.first;
  }
}
