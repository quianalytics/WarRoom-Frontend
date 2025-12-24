import 'package:json_annotation/json_annotation.dart';
part 'draft_pick.g.dart';

@JsonSerializable()
class DraftPick {
  final int year;
  final int round;
  final int pickOverall;
  final int pickInRound;

  final String teamAbbr;
  final String? team;
  final String originalTeamAbbr;

  final bool isCompensatory;

  DraftPick({
    required this.year,
    required this.round,
    required this.pickOverall,
    required this.pickInRound,
    required this.teamAbbr,
    this.team,
    required this.originalTeamAbbr,
    required this.isCompensatory,
  });

  factory DraftPick.fromJson(Map<String, dynamic> json) => _$DraftPickFromJson(json);
  Map<String, dynamic> toJson() => _$DraftPickToJson(this);

  String get label => 'Pick $pickOverall (R$round.$pickInRound)';
}
