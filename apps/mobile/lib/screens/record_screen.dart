import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/recording_api.dart';

/// In-app voice notes + optional phone-call capture (platform-dependent).
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  bool _consent = false;
  bool _recording = false;
  RecordingKind _kind = RecordingKind.voiceNote;
  String? _status;

  Future<void> _requestMic() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted && mounted) {
      setState(() => _status = 'Microphone permission denied');
    }
  }

  Future<void> _toggleRecord() async {
    if (!_consent) {
      setState(() => _status = 'Acknowledge consent before recording');
      return;
    }
    await _requestMic();
    setState(() {
      _recording = !_recording;
      _status = _recording ? 'Recording (stub UI)…' : 'Stopped — upload stub next';
    });
    // TODO: integrate `record` package; on stop, multipart POST to /recordings
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _kind = RecordingKind.voiceNote;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = Platform.isAndroid;
    final isIos = Platform.isIOS;
    final callRecordingOffered = isAndroid;

    return Scaffold(
      appBar: AppBar(title: const Text('Record')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Capture an in-app voice note or, where allowed, a phone call. '
            'You are responsible for informing other parties and complying with local law.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (callRecordingOffered)
            SegmentedButton<RecordingKind>(
              segments: const [
                ButtonSegment(
                  value: RecordingKind.voiceNote,
                  label: Text('Voice note'),
                  icon: Icon(Icons.mic),
                ),
                ButtonSegment(
                  value: RecordingKind.phoneCall,
                  label: Text('Phone call'),
                  icon: Icon(Icons.call),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            )
          else
            const ListTile(
              leading: Icon(Icons.mic),
              title: Text('In-app voice note'),
            ),
          if (_kind == RecordingKind.phoneCall && callRecordingOffered) ...[
            const SizedBox(height: 12),
            _PlatformCallNote(isAndroid: isAndroid, isIos: isIos),
          ],
          CheckboxListTile(
            value: _consent,
            onChanged: (v) => setState(() => _consent = v ?? false),
            title: const Text(
              'I confirm I have consent or legal right to record this conversation',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 24),
          Center(
            child: FilledButton.tonalIcon(
              onPressed: _toggleRecord,
              icon: Icon(_recording ? Icons.stop : Icons.fiber_manual_record),
              label: Text(_recording ? 'Stop' : 'Start recording'),
            ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 16),
            Text(_status!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _consent
                ? () async {
                    final api = RecordingApi(baseUrl: 'http://localhost:8000');
                    // Stub upload without file until recorder wired
                    setState(() => _status = 'Upload stub — wire JWT + audio file');
                    await api.uploadMetadata(kind: _kind);
                  }
                : null,
            child: const Text('Upload & summarize (stub)'),
          ),
        ],
      ),
    );
  }
}

class _PlatformCallNote extends StatelessWidget {
  const _PlatformCallNote({required this.isAndroid, required this.isIos});

  final bool isAndroid;
  final bool isIos;

  @override
  Widget build(BuildContext context) {
    if (isIos) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('iOS phone call recording'),
          subtitle: Text(
            'Apple does not expose a public API to record cellular calls in third-party apps. '
            'Use in-app voice notes during speakerphone, or system Shortcuts/voicemail workarounds. '
            'Call recording UI is hidden or disabled on iOS builds.',
          ),
        ),
      );
    }
    if (isAndroid) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.warning_amber),
          title: Text('Android phone call recording'),
          subtitle: Text(
            'Varies by OEM and Android version: AccessibilityService, dialer integration, '
            'or RECORD_AUDIO during calls may be required. Play policy requires clear disclosure. '
            'Some devices block third-party call recording entirely.',
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
