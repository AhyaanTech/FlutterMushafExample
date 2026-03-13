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

### Letter Breakdown Table (letter_breakdown)
Character-level segmentation table for Quranic text analysis with diacritical metadata.

| Column | Notes |
|--------|-------|
| word_id | Foreign key to mushaf_pages.word_id |
| verse_key | Format "surah:ayah" (e.g., "1:1") |
| letter_index | Position within word (0-based, RTL) |
| base_letter | Arabic letter without diacritics |
| letter_with_diacritics | Full letter with tashkeel |
| diacritics_json | JSON array of diacritic objects |
| has_fatha/kasra/damma/sukun/shadda | Boolean flags for quick filtering |
| has_tanwin_* | Boolean flags for tanwin types |
| has_maddah/hamza_* | Boolean flags for special marks |
| has_superscript/subscript_alef | Boolean flags for Uthmani script |
| letter_type | 'consonant', 'vowelCarrier', 'longVowel' |

**Statistics**: ~341,062 letters across 83,668 words (avg 4.1 letters/word)

**Dart Model**: [`QuranLetter`](lib/models/quran_letter_models.dart:67) - Full letter data with diacritics

**Usage Examples**:
```sql
-- Get letters of a specific word
SELECT * FROM letter_breakdown WHERE word_id = 123 ORDER BY letter_index;

-- Find all words with shadda
SELECT DISTINCT word_id FROM letter_breakdown WHERE has_shadda = 1;

-- Count fatha occurrences by letter
SELECT base_letter, COUNT(*) FROM letter_breakdown WHERE has_fatha = 1 GROUP BY base_letter;
```

### Code Generation/Rebuild
To rebuild the SQLite database from source:
```bash
# Merge base databases
python scripts/merge_quran_dbs.py

# Generate letter breakdown table
python scripts/generate_letter_breakdown.py
```
Requires: `qpc-hafs-word-by-word.db` and `qudratullah-indopak-15-lines.db` in project root.

## Key Gotchas
1. **No persistence layer**: Marked words not saved - adding persistence requires new dependency (shared_preferences/hive)
2. **Legacy models exist**: `Surah`, `Ayah`, `Word` classes in [`quran_models.dart`](lib/models/quran_models.dart:132) are unused - app uses `QuranWord`, `QuranLine`, `QuranPage`
3. **Widget key handling**: Each word widget gets unique identity via `word.id` - changing this breaks mark state tracking
4. **Database path**: Uses `getApplicationDocumentsDirectory()` - different path per platform
5. **Total pages hardcoded**: 604 pages in [`PageView.builder`](lib/screens/mushaf_screen.dart:192), but DB has 610 - mismatch intentional for common Mushaf layout

## External Resources & APIs

### QUL (Quranic Universal Library) - Tarteel
[QUL](https://qul.tarteel.io) is an open-source platform by Tarteel that centralizes high-quality Quranic resources for developers. It provides standardized Quranic text, translations, tafsir, recitations, and Mushaf layouts.

**Relevance to Letter Breakdown**:
- Uses same `verse_key` format (surah:ayah) for verse identification
- Provides word-by-word alignment data compatible with this schema
- Morphological annotations can be cross-referenced with letter positions

### PyArabic Library
[PyArabic](https://pypi.org/project/PyArabic/) is a Python library for Arabic text processing that can supplement the letter breakdown data.

```bash
pip install pyarabic
```

**Useful Functions**:
- `araby.strip_diacritics(text)` - Remove tashkeel to get base text
- `araby.separate_diacritics(text)` - Separate letters from diacritics
- `araby.is_arabicletter(char)` - Check if character is Arabic letter

### Unicode Arabic Blocks
- **Arabic**: U+0600 - U+06FF (Base Arabic letters and diacritics)
- **Arabic Supplement**: U+0750 - U+077F (Extended Arabic letters)
- **Arabic Extended-A**: U+08A0 - U+08FF (Additional Quranic characters)

### Related Data Sources
1. **Quran Complexity Project**: Character-level linguistic analysis
2. ** Tanzil Quran Text**: Uthmani script standard reference
3. **King Fahd Quran Complex**: Official Mushaf fonts and layouts

## TextSpan Rendering Approach

The letter breakdown table is designed to work with Flutter's TextSpan rendering:

```dart
// Example: Build colored TextSpans from letter data
List<TextSpan> buildLetterSpans(List<QuranLetter> letters) {
  return letters.map((letter) => TextSpan(
    text: letter.phonetic,
    style: TextStyle(
      color: getTajweedColor(letter), // Color based on diacritics
      fontFamily: 'Scheherazade',
    ),
    recognizer: TapGestureRecognizer()
      ..onTap = () => onLetterTapped(letter),
  )).toList();
}

Color getTajweedColor(QuranLetter letter) {
  if (letter.hasShadda) return Colors.red;
  if (letter.hasMaddah) return Colors.blue;
  return Colors.black;
}
```
