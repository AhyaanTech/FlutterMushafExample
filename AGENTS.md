# AGENTS.md

Guidelines for AI agents working on this Flutter Mushaf (Quran) application.

## Build Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run -d macos          # Primary platform
flutter run                   # Auto-detect device

# Code quality
flutter analyze               # Lint (uses flutter_lints)
flutter test                  # Run all tests
flutter test test/foo_test.dart   # Run single test file
flutter test --name "testName"    # Run specific test by name

# Build
flutter build macos           # Production build
flutter build apk             # Android build
```

## Database Build Commands

```bash
# Main build script (unified)
uv run scripts/build_db.py --full        # Build + validate everything
uv run scripts/build_db.py --build       # Build core tables only
uv run scripts/build_db.py --validate    # Validate existing database
uv run scripts/build_db.py --schema      # Show schema

# Letter breakdown (separate step)
uv run scripts/build_letters.py          # Build letter_breakdown table
uv run scripts/build_letters.py --stats  # Show letter statistics
uv run scripts/build_letters.py --all-tests  # Run all tests
```

## Code Style Guidelines

### Imports
- Order: Dart SDK → Flutter packages → Third-party → Project (models, services, screens, widgets)
- Use relative imports for project files: `import '../models/quran_models.dart'`
- Group imports with a blank line between groups

### Formatting
- Use `dart format` (enforced by flutter_lints)
- Max line length: 80 characters
- Trailing commas for multi-line parameters

### Naming Conventions
- **Files**: snake_case (e.g., `mushaf_screen.dart`)
- **Classes**: PascalCase (e.g., `MushafScreen`)
- **Variables/Functions**: camelCase (e.g., `markedWordIds`)
- **Constants**: camelCase for local, PascalCase for enum values
- **Private members**: Leading underscore (e.g., `_pageCache`)

### Types
- Always specify types for public APIs
- Use `final` for immutable variables
- Prefer `const` constructors where possible
- Use `late` only when necessary (e.g., `Future` initialization)

### Error Handling
- Use `try-catch` for async operations (database, file I/O)
- Log errors with `print()` before rethrowing
- Return nullable types for potentially empty queries
- Use `rethrow` to preserve stack traces

### State Management
- Simple in-memory state with `Set<int>` and `Map<K, V>`
- Prop drilling through widget constructors
- No external state management (Provider, Bloc, etc.)

## Project Architecture

### Directory Structure
```
lib/
├── main.dart                 # Entry point, app initialization
├── models/                   # Data models
│   ├── quran_models.dart     # QuranWord, QuranLine, QuranPage
│   ├── tajweed_models.dart   # ColorMode, RenderingMode, LetterData
│   └── quran_letter_models.dart  # QuranLetter with diacritics
├── services/                 # Business logic
│   └── database_helper.dart  # SQLite singleton, caching
├── screens/                  # Full screens
│   └── mushaf_screen.dart    # Main Mushaf with PageView
└── widgets/                  # Reusable components
    ├── mushaf_widgets.dart   # Page/Line/Word widgets
    ├── mushaf_word_factory.dart   # Rendering mode factory
    ├── mushaf_word_textspan.dart  # TextSpan implementation
    ├── mushaf_word_glyph.dart     # CustomPainter implementation
    └── color_picker_dialog.dart   # Letter color picker

scripts/
├── build_db.py              # Main entry point
└── quran_db/                # Build modules
    ├── cli.py              # Command-line interface
    ├── builders.py         # Core table builders
    ├── letter_builder.py   # Letter breakdown builder
    ├── validators.py       # Database validation
    ├── database.py         # DB connection utilities
    └── config.py           # Constants and paths
```

### Database Architecture
- **SQLite bundled DB**: Pre-built at `assets/db/quran_offline.db` (102MB), copied on first launch
- **Singleton pattern**: `DatabaseHelper()` factory constructor
- **Page cache**: `_pageCache` Map for smooth PageView swiping
- **Adjacent preloading**: `_preloadAdjacentPages()` loads prev/next pages

### Font Stack (RTL Critical)
```dart
fontFamilyFallback: const [
  'UthmanicHafs',    // Primary QPC font
  '.SF Arabic',      // iOS/macOS Arabic (critical for macOS)
  'Roboto',          // Android
  'Arial',           // Windows/macOS fallback
  'Noto Sans Arabic',
  'Scheherazade',
]
```
- App forces RTL: `locale: const Locale('ar', 'SA')` in main.dart
- PageView uses `reverse: true` for RTL swipe direction

### Key Patterns

**Factory Pattern for Rendering:**
```dart
// mushaf_word_factory.dart switches between TextSpan and Glyph modes
MushafWordFactory.build(
  word: word,
  mode: RenderingMode.textspan,  // or .glyph
  colorMode: ColorMode.custom,   // none, tajweed, mistakes, custom
  // ...
);
```

**Letter-by-Letter Coloring:**
- Custom colors stored in `Map<int, List<Color?>>` (wordId → letter colors)
- Tap handler shows `ColorPickerDialog` in Custom mode
- TextSpan mode supports full letter-level tap detection
- Glyph mode has limited support (word-level only)

## Database Schema

### Core Tables
| Table | Purpose | Rows |
|-------|---------|------|
| words | Core word data (id, surah, ayah, text) | ~83,668 |
| ayahs | Verse metadata | ~6,236 |
| surahs | Chapter metadata | 114 |
| mushaf_pages | 15-line layout coordinates | ~1.2M |
| metadata | Build info | 5 |
| letter_breakdown | Character-level segmentation | ~341,062 |

### mushaf_pages Table
| Column | Notes |
|--------|-------|
| page_number | 1-610 for 15-line Mushaf |
| line_number | 1-15 per page |
| word_id | Global unique ID |
| verse_key | Format "surah:ayah" |
| line_type | 'surah_name', 'basmallah', 'ayah' |
| is_centered | 1 for headers, 0 for ayah text |

### letter_breakdown Table
Character-level segmentation with diacritical metadata:
- `word_id`, `letter_index`, `base_letter`, `letter_with_diacritics`
- Boolean flags: `has_fatha`, `has_shadda`, `has_maddah`, etc.
- ~341,062 letters across 83,668 words

## Source Databases (Required)

| File | Purpose | Source |
|------|---------|--------|
| `qpc-hafs-word-by-word.db` | Word text | QUL KFGQPC Hafs |
| `digital-khatt-15-lines.db` | 15-line layout | Digital Khatt KFGQPC V2 |
| `qpc-hafs-tajweed-word.db` | Tajweed colors | QUL (optional) |

**⚠️ Important**: Must use Uthmani script sources. IndoPak has different page breaks.

## Important Notes

1. **No persistence**: Marked words and custom colors reset on app restart
2. **Legacy models**: `Surah`, `Ayah`, `Word` in quran_models.dart are unused
3. **Widget keys**: Word widgets use `word.id` for identity—don't change this
4. **Page count mismatch**: 604 pages hardcoded in UI, but DB has 610 (intentional)
5. **Database build**: Two-step process - `build_db.py` then `build_letters.py`

## External Resources

- **QUL (Quranic Universal Library)**: https://qul.tarteel.io
- **PyArabic**: `pip install pyarabic` for Arabic text processing
- **Unicode Arabic**: U+0600-U+06FF (base), U+08A0-U+08FF (extended)
