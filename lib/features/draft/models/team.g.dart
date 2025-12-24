// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Team _$TeamFromJson(Map<String, dynamic> json) => Team(
  teamId: json['teamId'] as String,
  name: json['name'] as String,
  city: json['city'] as String?,
  abbreviation: json['abbreviation'] as String,
  conference: json['conference'] as String,
  division: json['division'] as String,
  needs: (json['needs'] as List<dynamic>?)?.map((e) => e as String).toList(),
  colors: (json['colors'] as List<dynamic>?)?.map((e) => e as String).toList(),
  logoUrl: json['logoUrl'] as String?,
);

Map<String, dynamic> _$TeamToJson(Team instance) => <String, dynamic>{
  'teamId': instance.teamId,
  'name': instance.name,
  'city': instance.city,
  'abbreviation': instance.abbreviation,
  'conference': instance.conference,
  'division': instance.division,
  'needs': instance.needs,
  'colors': instance.colors,
  'logoUrl': instance.logoUrl,
};
