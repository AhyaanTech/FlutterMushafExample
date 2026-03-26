# Quran Offline Database Schema & State

**Last Updated:** 2026-03-16  
**Status:** Database ready, Flutter needs rewrite  
**Source of Truth:** `word_id` from QPC (Quran Programming Community) databases

---

## Database Files

| File | Size | Purpose |
|------|------|---------|
| `assets/db/quran_offline.db` | 106.9 MB | Main bundled database with all data |
| `qpc-hafs-tajweed.db` | ~20 MB | Separate file with words table (NO color data) |

---

## Table Overview

| Table | Rows | Purpose | Status |
|-------|------|---------|--------|
| `words` | 83,668 | Core word data with Arabic Uthmani text | ✅ Working |
| `ayahs` | 6,236 | Verse metadata (juz, hizb, sajda, etc.) | ⚠️ Partial (NULL values) |
| `surahs` | 114 | Surah metadata (names, revelation, verse count) | ⚠️ Partial (NULL names) |
| `mushaf_pages` | 83,668 | 15-line Mushaf layout coordinates | ✅ Working |
| `letter_breakdown` | 341,062 | Character-level analysis with diacritics | ✅ Working |
| `metadata` | 5+ | Build info and source tracking | ✅ Working |
| `words_tajweed` | ❌ MISSING | Official Tajweed color data | ❌ Not implemented |

---

## Schema Details

### 1. `words` - Core Word Table

Primary table for Quranic words. Every word in the Quran with unique global ID.

```sql
CREATE TABLE words (
    id INTEGER PRIMARY KEY,           -- Global word_id (source of truth)
    surah INTEGER NOT NULL,           -- 1-114
    ayah INTEGER NOT NULL,            -- 1-286
    word_position INTEGER NOT NULL,   -- Position within ayah (1-based)
    text TEXT NOT NULL,               -- Uthmani script Arabic text
    verse_key TEXT NOT NULL           -- Format: "surah:ayah"
);

-- Indexes
CREATE INDEX idx_words_surah_ayah ON words(surah, ayah);
CREATE INDEX idx_words_verse_key ON words(verse_key);
```

**Relationships:**
- Referenced by: `mushaf_pages.word_id`, `letter_breakdown.word_id`

---

### 2. `ayahs` - Verse Metadata

Per-verse metadata including structural divisions.

```sql
CREATE TABLE ayahs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    verse_key TEXT NOT NULL UNIQUE,   -- Format: "surah:ayah"
    surah INTEGER NOT NULL,           -- 1-114
    ayah INTEGER NOT NULL,            -- 1-286
    text TEXT,                        -- Complete verse text (NULL - not populated)
    juz INTEGER,                      -- 1-30 (NULL)
    hizb INTEGER,                     -- 1-60 (NULL)
    rub INTEGER,                      -- 1-240 (NULL)
    manzil INTEGER,                   -- 1-7 (NULL)
    ruku INTEGER,                     -- Ruku number (NULL)
    sajda_type TEXT,                  -- 'recommended', 'obligatory', or NULL
    sajda_id INTEGER,                 -- Reference to sajda entry (NULL)
    page INTEGER,                     -- Page in 15-line Mushaf (NULL)
    first_word_id INTEGER,            -- First word in verse (NULL)
    last_word_id INTEGER,             -- Last word in verse (NULL)
    word_count INTEGER                -- Number of words (NULL)
);
```

**Status:** ⚠️ Structure exists but most columns are NULL

---

### 3. `surahs` - Surah Metadata

Information about each of the 114 chapters.

```sql
CREATE TABLE surahs (
    id INTEGER PRIMARY KEY,           -- 1-114
    name_ar TEXT,                     -- Arabic name (NULL - not populated)
    name_en TEXT,                     -- English transliteration (NULL)
    name_translation TEXT,            -- English meaning (NULL)
    revelation_type TEXT,             -- 'meccan' or 'medinan' (NULL)
    verses_count INTEGER NOT NULL,    -- Number of ayahs ✅
    first_ayah_id INTEGER,            -- First verse in surah (NULL)
    last_ayah_id INTEGER,             -- Last verse in surah (NULL)
    first_word_id INTEGER,            -- First word in surah (NULL)
    last_word_id INTEGER,             -- Last word in surah (NULL)
    bismillah_pre TEXT                -- Bismillah text if different (NULL)
);
```

**Status:** ⚠️ Only `id` and `verses_count` populated

---

### 4. `mushaf_pages` - Layout Coordinates

15-line Mushaf layout. Each row is one word on a specific page/line.

```sql
CREATE TABLE mushaf_pages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    page_number INTEGER NOT NULL,     -- 1-604 (15-line Mushaf)
    line_number INTEGER NOT NULL,     -- 1-15 per page
    word_id INTEGER NOT NULL,         -- FK to words.id
    verse_key TEXT NOT NULL,          -- Denormalized: "surah:ayah"
    line_type TEXT,                   -- Currently ALL 'ayah' ⚠️
    is_centered INTEGER DEFAULT 0,    -- 1 for headers/basmallah
    
    FOREIGN KEY (word_id) REFERENCES words(id)
);

-- Indexes
CREATE INDEX idx_mushaf_pages_page ON mushaf_pages(page_number);
CREATE INDEX idx_mushaf_pages_page_line ON mushaf_pages(page_number, line_number);
CREATE INDEX idx_mushaf_pages_word ON mushaf_pages(word_id);
CREATE INDEX idx_mushaf_pages_verse ON mushaf_pages(verse_key);
```

**Known Issues:**
- ⚠️ All `line_type = 'ayah'` - No surah headers or basmallah markers
- ⚠️ Page 1 starts at line 2 (missing line 1 for Al-Fatiha header)
- ✅ 604 pages with proper word positioning

---

### 5. `letter_breakdown` - Character Analysis

Granular letter-level data with diacritics for letter-by-letter rendering.

```sql
CREATE TABLE letter_breakdown (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    word_id INTEGER NOT NULL,         -- FK to words.id
    verse_key TEXT NOT NULL,          -- Denormalized
    word_position INTEGER NOT NULL,   -- Position within verse
    letter_index INTEGER NOT NULL,    -- Position within word (RTL, 0-based)
    base_letter TEXT NOT NULL,        -- Letter without diacritics
    letter_with_diacritics TEXT,      -- Full letter + tashkeel
    base_letter_codepoint INTEGER,    -- Unicode codepoint
    base_letter_category TEXT,        -- Unicode category
    base_letter_name TEXT,            -- Unicode name
    diacritics_json TEXT,             -- JSON array of diacritic objects
    
    -- Boolean flags (0/1) for quick filtering
    has_fatha INTEGER DEFAULT 0,
    has_kasra INTEGER DEFAULT 0,
    has_damma INTEGER DEFAULT 0,
    has_sukun INTEGER DEFAULT 0,
    has_shadda INTEGER DEFAULT 0,
    has_tanwin_fath INTEGER DEFAULT 0,
    has_tanwin_kasr INTEGER DEFAULT 0,
    has_tanwin_damm INTEGER DEFAULT 0,
    has_maddah INTEGER DEFAULT 0,
    has_hamza_above INTEGER DEFAULT 0,
    has_hamza_below INTEGER DEFAULT 0,
    has_superscript_alef INTEGER DEFAULT 0,
    has_subscript_alef INTEGER DEFAULT 0,
    has_small_high_sad_lam INTEGER DEFAULT 0,
    has_small_high_qaf_lam INTEGER DEFAULT 0,
    has_small_high_meem_initial INTEGER DEFAULT 0,
    has_small_high_lam INTEGER DEFAULT 0,
    has_small_high_jeem INTEGER DEFAULT 0,
    has_small_high_three_dots INTEGER DEFAULT 0,
    has_small_high_seen INTEGER DEFAULT 0,
    has_small_high_rounded_zero INTEGER DEFAULT 0,
    has_small_high_upright_zero INTEGER DEFAULT 0,
    has_small_high_dotless_head INTEGER DEFAULT 0,
    has_small_high_meem_isolated INTEGER DEFAULT 0,
    has_small_low_seen INTEGER DEFAULT 0,
    has_small_high_maddah INTEGER DEFAULT 0,
    has_small_waw INTEGER DEFAULT 0,
    has_small_yeh INTEGER DEFAULT 0,
    has_small_high_noon INTEGER DEFAULT 0,
    has_small_high_three_dots_alt INTEGER DEFAULT 0,
    has_empty_centre_low_stop INTEGER DEFAULT 0,
    has_empty_centre_high_stop INTEGER DEFAULT 0,
    has_rounded_high_stop INTEGER DEFAULT 0,
    has_small_low_meem INTEGER DEFAULT 0,
    -- Note: has_end_of_ayah, has_start_of_rub, has_place_of_sajdah removed
    -- These are standalone markers (U+06DD, U+06DE, U+06E9), not diacritics
    
    letter_type TEXT,                 -- 'consonant' | 'vowel_carrier' | 'long_vowel'
    is_hamza_variant INTEGER DEFAULT 0,
    source_db TEXT,                   -- Origin database name
    
    UNIQUE(word_id, letter_index)
    FOREIGN KEY (word_id) REFERENCES words(id)
);

-- Indexes
CREATE INDEX idx_letter_word ON letter_breakdown(word_id);
CREATE INDEX idx_letter_verse ON letter_breakdown(verse_key);
CREATE INDEX idx_letter_base ON letter_breakdown(base_letter);
CREATE INDEX idx_letter_shadda ON letter_breakdown(has_shadda);
CREATE INDEX idx_letter_fatha ON letter_breakdown(has_fatha);
```

**Statistics:**
- 341,062 letters across 83,668 words
- Average: 4.08 letters per word
- 100% coverage - all words have letter data

**diacritics_json format:**
```json
[
  {"char": "\u0650", "codepoint": 1616, "name": "ARABIC KASRA", "type": "haraka"},
  {"char": "\u0651", "codepoint": 1617, "name": "ARABIC SHADDA", "type": "shadda"}
]
```

---

### 6. `metadata` - Build Information

Key-value store for database provenance.

```sql
CREATE TABLE metadata (
    key TEXT PRIMARY KEY,
    value TEXT
);
```

**Standard keys:**
- `source_words_db` - Path to words source
- `source_layout_db` - Path to layout source  
- `total_pages` - 610 (metadata says 610, but actual is 604)
- `lines_per_page` - 15
- `merged_at` - ISO timestamp
- `version` - Schema version

---

## Entity Relationships

```
surahs (1) ----< (N) ayahs (1) ----< (N) words (1) ----< (N) letter_breakdown
                                     |
                                     ^
                                     |
mushaf_pages (N) --------------------'
```

**Key:**
- `----<` = One-to-Many relationship
- `words.id` = Source of truth (word_id)

---

## Query Patterns

### Get all words on a page (for rendering)
```sql
SELECT mp.*, w.text as arabic_text
FROM mushaf_pages mp
LEFT JOIN words w ON w.id = mp.word_id
WHERE mp.page_number = ?
ORDER BY mp.line_number ASC, mp.word_id ASC
```

### Get letters of a word (for letter-by-letter rendering)
```sql
SELECT * FROM letter_breakdown 
WHERE word_id = ? 
ORDER BY letter_index ASC
```

### Find all words with shadda
```sql
SELECT DISTINCT lb.word_id, w.text
FROM letter_breakdown lb
JOIN words w ON w.id = lb.word_id
WHERE lb.has_shadda = 1
```

---

## Known Issues & Limitations

### Critical Issues
1. **Missing Tajweed Colors** - `words_tajweed` table doesn't exist
   - **Workaround:** Infer basic rules from diacritics (maddah→blue, shadda→yellow, etc.)

2. **No Surah Headers** - All `line_type = 'ayah'`
   - **Impact:** No decorative surah names or basmallah rendering
   - **Workaround:** Detect surah boundaries programmatically from verse_key changes

3. **Missing Metadata** - `surahs` and `ayahs` tables have NULL values
   - **Impact:** No surah names, juz/hizb markers, sajda indicators
   - **Workaround:** Use verse_key parsing for basic navigation

### Fixed Issues
✅ Database table name mismatch (`word_letters` vs `letter_breakdown`)  
✅ Desktop platform support (`sqflite_common_ffi`)  
✅ Query joins `words` table for Arabic text  
✅ Foreign key relationships validated  

---

## Future Tables (Pending)

| Table | Purpose | Status |
|-------|---------|--------|
| `words_tajweed` | Official Tajweed color data per word | ❌ Missing - need QUL source |
| `translations` | Translations by verse | Pending |
| `tafsir` | Tafsir/exegesis | Pending |
| `audio` | Recitation timing data | Pending |
| `word_meanings` | Word-by-word translation | Pending |

---

## Flutter Integration Notes

### Required Setup
```dart
// For desktop support
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
```

### Font Configuration
```yaml
fonts:
  - family: UthmanicHafs
    fonts:
      - asset: assets/fonts/UthmanicHafs_V22.ttf
```

### Key Implementation Details
- Use `letter_breakdown` table for letter-by-letter rendering
- Apply ZWJ (Zero Width Joiner) for proper Arabic shaping
- Cache pages in memory (LRU strategy)
- Line-scoped rebuilds for performance

---

## VSCode Extensions for SQLite

| Extension | ID | Purpose |
|-----------|-----|---------|
| SQLite Viewer | `qwtel.sqlite-viewer` | View tables, run queries |
| SQLite | `alexcvzz.vscode-sqlite` | SQL intellisense, export |

---

## Schema Version

**Version:** 1.0  
**Last Updated:** 2026-03-16  
**Next Review:** After Flutter rewrite completion

