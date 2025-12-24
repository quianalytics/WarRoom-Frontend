// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_pick.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DraftPick _$DraftPickFromJson(Map<String, dynamic> json) => DraftPick(
  year: (json['year'] as num).toInt(),
  round: (json['round'] as num).toInt(),
  pickOverall: (json['pickOverall'] as num).toInt(),
  pickInRound: (json['pickInRound'] as num).toInt(),
  teamAbbr: json['teamAbbr'] as String,
  team: json['team'] as String?,
  originalTeamAbbr: json['originalTeamAbbr'] as String,
  isCompensatory: json['isCompensatory'] as bool,
);

Map<String, dynamic> _$DraftPickToJson(DraftPick instance) => <String, dynamic>{
  'year': instance.year,
  'round': instance.round,
  'pickOverall': instance.pickOverall,
  'pickInRound': instance.pickInRound,
  'teamAbbr': instance.teamAbbr,
  'team': instance.team,
  'originalTeamAbbr': instance.originalTeamAbbr,
  'isCompensatory': instance.isCompensatory,
};
