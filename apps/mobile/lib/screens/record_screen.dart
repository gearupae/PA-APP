import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/note_builder.dart';
import '../services/speech_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'note_detail_screen.dart';

/// Full-screen recording page. Auto-starts listening, transcribes on device,
/// and on stop builds a note (todos + mind map) and opens it.
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key, required this.state, this.autoStart = false});
  final AppState state;
  final bool autoStart;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final _speech = SpeechService();
  bool _listening = false;
  bool _starting = false;
  String _live = '';
  String _buffer = '';

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  @override
  void dispose() {
    _speech.cancel();
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
    final ok = await _speech.init();
    if (!ok) {
      setState(() => _starting = false);
      _snack('Speech recognition not available on this device.');
      return;
    }
    setState(() {
      _listening = true;
      _starting = false;
      _live = '';
      _buffer = '';
    });
    await _speech.start(onResult: (text, isFinal) {
      setState(() {
        _live = text;
        if (isFinal) _buffer = '$_buffer $text'.trim();
      });
    });
  }

  Future<void> _stopAndSave() async {
    await _speech.stop();
    setState(() => _listening = false);
    final text = _text;
    if (text.isEmpty) {
      _snack('Nothing was captured — try again.');
      return;
    }
    final note = NoteBuilder.build(text);
    await widget.state.addNote(note);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => NoteDetailScreen(state: widget.state, noteId: note.id),
    ));
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice note')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              _listening
                  ? 'Listening… speak naturally'
                  : _starting
                      ? 'Starting…'
                      : 'Tap to record',
              style: const TextStyle(color: AppColors.slate, fontSize: 15),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Text(
                    _text.isEmpty ? '…' : _text,
                    style: const TextStyle(fontSize: 20, height: 1.5),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: GestureDetector(
                onTap: _listening ? _stopAndSave : _start,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _listening ? AppColors.ink : AppColors.red,
                    boxShadow: [
                      BoxShadow(
                        color: (_listening ? AppColors.ink : AppColors.red)
                            .withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(_listening ? Icons.stop : Icons.mic,
                      color: Colors.white, size: 40),
                ),
              ),
            ),
            if (_listening)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text('Tap to stop & save',
                    style: TextStyle(color: AppColors.slate)),
              ),
          ],
        ),
      ),
    );
  }
}
