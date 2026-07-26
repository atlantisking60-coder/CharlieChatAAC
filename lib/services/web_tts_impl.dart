import 'dart:js_interop';

import 'package:flutter/foundation.dart';

const double _minRate = 0.1;
const double _maxRate = 2.0;
const double _minPitch = 0.0;
const double _maxPitch = 2.0;
const double _minVolume = 0.0;
const double _maxVolume = 1.0;

@JS('window.speechSynthesis')
external SpeechSynthesis? get _speechSynthesis;

@JS('SpeechSynthesis')
@staticInterop
class SpeechSynthesis {}

extension SpeechSynthesisExtension on SpeechSynthesis {
  external JSVoid speak(SpeechSynthesisUtterance utterance);
  external JSVoid cancel();
  external JSVoid pause();
  external JSVoid resume();
  external JSArray getVoices();
}

@JS('SpeechSynthesisVoice')
@staticInterop
class SpeechSynthesisVoice {}

extension SpeechSynthesisVoiceExtension on SpeechSynthesisVoice {
  external String get name;
  external String get lang;
  external String get localService;
  external bool get isDefault;
}

@JS('SpeechSynthesisUtterance')
@staticInterop
class SpeechSynthesisUtterance {
  external factory SpeechSynthesisUtterance([String text]);
}

extension SpeechSynthesisUtteranceExtension on SpeechSynthesisUtterance {
  external set lang(String value);
  external String get lang;
  external set volume(num value);
  external num get volume;
  external set rate(num value);
  external num get rate;
  external set pitch(num value);
  external num get pitch;
  external set voice(SpeechSynthesisVoice? value);
  external SpeechSynthesisVoice? get voice;
  external set onerror(JSFunction? value);
}

/// Get available voices from the Web Speech API
Future<List<Map<String, String>>> getWebVoices() async {
  try {
    final synth = _speechSynthesis;
    if (synth == null) return [];

    final voices = await _waitForVoices();

    final voiceList = <Map<String, String>>[];
    final length = voices.length;
    for (var i = 0; i < length; i++) {
      final voice = voices[i] as SpeechSynthesisVoice;
      final name = voice.name;
      final lang = voice.lang;
      
      // Add gender label based on common naming patterns
      String gender = 'unknown';
      final lowerName = name.toLowerCase();
      if (lowerName.contains('female') || lowerName.contains('woman') || lowerName.contains('girl') ||
          lowerName.contains('aria') || lowerName.contains('zira') || lowerName.contains('hazel') || 
          lowerName.contains('susan') || lowerName.contains('linda') || lowerName.contains('helena') || 
          lowerName.contains('sabina') || lowerName.contains('julie') || lowerName.contains('caroline') || 
          lowerName.contains('katja') || lowerName.contains('hedda') || lowerName.contains('elsa') || 
          lowerName.contains('helga') || lowerName.contains('maria') || lowerName.contains('ayumi') || 
          lowerName.contains('heera') || lowerName.contains('kalpana')) {
        gender = 'female';
      } else if (lowerName.contains('male') || lowerName.contains('man') || lowerName.contains('boy') ||
                 lowerName.contains('guy') || lowerName.contains('david') || lowerName.contains('mark') || 
                 lowerName.contains('george') || lowerName.contains('daniel') || lowerName.contains('pablo') || 
                 lowerName.contains('jorge') || lowerName.contains('paul') || lowerName.contains('claude') || 
                 lowerName.contains('stefan') || lowerName.contains('hans') || lowerName.contains('cosimo') || 
                 lowerName.contains('carlos') || lowerName.contains('kangkang') || lowerName.contains('ichiro') || 
                 lowerName.contains('jun') || lowerName.contains('vikram') || lowerName.contains('hemant')) {
        gender = 'male';
      }

      voiceList.add({
        'name': name,
        'locale': lang,
        'gender': gender,
      });
    }

    return voiceList;
  } catch (error, stackTrace) {
    debugPrint('Error getting web voices: $error\n$stackTrace');
    return [];
  }
}

Future<JSArray> _waitForVoices() async {
  final synth = _speechSynthesis;
  if (synth == null) return JSArray();

  var voices = synth.getVoices();
  int attempts = 0;
  while (voices.length == 0 && attempts < 15) {
    await Future.delayed(const Duration(milliseconds: 100));
    voices = synth.getVoices();
    attempts++;
  }
  return voices;
}

/// Web implementation of TTS using the browser's SpeechSynthesis API.
void webSpeak(String text, String lang, double rate, double pitch,
    double volume, String? voiceName) async {
  final trimmedText = text.trim();
  if (trimmedText.isEmpty) {
    return;
  }

  try {
    final synth = _speechSynthesis;
    if (synth == null) return;

    // Aggressively clear state
    synth.cancel();

    final utterance = SpeechSynthesisUtterance(trimmedText);

    // Configure utterance
    utterance.lang = lang;
    utterance.rate = rate.clamp(_minRate, _maxRate);
    utterance.pitch = pitch.clamp(_minPitch, _maxPitch);
    utterance.volume = volume.clamp(_minVolume, _maxVolume);

    // Find and set voice
    final voices = await _waitForVoices();
    final voicesLength = voices.length;

    SpeechSynthesisVoice? selectedVoice;

    if (voiceName != null && voiceName.isNotEmpty) {
      // 1. Try exact match
      for (var i = 0; i < voicesLength; i++) {
        final voice = voices[i] as SpeechSynthesisVoice;
        if (voice.name == voiceName) {
          selectedVoice = voice;
          break;
        }
      }

      // 2. Try case-insensitive partial match if no exact match found
      if (selectedVoice == null) {
        final lowerVoiceName = voiceName.toLowerCase();
        for (var i = 0; i < voicesLength; i++) {
          final voice = voices[i] as SpeechSynthesisVoice;
          if (voice.name.toLowerCase().contains(lowerVoiceName) ||
              lowerVoiceName.contains(voice.name.toLowerCase())) {
            selectedVoice = voice;
            break;
          }
        }
      }

      // 3. Try matching by gender and language if still no match
      if (selectedVoice == null) {
        final lowerVoiceName = voiceName.toLowerCase();
        final isFemale = lowerVoiceName.contains('female') ||
            lowerVoiceName.contains('woman') ||
            lowerVoiceName.contains('girl') ||
            lowerVoiceName.contains('aria') ||
            lowerVoiceName.contains('zira') ||
            lowerVoiceName.contains('hazel');
        final isMale = lowerVoiceName.contains('male') ||
            lowerVoiceName.contains('man') ||
            lowerVoiceName.contains('boy') ||
            lowerVoiceName.contains('guy') ||
            lowerVoiceName.contains('david');

        for (var i = 0; i < voicesLength; i++) {
          final voice = voices[i] as SpeechSynthesisVoice;
          final voiceLang = voice.lang.split('-')[0].split('_')[0];
          final targetLang = lang.split('-')[0].split('_')[0];

          if (voiceLang == targetLang) {
            final voiceNameLower = voice.name.toLowerCase();
            final voiceIsFemale = voiceNameLower.contains('female') ||
                voiceNameLower.contains('woman') ||
                voiceNameLower.contains('girl') ||
                voiceNameLower.contains('zira');
            final voiceIsMale = voiceNameLower.contains('male') ||
                voiceNameLower.contains('man') ||
                voiceNameLower.contains('boy');

            if (isFemale && voiceIsFemale) {
              selectedVoice = voice;
              break;
            } else if (isMale && voiceIsMale) {
              selectedVoice = voice;
              break;
            }
          }
        }
      }
    }

    // 4. Fallback to any voice matching language if still no voice selected
    if (selectedVoice == null && voicesLength > 0) {
      final targetLang = lang.split('-')[0].split('_')[0];
      for (var i = 0; i < voicesLength; i++) {
        final voice = voices[i] as SpeechSynthesisVoice;
        final voiceLang = voice.lang.split('-')[0].split('_')[0];
        if (voiceLang == targetLang) {
          selectedVoice = voice;
          break;
        }
      }
    }

    if (selectedVoice != null) {
      utterance.voice = selectedVoice;
    }

    // Some browsers need a tiny delay after cancel()
    Future.delayed(const Duration(milliseconds: 50), () {
      try {
        synth.speak(utterance);
        synth.resume();
      } catch (e) {
        debugPrint('Final attempt to speak failed: $e');
      }
    });
  } catch (error, stackTrace) {
    debugPrint('Error with web TTS speak: $error\n$stackTrace');
  }
}

void webStop() => _runSpeechAction((synth) => synth.cancel(), 'stop');

void webPause() => _runSpeechAction((synth) => synth.pause(), 'pause');

void webResume() => _runSpeechAction((synth) => synth.resume(), 'resume');

void _runSpeechAction(
  void Function(SpeechSynthesis synth) action,
  String actionName,
) {
  try {
    final synth = _speechSynthesis;
    if (synth == null) return;
    action(synth);
  } catch (error, stackTrace) {
    debugPrint('Error with web TTS $actionName: $error\n$stackTrace');
  }
}
