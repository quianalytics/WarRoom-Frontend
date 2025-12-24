// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prospect.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Prospect _$ProspectFromJson(Map<String, dynamic> json) => Prospect(
  id: _idFromJson(json['_id']),
  name: _stringFromJson(json['fullName']),
  position: _stringFromJson(json['position']),
  college: _stringFromJson(json['school']),
  rank: _intFromJson(json['consensusRank']),
);

Map<String, dynamic> _$ProspectToJson(Prospect instance) => <String, dynamic>{
  '_id': instance.id,
  'fullName': instance.name,
  'position': instance.position,
  'school': instance.college,
  'rank': instance.rank,
};
