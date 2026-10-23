import 'package:speech_to_text/speech_to_text.dart';

/// On-device speech recognition. Supports a continuous "meeting" mode that
/// auto-restarts after each pause so one long session builds a running
/// transcript.
class SpeechService {
  final SpeechToText _stt = SpeechToText();
  bool _available = false;

  bool get isAvailable => _available;
  bool get isListening => _stt.isListening;

  Future<bool> init({
    void Function(String status)? onStatus,
    void Function()? onError,
  }) async {
    if (_available) return true;
    _available = await _stt.initialize(
      onError: (_) => onError?.call(),
      onStatus: (s) => onStatus?.call(s),
    );
    return _available;
  }

  /// Start one listening segment. In continuous mode the caller restarts
  /// this when the status callback reports the segment ended.
  Future<void> listen({
    required void Function(String text, bool finalResult) onResult,
  }) async {
    if (!_available) return;
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
  }

  Future<void> stop() => _stt.stop();
  Future<void> cancel() => _stt.cancel();
}
