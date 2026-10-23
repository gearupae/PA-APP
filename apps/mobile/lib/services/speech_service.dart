import 'package:speech_to_text/speech_to_text.dart';

/// Thin wrapper around on-device speech recognition used for voice notes.
class SpeechService {
  final SpeechToText _stt = SpeechToText();
  bool _available = false;

  bool get isAvailable => _available;
  bool get isListening => _stt.isListening;

  Future<bool> init() async {
    _available = await _stt.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _available;
  }

  Future<void> start({
    required void Function(String text, bool finalResult) onResult,
  }) async {
    if (!_available) {
      _available = await init();
      if (!_available) return;
    }
    await _stt.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 6),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stop() => _stt.stop();
  Future<void> cancel() => _stt.cancel();
}
