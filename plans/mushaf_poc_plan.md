# Interactive Offline Mushaf Flutter POC - Implementation Plan

## Project Overview
Build a Flutter proof-of-concept for an interactive Quran (Mushaf) application that renders a physical Mushaf layout with every word as a distinct, interactive widget, using offline SQLite data.

## Current State Analysis
- **Layout Database**: `qudratullah-indopak-15-lines.db` (contains page/line coordinates)
- **Script Database**: `qpc-hafs-word-by-word.db` (contains Arabic word-by-word text)
- **Font**: Need to download Uthmani font

## Implementation Steps

### Phase 1: Data Preparation Pipeline
1. **Examine database schemas** to understand table structures
2. **Create Python merging script** (`merge_quran_dbs.py`) that:
   - Attaches both SQLite databases
   - Performs JOIN operation to map Arabic text to page/line coordinates
   - Creates unified `mushaf_pages` table with columns: `page_number`, `line_number`, `word_id`, `arabic_text`, `verse_key`
   - Outputs to `assets/db/quran_offline.db`
3. **Download Uthmani font** from QUL resources
4. **Test the merging script** with existing databases

### Phase 2: Flutter App Setup
1. **Initialize Flutter project structure** (if not already done)
2. **Configure `pubspec.yaml`** with:
   - `sqflite` dependency
   - `path_provider` dependency  
   - Custom font configuration
   - Asset declarations for database and font
3. **Create directory structure**:
   - `assets/db/` for database
   - `assets/fonts/` for font files

### Phase 3: Database Service Layer
1. **Create `database_helper.dart`** as singleton service
2. **Implement database initialization**:
   - Copy `quran_offline.db` from assets to app directory on first launch
3. **Create query method**:
   - `getPageData(int pageNumber)` returning ordered page data

### Phase 4: Data Models & State Management
1. **Create Dart models**:
   - `QuranWord` class
   - `QuranLine` class  
   - `QuranPage` class
2. **Implement state management** for marked words using `Set<int>`

### Phase 5: UI Implementation
1. **Create `MushafScreen`** with `PageView.builder` (pages 1-604)
2. **Create `MushafPageWidget`** with RTL directionality and Column layout
3. **Create `MushafLineWidget`** with Row layout and spaceBetween alignment
4. **Create `MushafWordWidget`** with GestureDetector and font styling
5. **Implement tap interactivity** for word marking

### Phase 6: Testing & Validation
1. **Test database merging** and verify data integrity
2. **Test offline functionality** without internet connection
3. **Validate UI rendering** matches physical Mushaf layout
4. **Test interactivity** (word marking/unmarking)

## Dependencies
- **Python**: sqlite3, sys, os
- **Flutter**: sqflite, path_provider
- **Assets**: Uthmani font file, merged SQLite database

## Expected Output Structure
```
FlutterMushafExample/
├── assets/
│   ├── db/
│   │   └── quran_offline.db
│   └── fonts/
│       └── KFGQPC_Uthmanic_Script_HAFS.ttf
├── lib/
│   ├── database/
│   │   └── database_helper.dart
│   ├── models/
│   │   ├── quran_word.dart
│   │   ├── quran_line.dart
│   │   └── quran_page.dart
│   ├── widgets/
│   │   ├── mushaf_screen.dart
│   │   ├── mushaf_page_widget.dart
│   │   ├── mushaf_line_widget.dart
│   │   └── mushaf_word_widget.dart
│   └── main.dart
├── merge_quran_dbs.py
└── pubspec.yaml