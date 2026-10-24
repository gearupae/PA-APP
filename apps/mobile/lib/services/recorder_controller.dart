import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'speech_service.dart';

/// Owns the always-ready continuous capture session. Auto-restarts after each
/// pause so one session is a running transcript; on stop it hands the
/// transcript to [onTranscript], which builds + saves the note. Foreground only.
class RecorderController extends ChangeNotifier {
  RecorderController({required this.onTranscript});

  /// Build + persist a note from the transcript; returns its id and the
  /// number of reminders created, or null if nothing was saved.
  final Future<({String id, int reminders})?> Function(String transcript)
      onTranscript;

  final SpeechService _speech = SpeechService();

  bool active = false;
  bool starting = false;
  bool _restarting = false;
  String live = '';
  String buffer = '';

  DateTime? _startedAt;
  Timer? _ticker;
  Duration elapsed = Duration.zero;
  String? lastSavedNoteId;
  int lastReminderCount = 0;

  String? get lastError => _speech.lastError;
  String get text => ('$buffer $live').trim();
  String get clock {
    final mm = elapsed.inMinutes.toString().padLeft(2, '0');
    final ss = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<bool> start() async {
    if (active || starting) return active;
    starting = true;
    notifyListeners();
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      starting = false;
      notifyListeners();
      return false;
    }
    final ok = await _speech.init(onStatus: _onStatus, onError: _onError);
    if (!ok) {
      starting = false;
      notifyListeners();
      return false;
    }
    await WakelockPlus.enable();
    _startedAt = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startedAt != null) {
        elapsed = DateTime.now().difference(_startedAt!);
        notifyListeners();
      }
    });
    active = true;
    starting = false;
    live = '';
    buffer = '';
    notifyListeners();
    await _speech.listen(onResult: _onResult);
    return true;
  }

  void _onResult(String t, bool finalResult) {
    live = t;
    if (finalResult && t.trim().isNotEmpty) {
      buffer = '$buffer $t'.trim();
      live = '';
    }
    notifyListeners();
  }

  void _onStatus(String status) {
    if (!active) return;
    if (status == 'notListening' || status == 'done') _restartSoon();
  }

  void _onError() {
    if (active) _restartSoon();
  }

  void _restartSoon() {
    if (_restarting || !active) return;
    _restarting = true;
    Future<void>.delayed(const Duration(milliseconds: 350), () async {
      _restarting = false;
      if (active && !_speech.isListening) {
        if (live.trim().isNotEmpty) {
          buffer = '$buffer $live'.trim();
          live = '';
        }
        await _speech.listen(onResult: _onResult);
      }
    });
  }

  /// Stops and saves. Returns the saved note id, or null if nothing captured.
  Future<String?> stopAndSave() async {
    if (!active) return null;
    active = false;
    _ticker?.cancel();
    await _speech.stop();
    await WakelockPlus.disable();
    final t = text;
    live = '';
    buffer = '';
    elapsed = Duration.zero;
    notifyListeners();
    if (t.isEmpty) return null;
    final result = await onTranscript(t);
    if (result == null) return null;
    lastReminderCount = result.reminders;
    lastSavedNoteId = result.id;
    notifyListeners();
    return result.id;
  }

  Future<void> cancel() async {
    active = false;
    _ticker?.cancel();
    await _speech.cancel();
    await WakelockPlus.disable();
    live = '';
    buffer = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }
}
