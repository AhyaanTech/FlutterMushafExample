# Quran Offline Database Schema

**Source of Truth:** `word_id` - All tables reference this global unique identifier from QPC (Quran Programming Community) databases.

**Current Version:** Generated from:
- `qpc-hafs-word-by-word.db` - Arabic text (Uthmani script)
- `qudratullah-indopak-15-lines.db` - 15-line Mushaf layout

---

## Table Overview

| Table | Purpose | Row Count |
|-------|---------|-----------|
| `words` | Core word data with Arabic text | ~83,668 |
| `ayahs` | Verse-level metadata (juz, hizb, sajda, etc.) | ~6,236 |
| `surahs` | Surah metadata (names, revelation, verse count) | 114 |
| `mushaf_pages` | 15-line IndoPak layout coordinates | ~83,668 |
| `letter_breakdown` | Character-level analysis with diacritics | ~341,062 |
| `metadata` | Build info and source tracking | variable |

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

Per-verse metadata including structural divisions (juz, hizb, etc.)

```sql
CREATE TABLE ayahs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    verse_key TEXT NOT NULL UNIQUE,   -- Format: "surah:ayah"
    surah INTEGER NOT NULL,           -- 1-114
    ayah INTEGER NOT NULL,            -- 1-286
    text TEXT,                        -- Complete verse text (optional)
    juz INTEGER,                      -- 1-30
    hizb INTEGER,                     -- 1-60
    rub INTEGER,                      -- 1-240 (rub' al-hizb)
    manzil INTEGER,                   -- 1-7
    ruku INTEGER,                     -- Ruku number
    sajda_type TEXT,                  -- 'recommended', 'obligatory', or NULL
    sajda_id INTEGER,                 -- Reference to sajda entry
    page INTEGER,                     -- Page in 15-line Mushaf
    first_word_id INTEGER,            -- First word in verse
    last_word_id INTEGER,             -- Last word in verse
    word_count INTEGER                -- Number of words
);

-- Indexes
CREATE INDEX idx_ayahs_surah ON ayahs(surah);
CREATE INDEX idx_ayahs_juz ON ayahs(juz);
CREATE INDEX idx_ayahs_page ON ayahs(page);
```

---

### 3. `surahs` - Surah Metadata

Information about each of the 114 chapters.

```sql
CREATE TABLE surahs (
    id INTEGER PRIMARY KEY,           -- 1-114
    name_ar TEXT NOT NULL,            -- Arabic name (e.g., "الفاتحة")
    name_en TEXT,                     -- English transliteration
    name_translation TEXT,            -- English meaning
    revelation_type TEXT,             -- 'meccan' or 'medinan'
    verses_count INTEGER NOT NULL,    -- Number of ayahs
    first_ayah_id INTEGER,            -- First verse in surah
    last_ayah_id INTEGER,             -- Last verse in surah
    first_word_id INTEGER,            -- First word in surah
    last_word_id INTEGER,             -- Last word in surah
    bismillah_pre TEXT                -- Bismillah text if different
);

-- Indexes
CREATE INDEX idx_surahs_revelation ON surahs(revelation_type);
```

---

### 4. `mushaf_pages` - Layout Coordinates

15-line IndoPak Mushaf layout. Each row is one word on a specific page/line.

```sql
CREATE TABLE mushaf_pages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    page_number INTEGER NOT NULL,     -- 1-610 (15-line Mushaf)
    line_number INTEGER NOT NULL,     -- 1-15 per page
    word_id INTEGER NOT NULL,         -- FK to words.id
    verse_key TEXT NOT NULL,          -- Denormalized: "surah:ayah"
    line_type TEXT,                   -- 'ayah' | 'basmallah' | 'surah_name'
    is_centered INTEGER DEFAULT 0,    -- 1 for headers/basmallah
    
    FOREIGN KEY (word_id) REFERENCES words(id)
);

-- Indexes
CREATE INDEX idx_mushaf_pages_page ON mushaf_pages(page_number);
CREATE INDEX idx_mushaf_pages_page_line ON mushaf_pages(page_number, line_number);
CREATE INDEX idx_mushaf_pages_word ON mushaf_pages(word_id);
CREATE INDEX idx_mushaf_pages_verse ON mushaf_pages(verse_key);
```

**Notes:**
- `word_id` is the join key to get actual Arabic text from `words` table
- `line_type` helps with rendering (center surah names/basmallah)

---

### 5. `letter_breakdown` - Character Analysis

Granular letter-level data with diacritics for Tajweed study.

```sql
CREATE TABLE letter_breakdown (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    word_id INTEGER NOT NULL,         -- FK to words.id
    verse_key TEXT NOT NULL,          -- Denormalized
    word_position INTEGER NOT NULL,   -- Position within verse
    letter_index INTEGER NOT NULL,    -- Position within word (RTL, 0-based)
    letter_position INTEGER NOT NULL, -- Same as letter_index
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
    has_small_high_alef INTEGER DEFAULT 0,
    has_small_high_meem INTEGER DEFAULT 0,
    has_small_high_jeem INTEGER DEFAULT 0,
    has_small_high_three_dots INTEGER DEFAULT 0,
    has_small_high_seen INTEGER DEFAULT 0,
    has_small_high_rounded_zero INTEGER DEFAULT 0,
    has_small_high_upright_zero INTEGER DEFAULT 0,
    has_small_high_dotless_head INTEGER DEFAULT 0,
    has_small_low_meem INTEGER DEFAULT 0,
    
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
CREATE INDEX idx_letter_word_letter ON letter_breakdown(word_id, letter_index);
```

**Statistics:**
- ~341,062 letters across 83,668 words
- Average: 4.1 letters per word

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
- `total_pages` - 610
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
SELECT mp.*, w.text 
FROM mushaf_pages mp
JOIN words w ON w.id = mp.word_id
WHERE mp.page_number = 1
ORDER BY mp.line_number, mp.id;
```

### Get letters of a word (for Tajweed coloring)
```sql
SELECT * FROM letter_breakdown 
WHERE word_id = 123 
ORDER BY letter_index;
```

### Find all words with shadda
```sql
SELECT DISTINCT lb.word_id, w.text
FROM letter_breakdown lb
JOIN words w ON w.id = lb.word_id
WHERE lb.has_shadda = 1;
```

### Get verse metadata
```sql
SELECT a.*, s.name_ar 
FROM ayahs a
JOIN surahs s ON s.id = a.surah
WHERE a.verse_key = '2:255';
```

---

## Future Tables (Pending Data Sources)

| Table | Purpose | Status |
|-------|---------|--------|
| `translations` | Translations by verse | Pending |
| `tafsir` | Tafsir/exegesis | Pending |
| `audio` | Recitation timing data | Pending |
| `word_meanings` | Word-by-word translation | Pending |
| `sajdas` | Sajda (prostration) details | Pending |
| `juzs` | Juz division metadata | Pending |

---

## VSCode Extensions for SQLite

Recommended extensions for working with this database:

| Extension | ID | Purpose |
|-----------|-----|---------|
| SQLite Viewer | `qwtel.sqlite-viewer` | View tables, run queries |
| SQLite | `alexcvzz.vscode-sqlite` | SQL intellisense, export |

---

## Schema Version

**Version:** 1.0  
**Last Updated:** 2026-03-13  
**Next Review:** When adding translations/audio data
