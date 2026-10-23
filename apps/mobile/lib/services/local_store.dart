import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Lightweight JSON persistence on top of SharedPreferences.
class LocalStore {
  LocalStore._(this._prefs);
  final SharedPreferences _prefs;

  static LocalStore? _instance;
  static Future<LocalStore> instance() async {
    _instance ??= LocalStore._(await SharedPreferences.getInstance());
    return _instance!;
  }

  // --- onboarding / consent ---
  bool get onboarded => _prefs.getBool('onboarded') ?? false;
  Future<void> setOnboarded(bool v) => _prefs.setBool('onboarded', v);

  String get userName => _prefs.getString('userName') ?? '';
  Future<void> setUserName(String v) => _prefs.setString('userName', v);

  bool get recordingConsent => _prefs.getBool('recordingConsent') ?? false;
  Future<void> setRecordingConsent(bool v) =>
      _prefs.setBool('recordingConsent', v);

  // --- notes ---
  List<Note> get notes {
    final raw = _prefs.getString('notes');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveNotes(List<Note> notes) =>
      _prefs.setString('notes', jsonEncode(notes.map((n) => n.toJson()).toList()));

  // --- reminders ---
  List<Reminder> get reminders {
    final raw = _prefs.getString('reminders');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveReminders(List<Reminder> items) => _prefs.setString(
      'reminders', jsonEncode(items.map((r) => r.toJson()).toList()));

  // --- manual transactions (user-added) ---
  List<Txn> get manualTxns {
    final raw = _prefs.getString('manualTxns');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Txn.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveManualTxns(List<Txn> items) => _prefs.setString(
      'manualTxns', jsonEncode(items.map((t) => t.toJson()).toList()));

  // --- category overrides keyed by txn id ---
  Map<String, String> get categoryOverrides {
    final raw = _prefs.getString('catOverrides');
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as String));
  }

  Future<void> setCategoryOverride(String txnId, String category) {
    final map = categoryOverrides;
    map[txnId] = category;
    return _prefs.setString('catOverrides', jsonEncode(map));
  }
}
