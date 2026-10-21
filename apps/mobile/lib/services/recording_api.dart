enum RecordingKind { voiceNote, phoneCall }

extension RecordingKindApi on RecordingKind {
  String get apiValue =>
      this == RecordingKind.voiceNote ? 'voice_note' : 'phone_call';
}

class RecordingApi {
  RecordingApi({required this.baseUrl, this.accessToken});

  final String baseUrl;
  final String? accessToken;

  /// Stub: replace with multipart upload + auth header.
  Future<void> uploadMetadata({required RecordingKind kind}) async {
    // POST $baseUrl/recordings with FormData: kind, consent_acknowledged, audio
    // Then POST .../summarize and .../mindmap
  }
}
