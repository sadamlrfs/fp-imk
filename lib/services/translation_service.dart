import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Result of an auto-detected EN<->ID translation.
class TranslationResult {
  final String sourceLanguageCode;
  final String textEn;
  final String textId;

  TranslationResult({
    required this.sourceLanguageCode,
    required this.textEn,
    required this.textId,
  });
}

/// Real on-device translation between English and Indonesian using
/// Google ML Kit. Models are downloaded once (requires internet the
/// first time) and then translation works fully offline.
class TranslationService {
  static const supportedLanguages = [
    TranslateLanguage.english,
    TranslateLanguage.indonesian,
  ];

  final LanguageIdentifier _languageIdentifier =
      LanguageIdentifier(confidenceThreshold: 0.4);
  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();
  final Map<String, OnDeviceTranslator> _translators = {};

  Future<void>? _modelsFuture;
  bool _modelsReady = false;

  bool get modelsReady => _modelsReady;

  /// Downloads the EN & ID translation models if they aren't on-device yet.
  /// Safe to call repeatedly; only downloads once.
  Future<void> ensureModelsReady() {
    return _modelsFuture ??= _downloadModels();
  }

  Future<void> _downloadModels() async {
    for (final lang in supportedLanguages) {
      final downloaded = await _modelManager.isModelDownloaded(lang.bcpCode);
      if (!downloaded) {
        await _modelManager.downloadModel(lang.bcpCode, isWifiRequired: false);
      }
    }
    _modelsReady = true;
  }

  /// Detects the BCP-47 language code of [text] ('en', 'id', or 'und').
  Future<String> detectLanguageCode(String text) async {
    if (text.trim().isEmpty) return 'und';
    return _languageIdentifier.identifyLanguage(text);
  }

  OnDeviceTranslator _translatorFor(
    TranslateLanguage from,
    TranslateLanguage to,
  ) {
    final key = '${from.bcpCode}-${to.bcpCode}';
    return _translators.putIfAbsent(
      key,
      () => OnDeviceTranslator(sourceLanguage: from, targetLanguage: to),
    );
  }

  /// Translates [text] from [from] to [to] using the on-device model.
  Future<String> translate(
    String text, {
    required TranslateLanguage from,
    required TranslateLanguage to,
  }) async {
    if (text.trim().isEmpty) return text;
    if (from == to) return text;
    await ensureModelsReady();
    return _translatorFor(from, to).translateText(text);
  }

  /// Detects whether [text] is English or Indonesian and translates it to
  /// the other language, returning both versions. If detection is
  /// inconclusive, [fallbackSource] is assumed to be the spoken language.
  Future<TranslationResult> translateAuto(
    String text, {
    TranslateLanguage fallbackSource = TranslateLanguage.indonesian,
  }) async {
    final code = await detectLanguageCode(text);
    final isEnglish = code == 'en' ||
        (code == 'und' && fallbackSource == TranslateLanguage.english) ||
        (code != 'id' && code != 'en' && fallbackSource == TranslateLanguage.english);

    final from = isEnglish ? TranslateLanguage.english : TranslateLanguage.indonesian;
    final to = isEnglish ? TranslateLanguage.indonesian : TranslateLanguage.english;
    final translated = await translate(text, from: from, to: to);

    return TranslationResult(
      sourceLanguageCode: from.bcpCode,
      textEn: isEnglish ? text : translated,
      textId: isEnglish ? translated : text,
    );
  }

  void dispose() {
    _languageIdentifier.close();
    for (final translator in _translators.values) {
      translator.close();
    }
    _translators.clear();
  }
}
