import 'package:speech_to_text/speech_to_text.dart';

/// On-device speech recognition. Supports a continuous "meeting" mode that
/// auto-restarts after each pause so one long session builds a running
/// transcript.
class SpeechService {
  final SpeechToText _stt = SpeechToText();
  bool _available = false;
  String? lastError;
  String? lastStatus;

  bool get isAvailable => _available;
  bool get isListening => _stt.isListening;
  bool get hasRecognizer => _available;

  Future<bool> init({
    void Function(String status)? onStatus,
    void Function()? onError,
  }) async {
    if (_available) return true;
    try {
      _available = await _stt.initialize(
        debugLogging: true,
        onError: (e) {
          lastError = e.errorMsg;
          onError?.call();
        },
        onStatus: (s) {
          lastStatus = s;
          onStatus?.call(s);
        },
      );
      if (!_available) {
        lastError ??= 'Speech recognition is unavailable on this device. '
            'Install/enable "Speech Recognition & Synthesis" (Google) and try again.';
      }
    } catch (e) {
      _available = false;
      lastError = 'Could not start speech recognition: $e';
    }
    return _available;
  }

  /// Start one listening segment. In continuous mode the caller restarts
  /// this when the status callback reports the segment ended.
  Future<void> listen({
    required void Function(String text, bool finalResult) onResult,
  }) async {
    if (!_available) return;
    try {
      await _stt.listen(
        onResult: (r) => onResult(r.recognizedWords, r.finalResult),
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 4),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      lastError = 'Listen failed: $e';
    }
  }

  Future<void> stop() => _stt.stop();
  Future<void> cancel() => _stt.cancel();
}
