import 'dart:async';

import 'package:flutter/material.dart';
import '../../../services/settings_service.dart';
import '../../../services/cross_platform_tts_service.dart';
import '../settings_widgets.dart';
import '../../settings_screen.dart' show VoiceOption;

class SpeechSection extends StatelessWidget {
  const SpeechSection({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.availableLanguages,
    required this.availableVoices,
  });
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;
  final List<String> availableLanguages;
  final List<VoiceOption> availableVoices;

  Future<void> _testVoice() async {
    final tts = CrossPlatformTtsService.instance;
    await tts.applySettings(
      language: settings.voiceLanguage,
      voiceName: settings.voiceName,
      rate: settings.voiceRate,
      pitch: settings.voicePitch,
      volume: settings.voiceVolume,
    );
    await tts.speak('Hello! This is a test of your voice settings.');
  }

  @override
  Widget build(BuildContext context) {
    final langItems = availableLanguages
        .map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 13))))
        .toList();
    final voiceItems = availableVoices
        .map((v) => DropdownMenuItem(
              value: v.name,
              child: Text('${v.name} (${v.locale})',
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ))
        .toList();

    final currentLang = availableLanguages.contains(settings.voiceLanguage)
        ? settings.voiceLanguage
        : (availableLanguages.isNotEmpty ? availableLanguages.first : null);
    final currentVoice = availableVoices.any((v) => v.name == settings.voiceName)
        ? settings.voiceName
        : (availableVoices.isNotEmpty ? availableVoices.first.name : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
          icon: Icons.record_voice_over_rounded,
          title: 'Speech',
          subtitle: 'Configure voice synthesis for symbol output',
        ),

        SettingsGroup(
          title: 'Voice',
          children: [
            if (availableLanguages.isNotEmpty)
              SettingsDropdownTile<String>(
                icon: Icons.language_rounded,
                title: 'Language',
                value: currentLang ?? '',
                items: langItems,
                onChanged: (v) {
                  if (v != null) {
                    final updated = settings.copyWith(voiceLanguage: v);
                    onChanged(updated);
                    unawaited(CrossPlatformTtsService.instance.applySettings(
                      language: updated.voiceLanguage,
                      voiceName: updated.voiceName,
                      rate: updated.voiceRate,
                      pitch: updated.voicePitch,
                      volume: updated.voiceVolume,
                    ));
                  }
                },
              ),
            if (availableVoices.isNotEmpty)
              SettingsDropdownTile<String>(
                icon: Icons.person_rounded,
                title: 'Voice',
                value: currentVoice ?? '',
                items: voiceItems,
                onChanged: (v) {
                  if (v != null) {
                    final updated = settings.copyWith(voiceName: v);
                    onChanged(updated);
                    unawaited(CrossPlatformTtsService.instance.applySettings(
                      language: updated.voiceLanguage,
                      voiceName: updated.voiceName,
                      rate: updated.voiceRate,
                      pitch: updated.voicePitch,
                      volume: updated.voiceVolume,
                    ));
                  }
                },
                showDivider: false,
              ),
          ],
        ),

        SettingsGroup(
          title: 'Tuning',
          children: [
            SettingsSliderTile(
              icon: Icons.speed_rounded,
              title: 'Rate',
              value: settings.voiceRate,
              min: 0.2,
              max: 1.0,
              divisions: 16,
              displayValue: settings.voiceRate.toStringAsFixed(2),
              onChanged: (v) {
                final updated = settings.copyWith(voiceRate: v);
                onChanged(updated);
                unawaited(CrossPlatformTtsService.instance.applySettings(
                  language: updated.voiceLanguage,
                  voiceName: updated.voiceName,
                  rate: updated.voiceRate,
                  pitch: updated.voicePitch,
                  volume: updated.voiceVolume,
                ));
              },
            ),
            SettingsSliderTile(
              icon: Icons.graphic_eq_rounded,
              title: 'Pitch',
              value: settings.voicePitch,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              displayValue: settings.voicePitch.toStringAsFixed(2),
              onChanged: (v) {
                final updated = settings.copyWith(voicePitch: v);
                onChanged(updated);
                unawaited(CrossPlatformTtsService.instance.applySettings(
                  language: updated.voiceLanguage,
                  voiceName: updated.voiceName,
                  rate: updated.voiceRate,
                  pitch: updated.voicePitch,
                  volume: updated.voiceVolume,
                ));
              },
            ),
            SettingsSliderTile(
              icon: Icons.volume_up_rounded,
              title: 'Volume',
              value: settings.voiceVolume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              displayValue: '${(settings.voiceVolume * 100).round()}%',
              onChanged: (v) {
                final updated = settings.copyWith(voiceVolume: v);
                onChanged(updated);
                unawaited(CrossPlatformTtsService.instance.applySettings(
                  language: updated.voiceLanguage,
                  voiceName: updated.voiceName,
                  rate: updated.voiceRate,
                  pitch: updated.voicePitch,
                  volume: updated.voiceVolume,
                ));
              },
              showDivider: false,
            ),
          ],
        ),

        SettingsGroup(
          title: 'Behaviour',
          children: [
            SettingsSwitchTile(
              icon: Icons.touch_app_rounded,
              title: 'Speak on Tap',
              subtitle: 'Speak symbol label immediately when tapped',
              value: settings.speakOnTap,
              onChanged: (v) => onChanged(settings.copyWith(speakOnTap: v)),
              showDivider: false,
            ),
          ],
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: _testVoice,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_outline_rounded),
                  SizedBox(width: 8),
                  Text('Test Voice'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
