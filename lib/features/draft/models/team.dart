import 'package:json_annotation/json_annotation.dart';

part 'team.g.dart';

String _str(dynamic v) => (v ?? '').toString();

List<String>? _stringList(dynamic v) {
  if (v == null) return null;
  if (v is List) {
    return v.where((e) => e != null).map((e) => e.toString()).toList();
  }
  return null;
}

@JsonSerializable()
class Team {
  @JsonKey(fromJson: _str)
  final String teamId;

  @JsonKey(fromJson: _str)
  final String name;

  @JsonKey(fromJson: _str)
  final String? city;

  @JsonKey(fromJson: _str)
  final String abbreviation;

  @JsonKey(fromJson: _str)
  final String conference;

  @JsonKey(fromJson: _str)
  final String division;

  @JsonKey(fromJson: _stringList)
  final List<String>? needs;

  @JsonKey(fromJson: _stringList)
  final List<String>? colors;

  @JsonKey(fromJson: _str)
  final String? logoUrl;

  Team({
    required this.teamId,
    required this.name,
    this.city,
    required this.abbreviation,
    required this.conference,
    required this.division,
    this.needs,
    this.colors,
    this.logoUrl,
  });

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);
  Map<String, dynamic> toJson() => _$TeamToJson(this);
}
