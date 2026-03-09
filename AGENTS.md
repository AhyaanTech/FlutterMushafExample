# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Overview
Interactive offline Mushaf (Quran) Flutter app with 15-line layout and tap-to-mark words for memorization. Features letter-by-letter custom coloring for Tajweed study and memorization assistance.

## Build/Run Commands
- `flutter pub get` - Install dependencies
- `flutter run -d macos` - Run on macOS (primary platform)
- `flutter run` - Auto-detect device
- `flutter analyze` - Lint (uses `flutter_lints` from `analysis_options.yaml`)
- `flutter test` - Run tests (none currently)

## Project-Specific Patterns

### Database Architecture
- **SQLite bundled DB**: Pre-built at `assets/db/quran_offline.db` (6.88MB), copied from assets on first launch via [`DatabaseHelper._copyDatabaseFromAssets()`](lib/services/database_helper.dart:66)
- **Singleton pattern**: [`DatabaseHelper`](lib/services/database_helper.dart:10) is singleton - use `DatabaseHelper()` factory, not `new DatabaseHelper()`
- **Page cache**: [`MushafScreen._pageCache`](lib/screens/mushaf_screen.dart:39) in-memory LRU-style cache for smooth swiping
- **Adjacent preloading**: [`_preloadAdjacentPages()`](lib/screens/mushaf_screen.dart:102) preloads prev/next pages automatically

### Font Stack (Non-obvious RTL handling)
System fonts used with fallback chain in [`MushafWordWidget`](lib/widgets/mushaf_widgets.dart:35):
```dart
fontFamilyFallback: const [
  '.SF Arabic',      // iOS/macOS Arabic (critical for macOS)
  'Roboto',          // Android
  'Arial',           // Windows/macOS fallback
  'Noto Sans Arabic',
  'Scheherazade',
]
```
App forces RTL locale via `locale: const Locale('ar', 'SA')` in [`main.dart`](lib/main.dart:173).

### State Management
- **In-memory only**: [`MushafScreen._markedWordIds`](lib/screens/mushaf_screen.dart:33) is `Set<int>` - marks reset on app restart
- **Prop drilling**: Word mark state passed down: `MushafScreen` → `MushafPageWidget` → `MushafLineWidget` → `MushafWordFactory` → (`MushafWordTextSpan` or `MushafWordGlyph`)
- **PageView reverse**: `reverse: true` in [`PageView.builder`](lib/screens/mushaf_screen.dart:191) for RTL swipe direction (left = next page)

### Letter-by-Letter Custom Coloring
- **ColorMode enum**: Four modes in [`tajweed_models.dart`](lib/models/tajweed_models.dart:10): `none`, `tajweed`, `mistakes`, `custom`
- **CustomLetterColor model**: Tracks `wordId`, `letterIndex`, and `color` at [`tajweed_models.dart:217`](lib/models/tajweed_models.dart:217)
- **Custom color state**: [`MushafScreen._customLetterColors`](lib/screens/mushaf_screen.dart:41) is `Map<int, List<Color?>>` - keyed by word ID
- **Color picker dialog**: [`ColorPickerDialog`](lib/widgets/color_picker_dialog.dart) provides predefined Tajweed colors and custom picker
- **Rendering modes**: 
  - TextSpan mode ([`MushafWordTextSpan`](lib/widgets/mushaf_word_textspan.dart)): Full letter-level tap detection and coloring
  - Glyph mode ([`MushafWordGlyph`](lib/widgets/mushaf_word_glyph.dart)): Limited custom color support, word-level tap only
- **Factory pattern**: [`MushafWordFactory`](lib/widgets/mushaf_word_factory.dart) switches between rendering modes
- **Usage**: Select "Custom" from color mode dropdown, tap individual letters to apply colors

### Database Schema (mushaf_pages table)
| Column | Notes |
|--------|-------|
| page_number | 1-610 for 15-line IndoPak Mushaf |
| line_number | 1-15 per page |
| word_id | Global unique ID from QPC database |
| verse_key | Format "surah:ayah" (e.g., "1:1") |
| line_type | Enum: 'surah_name', 'basmallah', 'ayah' |
| is_centered | 1 for surah names/basmallah, 0 for ayah text |

### Code Generation/Rebuild
To rebuild the SQLite database from source:
```bash
python scripts/merge_quran_dbs.py
```
Requires: `qpc-hafs-word-by-word.db` and `qudratullah-indopak-15-lines.db` in project root.

## Key Gotchas
1. **No persistence layer**: Marked words not saved - adding persistence requires new dependency (shared_preferences/hive)
2. **Legacy models exist**: `Surah`, `Ayah`, `Word` classes in [`quran_models.dart`](lib/models/quran_models.dart:132) are unused - app uses `QuranWord`, `QuranLine`, `QuranPage`
3. **Widget key handling**: Each word widget gets unique identity via `word.id` - changing this breaks mark state tracking
4. **Database path**: Uses `getApplicationDocumentsDirectory()` - different path per platform
5. **Total pages hardcoded**: 604 pages in [`PageView.builder`](lib/screens/mushaf_screen.dart:192), but DB has 610 - mismatch intentional for common Mushaf layout
