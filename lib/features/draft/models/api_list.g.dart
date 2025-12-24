// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiListResponse<T> _$ApiListResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => ApiListResponse<T>(
  count: (json['count'] as num).toInt(),
  results: (json['results'] as List<dynamic>).map(fromJsonT).toList(),
);

Map<String, dynamic> _$ApiListResponseToJson<T>(
  ApiListResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'count': instance.count,
  'results': instance.results.map(toJsonT).toList(),
};
