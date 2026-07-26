# Charlie Chat

Charlie Chat - A Flutter-based AAC (augmentative and alternative communication) app with SymbolTalk backend integration.

## Features
- Symbol grid with categories and search
- Phrase builder with removable symbol chips
- Text-to-speech playback for individual symbols and full phrases
- Cloud sync with SymbolTalk backend
- User authentication and profiles
- Favorites storage with cloud backup
- Dedicated favorites screen
- Phrase history and quick sentence presets
- Sentence construction mode for full text messages
- Settings screen for voice rate, pitch, volume, and theme mode
- Cross-platform support (Web, iOS, Android, Windows)

## Architecture
- **Frontend**: Flutter & Dart (cross-platform UI)
- **Backend**: SymbolTalk API (Ktor/PostgreSQL)
- **Storage**: Local cache + Cloud sync via SymbolTalk backend

## Get started

1. Ensure SymbolTalk backend is running (default: http://localhost:8080)
2. Open the project folder in VS Code.
3. Run `flutter pub get`.
4. Start the app using `flutter run` (or `flutter run -d chrome` for web)

## Notes

- Long-press a symbol to toggle it as a favorite.
- Tap a favorite chip to add it to the current phrase.
- The app uses custom SVG symbol assets for a more visual AAC experience.
- Categories are navigated via top tabs.
- Data syncs automatically with SymbolTalk backend when authenticated.
