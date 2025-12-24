// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Team _$TeamFromJson(Map<String, dynamic> json) => Team(
  teamId: _str(json['teamId']),
  name: _str(json['name']),
  city: _str(json['city']),
  abbreviation: _str(json['abbreviation']),
  conference: _str(json['conference']),
  division: _str(json['division']),
  needs: _stringList(json['needs']),
  colors: _stringList(json['colors']),
  logoUrl: _str(json['logoUrl']),
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
