List<String>? _stringList(dynamic v) {
  if (v == null) return null;
  if (v is List) {
    return v.where((e) => e != null).map((e) => e.toString()).toList();
  }
  return null;
}

class TeamNeedsEntry {
  final String teamAbbr;
  final int year;
  final List<String> needs;

  TeamNeedsEntry({
    required this.teamAbbr,
    required this.year,
    required this.needs,
  });

  factory TeamNeedsEntry.fromJson(Map<String, dynamic> json) {
    final needs = _stringList(json['needs']) ?? const <String>[];
    return TeamNeedsEntry(
      teamAbbr: (json['teamAbbr'] ?? '').toString(),
      year: json['year'] is int ? json['year'] as int : int.tryParse('${json['year']}') ?? 0,
      needs: needs,
    );
  }
}
