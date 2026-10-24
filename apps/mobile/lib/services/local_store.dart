import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
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

  // --- account / server ---
  String get apiBaseUrl =>
      _prefs.getString('apiBaseUrl') ?? ApiConfig.baseUrl;
  Future<void> setApiBaseUrl(String v) => _prefs.setString('apiBaseUrl', v);

  String get authToken => _prefs.getString('authToken') ?? '';
  Future<void> setAuthToken(String v) => _prefs.setString('authToken', v);

  String get authEmail => _prefs.getString('authEmail') ?? '';
  Future<void> setAuthEmail(String v) => _prefs.setString('authEmail', v);

  bool get offlineMode => _prefs.getBool('offlineMode') ?? false;
  Future<void> setOfflineMode(bool v) => _prefs.setBool('offlineMode', v);


  bool get signedIn => authToken.isNotEmpty || offlineMode;

  Future<void> signOut() async {
    await _prefs.remove('authToken');
    await _prefs.remove('authEmail');
    await _prefs.setBool('offlineMode', false);
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

  // --- trips ---
  List<Trip> get trips {
    final raw = _prefs.getString('trips');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveTrips(List<Trip> items) =>
      _prefs.setString('trips', jsonEncode(items.map((t) => t.toJson()).toList()));

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

  // --- auto-reminder state (ids derived from source messages) ---
  Set<String> _idSet(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return {};
    return (jsonDecode(raw) as List<dynamic>).map((e) => e as String).toSet();
  }

  Set<String> get doneAutoReminders => _idSet('doneAutoRem');
  Future<void> setDoneAutoReminder(String id, bool done) {
    final s = doneAutoReminders;
    done ? s.add(id) : s.remove(id);
    return _prefs.setString('doneAutoRem', jsonEncode(s.toList()));
  }

  Set<String> get dismissedAutoReminders => _idSet('dismissedAutoRem');
  Future<void> dismissAutoReminder(String id) {
    final s = dismissedAutoReminders..add(id);
    return _prefs.setString('dismissedAutoRem', jsonEncode(s.toList()));
  }

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
