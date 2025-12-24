import '../models/draft_pick.dart';
import '../models/prospect.dart';
import '../models/team.dart';

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

  final int year;
  final List<String> userTeams;

  final List<Team> teams;
  final List<DraftPick> order;

  final List<Prospect> availableProspects;
  final List<PickResult> picksMade;

  final int currentIndex;

  final int secondsRemaining;
  final bool clockRunning;

  const DraftState({
    required this.loading,
    required this.error,
    required this.year,
    required this.userTeams,
    required this.teams,
    required this.order,
    required this.availableProspects,
    required this.picksMade,
    required this.currentIndex,
    required this.secondsRemaining,
    required this.clockRunning,
  });

  factory DraftState.initial() => const DraftState(
    loading: false,
    error: null,
    year: 2026,
    userTeams: [],
    teams: [],
    order: [],
    availableProspects: [],
    picksMade: [],
    currentIndex: 0,
    secondsRemaining: 600,
    clockRunning: false,
  );
  
  Map<String, dynamic> toJson() => {
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
    int? year,
    List<String>? userTeams,
    List<Team>? teams,
    List<DraftPick>? order,
    List<Prospect>? availableProspects,
    List<PickResult>? picksMade,
    int? currentIndex,
    int? secondsRemaining,
    bool? clockRunning,
  }) {
    return DraftState(
      loading: loading ?? this.loading,
      error: error,
      year: year ?? this.year,
      userTeams: userTeams ?? this.userTeams,
      teams: teams ?? this.teams,
      order: order ?? this.order,
      availableProspects: availableProspects ?? this.availableProspects,
      picksMade: picksMade ?? this.picksMade,
      currentIndex: currentIndex ?? this.currentIndex,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      clockRunning: clockRunning ?? this.clockRunning,
    );
  }
}
