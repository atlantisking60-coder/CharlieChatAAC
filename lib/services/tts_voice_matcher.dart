Map<String, String>? selectBestVoice(
  List<Map<String, String>> voices, {
  required String voiceName,
  required String locale,
}) {
  if (voices.isEmpty) return null;

  final trimmedName = voiceName.trim();
  final requestedGender = _genderHint(trimmedName);
  final requestedLocale = locale.trim();
  final requestedLang = _languageCode(requestedLocale);

  // 1. Exact name match, preferring same locale.
  for (final voice in voices) {
    final name = voice['name']?.trim() ?? '';
    final voiceLocale = voice['locale']?.trim() ?? '';
    if (name.isEmpty) continue;
    if (name == trimmedName && (requestedLocale.isEmpty || _localeMatches(voiceLocale, requestedLocale))) {
      return voice;
    }
  }

  // 2. Normalized name match (ignoring punctuation/spaces).
  final normalizedName = _normalize(trimmedName);
  if (normalizedName.isNotEmpty) {
    for (final voice in voices) {
      final name = voice['name']?.trim() ?? '';
      final voiceLocale = voice['locale']?.trim() ?? '';
      if (_normalize(name) == normalizedName &&
          (requestedLocale.isEmpty || _localeMatches(voiceLocale, requestedLocale))) {
        return voice;
      }
    }
  }

  // 3. Partial name match.
  if (trimmedName.isNotEmpty) {
    for (final voice in voices) {
      final name = voice['name']?.trim() ?? '';
      final voiceLocale = voice['locale']?.trim() ?? '';
      if (name.isEmpty) continue;
      final normalizedVoiceName = _normalize(name);
      if ((normalizedVoiceName.contains(normalizedName) || normalizedName.contains(normalizedVoiceName)) &&
          (requestedLocale.isEmpty || _localeMatches(voiceLocale, requestedLocale))) {
        return voice;
      }
    }
  }

  // 4. Same locale/lang and matching gender.
  if (requestedGender.isNotEmpty && requestedLocale.isNotEmpty) {
    for (final voice in voices) {
      if (_matchesGender(voice, requestedGender) && _matchesLocale(voice, requestedLocale, requestedLang)) {
        return voice;
      }
    }
  }

  // 5. Same locale/lang regardless of gender.
  if (requestedLocale.isNotEmpty) {
    for (final voice in voices) {
      if (_matchesLocale(voice, requestedLocale, requestedLang)) {
        return voice;
      }
    }
  }

  // 6. Same gender if known.
  if (requestedGender.isNotEmpty) {
    for (final voice in voices) {
      if (_matchesGender(voice, requestedGender)) {
        return voice;
      }
    }
  }

  // 7. Best available fallback.
  return voices.first;
}

String _normalize(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

String _languageCode(String locale) {
  if (locale.isEmpty) return '';
  return locale.split('-')[0].split('_')[0].toLowerCase();
}

bool _localeMatches(String voiceLocale, String requestedLocale) {
  final voiceLang = _languageCode(voiceLocale);
  final requestedLang = _languageCode(requestedLocale);
  return voiceLocale.toLowerCase() == requestedLocale.toLowerCase() ||
      voiceLang == requestedLang;
}

bool _matchesLocale(Map<String, String> voice, String requestedLocale, String requestedLang) {
  final voiceLocale = (voice['locale'] ?? '').trim();
  final voiceLang = _languageCode(voiceLocale);
  if (requestedLocale.isEmpty) return true;
  return voiceLocale.toLowerCase() == requestedLocale.toLowerCase() ||
      voiceLang == requestedLang;
}

bool _matchesGender(Map<String, String> voice, String requestedGender) {
  final voiceGender = (voice['gender'] ?? '').trim().toLowerCase();
  final voiceName = (voice['name'] ?? '').trim().toLowerCase();
  if (voiceGender.isEmpty) {
    return voiceName.contains(requestedGender);
  }
  return voiceGender == requestedGender ||
      voiceName.contains(requestedGender);
}

String _genderHint(String voiceName) {
  final normalized = _normalize(voiceName);
  if (normalized.contains('female') ||
      normalized.contains('woman') ||
      normalized.contains('girl') ||
      normalized.contains('aria') ||
      normalized.contains('zira') ||
      normalized.contains('hazel') ||
      normalized.contains('susan') ||
      normalized.contains('linda') ||
      normalized.contains('helena') ||
      normalized.contains('sabina') ||
      normalized.contains('julie') ||
      normalized.contains('caroline') ||
      normalized.contains('katja') ||
      normalized.contains('hedda') ||
      normalized.contains('elsa') ||
      normalized.contains('helga') ||
      normalized.contains('maria') ||
      normalized.contains('ayumi') ||
      normalized.contains('heera') ||
      normalized.contains('kalpana')) {
    return 'female';
  }

  if (normalized.contains('male') ||
      normalized.contains('man') ||
      normalized.contains('boy') ||
      normalized.contains('guy') ||
      normalized.contains('david') ||
      normalized.contains('mark') ||
      normalized.contains('george') ||
      normalized.contains('daniel') ||
      normalized.contains('pablo') ||
      normalized.contains('jorge') ||
      normalized.contains('paul') ||
      normalized.contains('claude') ||
      normalized.contains('stefan') ||
      normalized.contains('hans') ||
      normalized.contains('cosimo') ||
      normalized.contains('carlos') ||
      normalized.contains('kangkang') ||
      normalized.contains('ichiro') ||
      normalized.contains('jun') ||
      normalized.contains('vikram') ||
      normalized.contains('hemant')) {
    return 'male';
  }

  return '';
}
