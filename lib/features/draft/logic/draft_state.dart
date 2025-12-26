import '../models/draft_pick.dart';
import '../models/prospect.dart';
import '../models/team.dart';
import '../models/trade.dart';

const Object _noTrade = Object();
const Object _noTradeInbox = Object();
const Object _noTradeLog = Object();
const Object _noTradeLogVersion = Object();

class PickResult {
  final DraftPick pick;
  final String teamAbbr;
  final Prospect prospect;
  final DateTime madeAt;

  PickResult({
    required this.pick,
    required this.teamAbbr,
    required this.prospect,
    required this.madeAt,
  });

  Map<String, dynamic> toJson() => {
    'pick': pick.toJson(),
    'teamAbbr': teamAbbr,
    'prospect': prospect.toJson(),
    'madeAt': madeAt.toIso8601String(),
  };

  static PickResult fromJson(Map<String, dynamic> json) => PickResult(
    pick: DraftPick.fromJson(json['pick'] as Map<String, dynamic>),
    teamAbbr: (json['teamAbbr'] ?? '').toString(),
    prospect: Prospect.fromJson(json['prospect'] as Map<String, dynamic>),
    madeAt: DateTime.parse((json['madeAt'] ?? '').toString()),
  );
}

class DraftState {
  final bool loading;
  final String? error;

  final String draftId;
  final int year;
  final List<String> userTeams;

  final List<Team> teams;
  final List<DraftPick> order;

  final List<Prospect> availableProspects;
  final List<PickResult> picksMade;

  final int currentIndex;

  final int secondsRemaining;
  final bool clockRunning;
  final TradeOffer? pendingTrade;
  final List<TradeOffer> tradeInbox;
  final List<TradeLogEntry> tradeLog;
  final int tradeLogVersion;

  const DraftState({
    required this.loading,
    required this.error,
    required this.draftId,
    required this.year,
    required this.userTeams,
    required this.teams,
    required this.order,
    required this.availableProspects,
    required this.picksMade,
    required this.currentIndex,
    required this.secondsRemaining,
    required this.clockRunning,
    required this.pendingTrade,
    required this.tradeInbox,
    required this.tradeLog,
    required this.tradeLogVersion,
  });

  factory DraftState.initial() => const DraftState(
    loading: false,
    error: null,
    draftId: '',
    year: 2026,
    userTeams: [],
    teams: [],
    order: [],
    availableProspects: [],
    picksMade: [],
    currentIndex: 0,
    secondsRemaining: 600,
    clockRunning: false,
    pendingTrade: null,
    tradeInbox: const <TradeOffer>[],
    tradeLog: const <TradeLogEntry>[],
    tradeLogVersion: 0,
  );
  
  Map<String, dynamic> toJson() => {
    'draftId': draftId,
    'year': year,
    'userTeams': userTeams,
    'teams': teams.map((t) => t.toJson()).toList(),
    'order': order.map((p) => p.toJson()).toList(),
    'availableProspects': availableProspects.map((p) => p.toJson()).toList(),
    'picksMade': picksMade.map((p) => p.toJson()).toList(),
    'currentIndex': currentIndex,
    'secondsRemaining': secondsRemaining,
    'clockRunning': clockRunning,
  };

  static DraftState fromJson(Map<String, dynamic> json) => DraftState(
    loading: false,
    error: null,
    draftId: (json['draftId'] ?? '').toString(),
    year: json['year'] as int,
    userTeams: (json['userTeams'] as List).map((e) => e.toString()).toList(),
    teams: (json['teams'] as List)
        .map((e) => Team.fromJson(e as Map<String, dynamic>))
        .toList(),
    order: (json['order'] as List)
        .map((e) => DraftPick.fromJson(e as Map<String, dynamic>))
        .toList(),
    availableProspects: (json['availableProspects'] as List)
        .map((e) => Prospect.fromJson(e as Map<String, dynamic>))
        .toList(),
    picksMade: (json['picksMade'] as List)
        .map((e) => PickResult.fromJson(e as Map<String, dynamic>))
        .toList(),
    currentIndex: json['currentIndex'] as int,
    secondsRemaining: json['secondsRemaining'] as int,
    clockRunning: json['clockRunning'] as bool,
    pendingTrade: null,
    tradeInbox: const <TradeOffer>[],
    tradeLog: const <TradeLogEntry>[],
    tradeLogVersion: 0,
  );

  DraftPick? get currentPick =>
      (order.isNotEmpty && currentIndex < order.length)
      ? order[currentIndex]
      : null;
  String get onClockTeam => currentPick?.teamAbbr ?? '--';
  bool get isUserOnClock => userTeams.contains(onClockTeam);
  bool get isComplete => order.isNotEmpty && currentIndex >= order.length;

  DraftState copyWith({
    bool? loading,
    String? error,
    String? draftId,
    int? year,
    List<String>? userTeams,
    List<Team>? teams,
    List<DraftPick>? order,
    List<Prospect>? availableProspects,
    List<PickResult>? picksMade,
    int? currentIndex,
    int? secondsRemaining,
    bool? clockRunning,
    Object? pendingTrade = _noTrade,
    Object? tradeInbox = _noTradeInbox,
    Object? tradeLog = _noTradeLog,
    Object? tradeLogVersion = _noTradeLogVersion,
  }) {
    return DraftState(
      loading: loading ?? this.loading,
      error: error,
      draftId: draftId ?? this.draftId,
      year: year ?? this.year,
      userTeams: userTeams ?? this.userTeams,
      teams: teams ?? this.teams,
      order: order ?? this.order,
      availableProspects: availableProspects ?? this.availableProspects,
      picksMade: picksMade ?? this.picksMade,
      currentIndex: currentIndex ?? this.currentIndex,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      clockRunning: clockRunning ?? this.clockRunning,
      pendingTrade: identical(pendingTrade, _noTrade)
          ? this.pendingTrade
          : pendingTrade as TradeOffer?,
      tradeInbox: identical(tradeInbox, _noTradeInbox)
          ? this.tradeInbox
          : tradeInbox as List<TradeOffer>,
      tradeLog: identical(tradeLog, _noTradeLog)
          ? this.tradeLog
          : tradeLog as List<TradeLogEntry>,
      tradeLogVersion: identical(tradeLogVersion, _noTradeLogVersion)
          ? this.tradeLogVersion
          : tradeLogVersion as int,
    );
  }
}

class TradeLogEntry {
  final String summary;
  final String fromTeam;
  final String toTeam;

  const TradeLogEntry({
    required this.summary,
    required this.fromTeam,
    required this.toTeam,
  });
}
