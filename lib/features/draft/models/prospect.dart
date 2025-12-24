import 'package:json_annotation/json_annotation.dart';
part 'prospect.g.dart';

@JsonSerializable()
class Prospect {
  final String id; // map from _id if needed
  final String fullName;
  final String position;
  final String? school;

  final int? consensusRank; // your big board rank

  Prospect({
    required this.id,
    required this.fullName,
    required this.position,
    this.school,
    this.consensusRank,
  });

  factory Prospect.fromJson(Map<String, dynamic> json) => _$ProspectFromJson(json);
  Map<String, dynamic> toJson() => _$ProspectToJson(this);
}
