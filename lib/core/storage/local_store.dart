import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static const _draftKeyPrefix = 'saved_draft_';
  static const _soundHapticsKey = 'sound_haptics_enabled';

  static Future<void> saveDraft(int year, Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_draftKeyPrefix$year', jsonEncode(json));
  }

  static Future<Map<String, dynamic>?> loadDraft(int year) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_draftKeyPrefix$year');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
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
}
