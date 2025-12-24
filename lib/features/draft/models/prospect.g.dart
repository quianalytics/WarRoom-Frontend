// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prospect.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Prospect _$ProspectFromJson(Map<String, dynamic> json) => Prospect(
  id: _idFromJson(json['_id']),
  name: _stringFromJson(json['name']),
  position: _stringFromJson(json['position']),
  college: _stringFromJson(json['college']),
  rank: _intFromJson(json['rank']),
);

Map<String, dynamic> _$ProspectToJson(Prospect instance) => <String, dynamic>{
  '_id': instance.id,
  'name': instance.name,
  'position': instance.position,
  'college': instance.college,
  'rank': instance.rank,
};
