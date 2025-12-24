import 'package:json_annotation/json_annotation.dart';

part 'prospect.g.dart';

String _idFromJson(dynamic v) {
  if (v == null) return '';
  // If backend sends {_id: "..."}, v is a string.
  if (v is String) return v;
  // If backend sends {_id: {"$oid":"..."}}
  if (v is Map && v[r'$oid'] is String) return v[r'$oid'] as String;
  return v.toString();
}

int? _intFromJson(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return int.tryParse(s);
}

String _stringFromJson(dynamic v) => (v ?? '').toString();

@JsonSerializable()
class Prospect {
  @JsonKey(name: '_id', fromJson: _idFromJson)
  final String id;

  @JsonKey(fromJson: _stringFromJson)
  final String name;

  @JsonKey(fromJson: _stringFromJson)
  final String position;

  @JsonKey(fromJson: _stringFromJson)
  final String? college;

  @JsonKey(fromJson: _intFromJson)
  final int? rank;

  Prospect({
    required this.id,
    required this.name,
    required this.position,
    this.college,
    this.rank,
  });

  factory Prospect.fromJson(Map<String, dynamic> json) => _$ProspectFromJson(json);
  Map<String, dynamic> toJson() => _$ProspectToJson(this);
}

