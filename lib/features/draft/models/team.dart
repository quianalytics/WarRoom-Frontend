import 'package:json_annotation/json_annotation.dart';
part 'team.g.dart';

@JsonSerializable()
class Team {
  final String teamId;
  final String name;
  final String? city;
  final String abbreviation;
  final String conference;
  final String division;

  // stored as list in DB; if your API returns stringified JSON, adjust parsing
  final List<String>? needs;

  // optional extras
  final List<String>? colors;
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
