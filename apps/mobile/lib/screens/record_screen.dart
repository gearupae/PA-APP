import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../services/note_builder.dart';
import '../services/speech_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'note_detail_screen.dart';

/// Continuous "Meeting mode" capture. Listens, auto-restarts after each
/// pause into one running transcript, keeps the screen awake, and on stop
/// builds a note (to-dos + mind map) and extracts reminders.
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key, required this.state, this.autoStart = false});
  final AppState state;
  final bool autoStart;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final _speech = SpeechService();
  bool _active = false; // meeting running
  bool _starting = false;
  bool _restarting = false;
  String _live = '';
  String _buffer = '';

  DateTime? _startedAt;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _speech.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  String get _text => ('$_buffer $_live').trim();

  Future<void> _start() async {
    setState(() => _starting = true);
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      setState(() => _starting = false);
      _snack('Microphone permission needed.');
      return;
    }
    final ok = await _speech.init(onStatus: _onStatus, onError: _onError);
    if (!ok) {
      setState(() => _starting = false);
      _snack('Speech recognition not available on this device.');
      return;
    }
    await WakelockPlus.enable();
    _startedAt = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _startedAt != null) {
        setState(() => _elapsed = DateTime.now().difference(_startedAt!));
      }
    });
    setState(() {
      _active = true;
      _starting = false;
      _live = '';
      _buffer = '';
    });
    await _speech.listen(onResult: _onResult);
  }

  void _onResult(String text, bool finalResult) {
    setState(() {
      _live = text;
      if (finalResult && text.trim().isNotEmpty) {
        _buffer = '$_buffer $text'.trim();
        _live = '';
      }
    });
  }

  // When a listening segment ends, restart it so capture is continuous.
  void _onStatus(String status) {
    if (!_active) return;
    if (status == 'notListening' || status == 'done') {
      _restartSoon();
    }
  }

  void _onError() {
    if (_active) _restartSoon();
  }

  void _restartSoon() {
    if (_restarting || !_active) return;
    _restarting = true;
    Future<void>.delayed(const Duration(milliseconds: 350), () async {
      _restarting = false;
      if (_active && !_speech.isListening) {
        // Fold any trailing partial into the buffer before the next segment.
        if (_live.trim().isNotEmpty) {
          _buffer = '$_buffer $_live'.trim();
          _live = '';
        }
        await _speech.listen(onResult: _onResult);
      }
    });
  }

  Future<void> _stopAndSave() async {
    setState(() => _active = false);
    _ticker?.cancel();
    await _speech.stop();
    await WakelockPlus.disable();
    final text = _text;
    if (text.isEmpty) {
      _snack('Nothing was captured — try again.');
      return;
    }
    final note = NoteBuilder.build(text);
    await widget.state.addNote(note);
    final reminderCount = await widget.state.addRemindersFromText(text);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => NoteDetailScreen(state: widget.state, noteId: note.id),
    ));
    if (reminderCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '$reminderCount reminder${reminderCount == 1 ? '' : 's'} added')),
      );
    }
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  String get _clock {
    final mm = _elapsed.inMinutes.toString().padLeft(2, '0');
    final ss = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meeting mode')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_active) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                        color: AppColors.red, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  _active
                      ? 'Listening · $_clock'
                      : _starting
                          ? 'Starting…'
                          : 'Tap to start capturing',
                  style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (_active)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Keeps listening until you stop · screen stays on',
                    style: TextStyle(color: AppColors.slate, fontSize: 12)),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Text(
                    _text.isEmpty ? '…' : _text,
                    style: const TextStyle(fontSize: 19, height: 1.5),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: GestureDetector(
                onTap: _active ? _stopAndSave : _start,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _active ? AppColors.ink : AppColors.red,
                    boxShadow: [
                      BoxShadow(
                        color: (_active ? AppColors.ink : AppColors.red)
                            .withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(_active ? Icons.stop : Icons.mic,
                      color: Colors.white, size: 40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                _active ? 'Tap to stop & save' : 'Captures notes, to-dos & reminders',
                style: TextStyle(color: AppColors.slate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
