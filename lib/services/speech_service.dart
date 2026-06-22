import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Wraps the device's native speech recognizer (Android SpeechRecognizer /
/// iOS Speech framework) for real, on-device speech-to-text. No API key
/// required - this is the same recognizer used by the OS keyboard mic.
class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _initWorked = false;
  bool _continuousActive = false;
  String? _continuousLocale;
  void Function(String text, bool isFinal)? _continuousOnResult;

  bool get isListening => _speech.isListening;

  Future<bool> _ensureInit() async {
    if (_initWorked) return true;
    _initWorked = await _speech.initialize(
      onStatus: _handleStatus,
      onError: (_) {},
    );
    return _initWorked;
  }

  void _handleStatus(String status) {
    if (!_continuousActive) return;
    if (status == 'done' || status == 'notListening') {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_continuousActive) _restartContinuous();
      });
    }
  }

  Future<void> _restartContinuous() async {
    final localeId = _continuousLocale;
    final onResult = _continuousOnResult;
    if (localeId == null || onResult == null) return;
    if (_speech.isListening) return;
    await _speech.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 55),
        pauseFor: const Duration(seconds: 10),
        localeId: localeId,
      ),
    );
  }

  /// Starts a long-running listening session that automatically restarts
  /// itself whenever the platform recognizer times out. Used for the live
  /// realtime-translate overlay during calls.
  Future<bool> startContinuousListening({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
  }) async {
    final ok = await _ensureInit();
    if (!ok) return false;
    _continuousActive = true;
    _continuousLocale = localeId;
    _continuousOnResult = onResult;
    await _restartContinuous();
    return true;
  }

  Future<void> stopContinuousListening() async {
    _continuousActive = false;
    _continuousLocale = null;
    _continuousOnResult = null;
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  /// Starts a single listening session - used for recording voice notes.
  Future<bool> startListening({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
  }) async {
    final ok = await _ensureInit();
    if (!ok) return false;
    await _speech.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 8),
        localeId: localeId,
      ),
    );
    return true;
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancelListening() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }

  /// Returns true if the device's recognizer supports [localeId]
  /// (e.g. 'id_ID' or 'en_US').
  Future<bool> hasLocale(String localeId) async {
    final ok = await _ensureInit();
    if (!ok) return false;
    final locales = await _speech.locales();
    return locales.any((l) => l.localeId == localeId);
  }

  void dispose() {
    _continuousActive = false;
    _speech.cancel();
  }
}
