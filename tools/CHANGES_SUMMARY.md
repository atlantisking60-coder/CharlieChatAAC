# Board Editor Enhancements - Changes Summary

## 1. Add tile always shown at end in edit mode
- File: `lib/widgets/board_editor.dart`
- Added `_ensureTileCapacity` calls in `initState`, after resize, and after saving a tile so the grid always ends with at least one empty add tile.

## 2. User-added tiles default to transparent background
- File: `lib/widgets/board_editor.dart`
- Tile cards now render with a transparent background.
- The board editor root widget is wrapped in a container using the board's background colour so the transparent tiles show the board colour behind them.

## 3. Record popup with record/stop/play/start again
- File: `lib/widgets/board_editor.dart`
- Replaced the old `_startRecording` snackbar flow with a new `_showRecordDialog` that opens a `_RecordDialog` widget.
- `_RecordDialog` provides fully functional record, stop, play, and start again buttons, plus a Done button.

## 4. Scan assets and fix missing tile pictures
- Created: `tools/fix_json_images.py`
- Scanned `assets/symbols/` recursively and matched labels to existing image files.
- Updated image paths in all JSON files under `lib/data/boards/[Area]/`.
- Handled duplicate labels by using `(1)` / `(2)` suffixed icons where available.
- Added special mappings for number words, colours, and other labels whose filenames differ from the label.
- Fixed label typos: `000)` -> `000`, `fog` -> `foggy`.
- Removed corrupted Cyrillic tile (`риз`) from Body Parts.
- Remaining text-only tiles (small words, phonics) intentionally have no image asset.
- Log: `tools/fix_json_images.log`

## 5. JSON files saved to lib/data/boards/[Area]
- File: `lib/services/board_service.dart`
- `_writeBoard`, `exportToProject`, `loadBoard`, `listBoards`, and `deleteBoard` now use `lib/data/boards/[Area]` as the canonical project-side JSON location.
- Removed writes to the deprecated root `boards/` directory.
- `generate_boards.bat` completion message updated to `lib\data\boards\`.
- Added JSON <-> `Board`/`SymbolTile` converters so runtime models and the JSON schema stay in sync.

## 6. JSON files reflect current app state
- All JSON files were re-written by the image-fixing script using the current JSON schema.
- Future saves via the app will write the same JSON schema to `lib/data/boards/[Area]/`.

## 7. App builds boards from lib/data/boards/
- `_ensurePrebuiltBoards` now tries to load each board from `lib/data/boards/[Area]/prebuilt_<id>.json` before falling back to programmatic generation.
- `loadBoard` and `listBoards` check the canonical JSON path first.

## 8. New empty subboards for missing links
- File: `lib/main.dart`
- `_openLinkedBoard` now creates a new empty adjustable-layout subboard when the target board does not exist, instead of falling back to the first (common) board.
- File: `lib/services/board_service.dart`
- Added `_ensureMissingSubboards` migration that runs on startup and creates empty subboards for any board-link tiles that reference a missing board.

## 9. My School Main board
- Created: `lib/data/boards/My School/prebuilt_my_school_main.json`
- Contains links to People At School, Baycroft Expects, Thinking Skills, When Things Go Wrong, Blank Levels, and Lessons.
- Updated `lib/data/boards/Common/prebuilt_people.json` so the People board links to My School Main instead of People At School.
- Registered My School Main in `lib/services/board_service.dart` prebuilt list, area mapping, and light-green theme set.

## 10. Web backup to file
- File: `lib/services/backup_service.dart`
- `exportBackupFile` now downloads a JSON backup on web via browser download instead of throwing.
- Added web-specific helper `lib/services/backup_web.dart` using `package:web`.

## 11. Subject Vocab tab icons
- File: `lib/main.dart`
- Updated `_getBoardIconPath` mapping for all School-mode subject boards to use the actual `assets/symbols/BOARDS/Subjects/*.png` files (e.g., `English Vocab.png`, `Maths Vocab.png`, etc.).

## 12. Sign Board tab icons
- File: `lib/main.dart`
- Added explicit icon mappings for every Sign-mode board, with the main `Sign` board using `assets/symbols/BOARDS/Signs.png`.

## 13. My School tab icons
- File: `lib/main.dart`
- Updated My School mode mapping to use `assets/symbols/BOARDS/Baycroft Expects.png`, `Blank Levels.png`, `Thinking Skills.png`, and `Lesson Vocabulary.png` for My School Lessons.

## 14. Feelings sub-board tab row (pilot only)
- File: `lib/main.dart`
- Added a second row of tabs below the main tab bar when the active board is `Feelings`.
- Second row contains: Sad, Mad, Scared, Joyful, Strong, Calm.
- Refactored tab bar rendering into `_buildTabBar` and `_subTabsForBoard` helpers.

## 15. Edit tile image preview
- File: `lib/widgets/board_editor.dart`
- Renamed the `Online` button to `Online Search`.
- Added a 120px image preview below the Online Search / View Full Image / Record button row when the tile has an image.

## 16. Transparent user-added tile backgrounds
- File: `lib/widgets/board_editor.dart`
- Fixed the tile save logic so the background value `transparent` is preserved instead of being mangled into `#transparent` (which rendered as white).

## 17. Prepositions board fixes
- Files: `lib/services/board_service.dart`, `lib/data/boards/Common/prebuilt_prepositions.json`
- Split `high up` into `high` and `up`.
- Split `low down` into `low` and `down`.
- Renamed `middle` to `middle ground` and removed the duplicate `middle` tile from the JSON.
- Removed the `Other Adjectives` board link from the Prepositions board.

## 18. Subject Vocab icons from `assets/symbols/Subjects`
- File: `lib/main.dart`
- Updated School/Subject Vocab tab icon mapping to use the cleaner `assets/symbols/Subjects/*.png` files (e.g., `English.png`, `Maths.png`, `P.E.png`, `P.D.png`, `I.T.png`, etc.).

## 19. Sub-board tabs for all parent boards
- File: `lib/main.dart`
- Replaced the hardcoded Feelings-only sub-tab row with a dynamic implementation.
- `_subTabsForBoard` now scans the active board's tiles for links to any board in the new `_subBoardNames` list and returns matching tabs.
- Added icon mappings for all sub-boards: Feelings sub-boards (`Sad`, `Mad`, `Scared`, `Joyful`, `Strong`, `Calm`), `Shades Of Colours`, `Adjectives`, `Phonics` / phase boards, and all Animals sub-boards.
- Cleaned up two non-existent asset directory references in `pubspec.yaml` (`Main/` and `Small Words/`) so the analyzer passes.

## 20. Back button for sub-boards
- File: `lib/main.dart`
- Added a `parentBoard` field to `TopTab` so sub-board tabs know their parent board.
- `_subBoardTab` now receives the parent board and stores it in the tab.
- `_handleTabTap` now sets `_parentBoard` when a sub-board tab is selected.
- The existing bottom-panel Back button will now navigate back to the parent board (e.g., `Scared` -> `Feelings`) for any sub-board reached via a sub-board tab.
- This also works for future sub-boards automatically because the parent relationship is computed dynamically from the active board's tiles.

## 21. Persistent sub-board tabs
- File: `lib/main.dart`
- Sub-board tabs now stay visible after opening a sub-board (e.g., `Animals` -> `Mammals` keeps the Mammals/Birds/Reptiles/etc. row visible).
- The second tab row is built from the parent board (`_parentBoard`) when one is set, so sibling sub-boards remain accessible.
- The main tab bar now also highlights the parent board tab while a sub-board is active.

## 22. A to Z of sign board with A-Z sub-boards
- Created 27 JSON board files under `lib/data/boards/Sign/` using `tools/generate_sign_az_boards.dart`:
  - Parent board `A to Z of sign` with board-link tiles to `A (Sign)` ... `Z (Sign)`.
  - 26 sub-boards populated from `A-Z Of Sign.txt`.
  - Each word tile uses the matching image from `assets/sign/00. A-Z of Sign/*.png`.
  - Sub-board tab icons use `assets/symbols/1. Main Boards/Alphabet/[a-z].png`.
- Updated `lib/services/board_service.dart`:
  - Added the Sign area to `_areaForBoardName`.
  - Added the parent and all sub-boards to `prebuiltBoardNames`.
  - Added the sub-board names to the `subBoardNames` set so they are hidden from the top tab bar.
- Updated `lib/main.dart`:
  - Replaced `Sign A-Z` with `A to Z of sign` in Sign mode.
  - Added icon mappings for `A to Z of sign` and all `A (Sign)` ... `Z (Sign)` sub-boards.
  - Added the sub-boards to `_subBoardNames`.
  - Updated `_subTabsForBoard` to resolve the actual board name from `_boards` when matching sub-board links (so sanitized IDs like `prebuilt_a_sign` match display names like `A (Sign)`).
- Updated `pubspec.yaml` to include `assets/sign/` and `assets/sign/00. A-Z of Sign/`.

## Verification
- `flutter analyze` passes with no issues.
- Missing image check: 2161 tiles currently without images; this is a data-level issue unrelated to the tab/sub-board changes and not caused by this edit.

---

# Charlie Chat - Flutter SDK Update

## Summary
Updated the Flutter SDK from 3.44.5 to the latest stable release (3.44.6) and fixed the analyzer issues introduced by the newer SDK/tooling.

## What was changed
- Ran `flutter upgrade` from `C:\Flutter`.
- Upgraded to **Flutter 3.44.6** (stable), **Dart 3.12.2**, **DevTools 2.57.0**.
- Fixed the following analyzer issues that appeared with the new SDK:
  - `lib/main.dart`: removed an unused local variable.
  - `lib/services/board_service.dart`: removed an unused private helper.
  - `lib/widgets/board_editor.dart`: updated the `BuildContext` mounted guard to use `context.mounted` and suppressed `file_picker` 12.x beta deprecation warnings.
  - `lib/widgets/settings/sections/custom_symbols_section.dart`: suppressed `file_picker` 12.x beta deprecation warnings.
- Added `tools/update_flutter.bat` to make future upgrades repeatable.

## Files changed
- `lib/main.dart`
- `lib/services/board_service.dart`
- `lib/widgets/board_editor.dart`
- `lib/widgets/settings/sections/custom_symbols_section.dart`
- `tools/update_flutter.bat`
- `tools/update_flutter.log`

## Verification
- `flutter analyze` passes with no issues.
- `flutter doctor` reports Flutter 3.44.6 on the stable channel; all expected tooling is available.
