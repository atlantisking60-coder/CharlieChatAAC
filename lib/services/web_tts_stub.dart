/// Stub for web TTS functionality to allow compilation on native platforms.
void webSpeak(String text, String lang, double rate, double pitch, double volume, String? voiceName) {
  // No-op on native
}

void webStop() {
  // No-op on native
}

void webPause() {
  // No-op on native
}

void webResume() {
  // No-op on native
}

Future<List<Map<String, String>>> getWebVoices() async {
  // Return empty list on native
  return [];
}
