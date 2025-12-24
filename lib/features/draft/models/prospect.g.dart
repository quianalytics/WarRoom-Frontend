// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prospect.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Prospect _$ProspectFromJson(Map<String, dynamic> json) => Prospect(
  id: json['id'] as String,
  fullName: json['fullName'] as String,
  position: json['position'] as String,
  school: json['school'] as String?,
  consensusRank: (json['consensusRank'] as num?)?.toInt(),
);

Map<String, dynamic> _$ProspectToJson(Prospect instance) => <String, dynamic>{
  'id': instance.id,
  'fullName': instance.fullName,
  'position': instance.position,
  'school': instance.school,
  'consensusRank': instance.consensusRank,
};
