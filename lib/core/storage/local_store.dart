import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static const _draftKeyPrefix = 'saved_draft_';
  static const _draftHistoryPrefix = 'draft_history_';
  static const _draftHistoryIndexKey = 'draft_history_index';
  static const _soundHapticsKey = 'sound_haptics_enabled';
  static const _tradePopupsKey = 'trade_popups_enabled';
  static const _lastActiveDateKey = 'last_active_date';
  static const _draftStreakKey = 'draft_streak_count';
  static const _badgeIdsKey = 'badge_ids';
  static const _dailyChallengePrefix = 'daily_challenge_completed_';

  static Future<void> saveDraft(int year, Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_draftKeyPrefix$year', jsonEncode(json));
  }

  static Future<void> saveDraftHistory(
    DraftHistoryEntry entry,
    Map<String, dynamic> json,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_draftHistoryPrefix${entry.id}', jsonEncode(json));

    final current = await loadDraftHistory();
    final previous = current.where((e) => e.id == entry.id).toList();
    final resolved = previous.isNotEmpty
        ? entry.copyWith(name: previous.first.name)
        : entry;
    final next = [
      resolved,
      ...current.where((e) => e.id != entry.id),
    ];
    await prefs.setString(
      _draftHistoryIndexKey,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }

  static Future<Map<String, dynamic>?> loadDraft(int year) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_draftKeyPrefix$year');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> loadDraftHistoryDraft(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_draftHistoryPrefix$id');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<List<DraftHistoryEntry>> loadDraftHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftHistoryIndexKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => DraftHistoryEntry.fromJson(e.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Future<void> renameDraftHistoryEntry({
    required String id,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await loadDraftHistory();
    final next = entries
        .map((e) => e.id == id ? e.copyWith(name: name) : e)
        .toList();
    await prefs.setString(
      _draftHistoryIndexKey,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> deleteDraftHistoryEntry(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_draftHistoryPrefix$id');
    final entries = await loadDraftHistory();
    final next = entries.where((e) => e.id != id).toList();
    await prefs.setString(
      _draftHistoryIndexKey,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> clearDraft(int year) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_draftKeyPrefix$year');
  }

  static Future<bool> hasDraft(int year) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_draftKeyPrefix$year');
  }

  static Future<void> setSoundHapticsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundHapticsKey, enabled);
  }

  static Future<bool> getSoundHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundHapticsKey) ?? true;
  }

  static Future<void> setTradePopupsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tradePopupsKey, enabled);
  }

  static Future<bool> getTradePopupsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tradePopupsKey) ?? true;
  }

  static Future<int> getDraftStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_draftStreakKey) ?? 0;
  }

  static Future<int> updateDraftStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = _dayKey(now);
    final lastKey = prefs.getString(_lastActiveDateKey);
    if (lastKey == todayKey) {
      return prefs.getInt(_draftStreakKey) ?? 0;
    }
    final streak = prefs.getInt(_draftStreakKey) ?? 0;
    final yesterdayKey = _dayKey(now.subtract(const Duration(days: 1)));
    final nextStreak = lastKey == yesterdayKey ? streak + 1 : 1;
    await prefs.setString(_lastActiveDateKey, todayKey);
    await prefs.setInt(_draftStreakKey, nextStreak);
    return nextStreak;
  }

  static String _dayKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  static Future<Set<String>> getBadgeIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_badgeIdsKey);
    return raw?.toSet() ?? <String>{};
  }

  static Future<void> addBadges(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getBadgeIds();
    current.addAll(ids);
    await prefs.setStringList(_badgeIdsKey, current.toList());
  }

  static Future<bool> isDailyChallengeCompleted(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_dailyChallengePrefix${_dayKey(date)}') ?? false;
  }

  static Future<void> markDailyChallengeCompleted(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_dailyChallengePrefix${_dayKey(date)}', true);
  }
}

class DraftHistoryEntry {
  final String id;
  final int year;
  final DateTime updatedAt;
  final int currentIndex;
  final int totalPicks;
  final List<String> userTeams;
  final String? name;

  const DraftHistoryEntry({
    required this.id,
    required this.year,
    required this.updatedAt,
    required this.currentIndex,
    required this.totalPicks,
    required this.userTeams,
    this.name,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'year': year,
    'updatedAt': updatedAt.toIso8601String(),
    'currentIndex': currentIndex,
    'totalPicks': totalPicks,
    'userTeams': userTeams,
    'name': name,
  };

  static DraftHistoryEntry fromJson(Map<String, dynamic> json) =>
      DraftHistoryEntry(
        id: (json['id'] ?? '').toString(),
        year: json['year'] as int,
        updatedAt: DateTime.parse((json['updatedAt'] ?? '').toString()),
        currentIndex: json['currentIndex'] as int,
        totalPicks: json['totalPicks'] as int,
        userTeams: (json['userTeams'] as List)
            .map((e) => e.toString())
            .toList(),
        name: (json['name'] ?? '').toString().isEmpty
            ? null
            : (json['name'] ?? '').toString(),
      );

  DraftHistoryEntry copyWith({
    String? name,
  }) {
    return DraftHistoryEntry(
      id: id,
      year: year,
      updatedAt: updatedAt,
      currentIndex: currentIndex,
      totalPicks: totalPicks,
      userTeams: userTeams,
      name: name ?? this.name,
    );
  }
}
