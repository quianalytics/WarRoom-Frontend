import 'package:json_annotation/json_annotation.dart';
part 'api_list.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ApiListResponse<T> {
  final int count;
  final List<T> results;

  ApiListResponse({required this.count, required this.results});

  factory ApiListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ApiListResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$ApiListResponseToJson(this, toJsonT);
}
