import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'tts_voice_matcher.dart';

// Conditional import to handle web-specific code
import 'web_tts_stub.dart'
    if (dart.library.html) 'web_tts_impl.dart';

/// CROSS-PLATFORM TTS SERVICE
/// This service handles speech output across Web, Windows, Android, and iOS.
/// It uses flutter_tts for native platforms and the Web Speech API for browsers.

class CrossPlatformTtsService {
  static final CrossPlatformTtsService _instance = CrossPlatformTtsService._internal();
  late FlutterTts _tts;
  bool _initialized = false;
  double _rate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;
  String _lang = 'en-US';
  String _voiceName = '';

  CrossPlatformTtsService._internal() {
    _tts = FlutterTts();
  }

  static CrossPlatformTtsService get instance => _instance;

  /// Initialize TTS for the current platform
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        // Trigger voice loading on web
        await getVoices();
      } else {
        // Native platforms (iOS, Android, Windows)
        await _tts.awaitSpeakCompletion(true);
      }
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
      _initialized = false;
    }
  }

  /// Apply the current voice settings to the underlying TTS engine.
  Future<void> applySettings({
    String? language,
    String? voiceName,
    double? rate,
    double? pitch,
    double? volume,
  }) async {
    if (language != null) _lang = language;
    if (voiceName != null) _voiceName = voiceName;
    if (rate != null) _rate = rate;
    if (pitch != null) _pitch = pitch;
    if (volume != null) _volume = volume;

    if (!_initialized) await initialize();

    try {
      if (language != null && language.isNotEmpty && !kIsWeb) {
        await _tts.setLanguage(language);
      }

      if (voiceName != null && voiceName.isNotEmpty) {
        await setVoice(voiceName, locale: language ?? _lang);
      }

      if (rate != null && !kIsWeb) {
        await _tts.setSpeechRate(rate);
      }

      if (pitch != null && !kIsWeb) {
        await _tts.setPitch(pitch);
      }

      if (volume != null && !kIsWeb) {
        await _tts.setVolume(volume);
      }
    } catch (e) {
      debugPrint('Error applying TTS settings: $e');
    }
  }

  /// Set language for TTS
  Future<void> setLanguage(String language) async {
    _lang = language;
    if (!_initialized) await initialize();

    try {
      if (!kIsWeb) {
        await _tts.setLanguage(language);
      }
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }

  /// Set voice properties
  Future<void> setVoice(String voiceName, {String locale = ''}) async {
    _voiceName = voiceName;
    if (!_initialized) await initialize();

    try {
      if (!kIsWeb) {
        final voices = await getVoices();
        debugPrint('Available voices: ${voices.map((v) => '${v['name']} (${v['locale']})').toList()}');
        debugPrint('Trying to set voice: $voiceName (locale: $locale)');

        final matchingVoice = selectBestVoice(voices, voiceName: voiceName, locale: locale);
        if (matchingVoice != null) {
          await _tts.setVoice({
            'name': matchingVoice['name'] ?? voiceName,
            'locale': matchingVoice['locale'] ?? locale,
          });
          debugPrint('Voice set to: ${matchingVoice['name']} (${matchingVoice['locale']})');
        } else {
          debugPrint('No matching voice found, using default');
        }
      }
    } catch (e) {
      debugPrint('Error setting voice: $e');
    }
  }

  /// Set speech rate (0.0 to 1.0 on most platforms)
  Future<void> setSpeechRate(double rate) async {
    _rate = rate;
    if (!_initialized) await initialize();

    try {
      if (!kIsWeb) {
        await _tts.setSpeechRate(rate);
      }
    } catch (e) {
      debugPrint('Error setting speech rate: $e');
    }
  }

  /// Set pitch (0.5 to 2.0 typically)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    if (!_initialized) await initialize();

    try {
      if (!kIsWeb) {
        await _tts.setPitch(pitch);
      }
    } catch (e) {
      debugPrint('Error setting pitch: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume;
    if (!_initialized) await initialize();

    try {
      if (!kIsWeb) {
        await _tts.setVolume(volume);
      }
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  /// Speak text
  Future<void> speak(String text) async {
    if (!_initialized) await initialize();

    if (text.trim().isEmpty) return;

    try {
      await applySettings(
        language: _lang,
        voiceName: _voiceName,
        rate: _rate,
        pitch: _pitch,
        volume: _volume,
      );

      debugPrint('Speaking: $text with language: $_lang, rate: $_rate, pitch: $_pitch, volume: $_volume, voice: $_voiceName');
      if (kIsWeb) {
        webSpeak(text, _lang, _rate, _pitch, _volume, _voiceName);
      } else {
        await _tts.speak(text);
      }
    } catch (e) {
      debugPrint('Error speaking: $e');
    }
  }

  /// Stop TTS
  Future<void> stop() async {
    try {
      if (kIsWeb) {
        webStop();
      } else {
        await _tts.stop();
      }
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }

  /// Pause TTS
  Future<void> pause() async {
    try {
      if (kIsWeb) {
        webPause();
      } else {
        await _tts.pause();
      }
    } catch (e) {
      debugPrint('Error pausing TTS: $e');
    }
  }

  /// Resume TTS
  Future<void> resume() async {
    try {
      if (kIsWeb) {
        webResume();
      }
      // Resume is not directly supported by flutter_tts on all platforms
    } catch (e) {
      debugPrint('Error resuming TTS: $e');
    }
  }

  /// Get available languages
  Future<List<String>> getLanguages() async {
    try {
      if (kIsWeb) {
        return ['en-US', 'en-GB', 'es-ES', 'fr-FR', 'de-DE'];
      } else {
        final langs = await _tts.getLanguages;
        if (langs is List) {
          return langs.map((l) => l.toString()).toList();
        }
        return [];
      }
    } catch (e) {
      debugPrint('Error getting languages: $e');
      return [];
    }
  }

  /// Get available voices
  Future<List<Map<String, String>>> getVoices() async {
    try {
      if (kIsWeb) {
        // Web Speech API voices - dynamically load from browser
        return await getWebVoices();
      } else {
        // Native platforms - get system voices
        final voices = await _tts.getVoices;
        if (voices is List) {
          return voices.map((v) {
            if (v is Map) {
              final voiceMap = Map<String, String>.from(v);
              // Add gender label if not present based on common naming patterns
              if (!voiceMap.containsKey('gender')) {
                final name = voiceMap['name']?.toLowerCase() ?? '';
                if (name.contains('female') || name.contains('woman') || name.contains('girl') || 
                    name.contains('zira') || name.contains('hazel') || name.contains('susan') || 
                    name.contains('linda') || name.contains('helena') || name.contains('sabina') ||
                    name.contains('julie') || name.contains('caroline') || name.contains('katja') ||
                    name.contains('hedda') || name.contains('elsa') || name.contains('helga') ||
                    name.contains('maria') || name.contains('ayumi') || name.contains('heera') ||
                    name.contains('kalpana')) {
                  voiceMap['gender'] = 'female';
                } else if (name.contains('male') || name.contains('man') || name.contains('boy') ||
                           name.contains('david') || name.contains('mark') || name.contains('george') ||
                           name.contains('daniel') || name.contains('pablo') || name.contains('jorge') ||
                           name.contains('paul') || name.contains('claude') || name.contains('stefan') ||
                           name.contains('hans') || name.contains('cosimo') || name.contains('carlos') ||
                           name.contains('kangkang') || name.contains('ichiro') || name.contains('jun') ||
                           name.contains('vikram') || name.contains('hemant')) {
                  voiceMap['gender'] = 'male';
                } else {
                  voiceMap['gender'] = 'unknown';
                }
              }
              return voiceMap;
            }
            return {'name': v.toString(), 'gender': 'unknown'};
          }).toList();
        }
        return [];
      }
    } catch (e) {
      debugPrint('Error getting voices: $e');
      return [];
    }
  }
}
