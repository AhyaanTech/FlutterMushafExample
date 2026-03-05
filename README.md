# Interactive Offline Mushaf (Flutter)

A Flutter proof-of-concept application for an interactive Quran (Mushaf) with a physical 15-line layout. Every word is a distinct, interactive widget that can be tapped to mark for memorization.

## Features

- **Offline-First**: Complete Quran database bundled with the app (no internet required)
- **15-Line Layout**: Authentic Madinah-style Mushaf layout with proper line distribution
- **Interactive Words**: Tap any word to mark/unmark it (black ↔ red) for memorization practice
- **Page Navigation**: Swipe left/right or use jump-to-page dialog
- **RTL Support**: Full Arabic right-to-left text direction
- **Block Alignment**: Words are distributed across lines like a physical Mushaf

## Screenshots

*Coming soon*

## Project Structure

```
lib/
├── main.dart                     # App entry point with RTL configuration
├── models/
│   └── quran_models.dart         # Data models: QuranWord, QuranLine, QuranPage
├── services/
│   └── database_helper.dart      # SQLite database service (singleton)
├── screens/
│   └── mushaf_screen.dart        # Main screen with PageView navigation
└── widgets/
    └── mushaf_widgets.dart       # UI components: word, line, page widgets

assets/
└── db/
    └── quran_offline.db          # Unified Quran database (6.88 MB)

scripts/
└── merge_quran_dbs.py            # Python script to merge source databases
```

## Getting Started

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart 3.0 or higher
- Python 3.8+ (for database merging script, if rebuilding database)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd FlutterMushafExample
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

   Or for a specific platform:
   ```bash
   flutter run -d macos     # macOS
   flutter run -d ios       # iOS
   flutter run -d android   # Android
   ```

## Database Setup

The app includes a pre-built database at `assets/db/quran_offline.db`. If you need to rebuild it:

### Source Data

Data comes from the [Tarteel Quranic Universal Library (QUL)](https://qul.tarteel.ai/resources):

1. **Layout Database**: `qudratullah-indopak-15-lines.db` - Contains page/line coordinates
2. **Script Database**: `qpc-hafs-word-by-word.db` - Contains Uthmani Arabic text

### Building the Database

```bash
# Run the Python merging script
python scripts/merge_quran_dbs.py
```

This creates `assets/db/quran_offline.db` with:
- **610 pages** (15-line IndoPak Mushaf layout)
- **6,236 verses**
- **83,668 words**
- **6.88 MB** file size

## Architecture

### Data Flow

```
User taps word
    ↓
MushafWordWidget.onTap → MushafLineWidget.onWordTap
    ↓
MushafScreen.toggleWordMark() → updates Set<int> markedWordIds
    ↓
setState() rebuilds UI with new mark state
```

### Database Schema

**Table: `mushaf_pages`**
| Column | Type | Description |
|--------|------|-------------|
| page_number | INTEGER | Mushaf page (1-610) |
| line_number | INTEGER | Line on page (1-15) |
| word_id | INTEGER | Unique word identifier |
| arabic_text | TEXT | Uthmani Arabic script |
| verse_key | TEXT | Format "surah:ayah" |
| line_type | TEXT | 'surah_name', 'basmallah', or 'ayah' |
| is_centered | INTEGER | 1 if centered, 0 if not |

### Key Components

| Component | Responsibility |
|-----------|---------------|
| `DatabaseHelper` | Singleton managing SQLite connection, copies DB from assets on first launch |
| `QuranWord` | Model for individual words with id, text, verseKey |
| `QuranLine` | Model for lines containing list of words |
| `QuranPage` | Model for pages containing list of lines |
| `MushafWordWidget` | Renders single word with tap handler |
| `MushafLineWidget` | Renders line of words with proper alignment |
| `MushafPageWidget` | Renders complete page with 15 lines |
| `MushafScreen` | Main screen with PageView, state management |

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  sqflite: ^2.3.0          # SQLite database
  path_provider: ^2.1.1    # File system access
  path: ^1.8.3             # Path manipulation
```

## Customization

### Adding Custom Fonts

1. Download Arabic fonts (e.g., Amiri, Scheherazade from Google Fonts)
2. Place in `fonts/` directory
3. Uncomment font definitions in `pubspec.yaml`:
   ```yaml
   fonts:
     - family: Amiri
       fonts:
         - asset: fonts/Amiri-Regular.ttf
   ```

### Changing Mark Color

Edit `lib/widgets/mushaf_widgets.dart`:
```dart
// Change Colors.red to your preferred color
color: isMarked ? Colors.red : Colors.black,
```

### Font Size Adjustment

Edit `lib/widgets/mushaf_widgets.dart`:
```dart
TextStyle(
  fontSize: 32,  // Adjust this value
  // ...
)
```

## Known Issues & Limitations

1. **Font Loading**: Currently uses system fonts with fallbacks. Custom fonts can be added by following the customization guide above.

2. **State Persistence**: Marked words are stored in memory only. They reset when app restarts. To persist:
   - Add `shared_preferences` or `hive` package
   - Save `markedWordIds` on change
   - Load on app startup

3. **Performance**: Large pages with many words may have slight jank during initial load. Consider:
   - Using `RepaintBoundary` around word widgets
   - Implementing word recycling for very long lists

## Future Enhancements

- [ ] Audio playback for word-by-word recitation
- [ ] Bookmarking specific pages
- [ ] Search functionality
- [ ] Multiple Mushaf layouts (16-line, etc.)
- [ ] Night mode / theme switching
- [ ] Persistent storage for marked words
- [ ] Export marked words for review
- [ ] Tajweed color coding

## License

This project is for educational purposes. Quran data from [Tarteel QUL](https://qul.tarteel.ai/) - please refer to their licensing terms.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Acknowledgments

- [Tarteel](https://www.tarteel.ai/) for the Quranic Universal Library data
- [King Fahd Glorious Quran Printing Complex](https://qurancomplex.gov.sa/) for the Uthmani script
- Flutter team for the amazing framework
