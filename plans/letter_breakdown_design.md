# Letter-by-Letter Breakdown Table Design

## Overview
This document outlines the design for a SQLite table that stores individual Arabic letters with their corresponding diacritics (tashkeel) for Quranic text analysis. The table enables character-level segmentation and linguistic metadata mapping for each word in the Quran.

## Data Models

### 1. Database Schema: `letter_breakdown` Table

```sql
CREATE TABLE letter_breakdown (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    word_id INTEGER NOT NULL,           -- Reference to mushaf_pages.word_id
    verse_key TEXT NOT NULL,             -- Format "surah:ayah" (e.g., "1:1")
    word_position INTEGER NOT NULL,      -- Position of word in the verse (1-based)
    
    -- Letter-level data
    letter_index INTEGER NOT NULL,       -- Index of letter within word (0-based)
    letter_position INTEGER NOT NULL,    -- Display position (RTL order)
    
    -- Character data
    base_letter TEXT NOT NULL,           -- The base Arabic letter (without diacritics)
    letter_with_diacritics TEXT,         -- Base letter + directly attached diacritics
    
    -- Unicode information
    base_letter_codepoint INTEGER,       -- Unicode codepoint of base letter
    base_letter_category TEXT,           -- Unicode category (e.g., "Lo")
    base_letter_name TEXT,               -- Unicode name of base letter
    
    -- Diacritic information (JSON array for multiple diacritics)
    diacritics_json TEXT,                -- JSON array of diacritic objects
    -- Example: [{"char": "\u064e", "codepoint": 1614, "name": "ARABIC FATHA", "type": "haraka"}]
    
    -- Diacritic types (derived flags for quick querying)
    has_fatha BOOLEAN,                   -- U+064E
    has_kasra BOOLEAN,                   -- U+0650
    has_damma BOOLEAN,                   -- U+064F
    has_sukun BOOLEAN,                   -- U+0652
    has_shadda BOOLEAN,                  -- U+0651
    has_tanwin_fath BOOLEAN,             -- U+064B (double fatha)
    has_tanwin_kasr BOOLEAN,             -- U+064D (double kasra)
    has_tanwin_damm BOOLEAN,             -- U+064C (double damma)
    has_maddah BOOLEAN,                  -- U+0653
    has_hamza_above BOOLEAN,             -- U+0654
    has_hamza_below BOOLEAN,             -- U+0655
    has_superscript_alef BOOLEAN,        -- U+0670 (dagger alef in Uthmani)
    has_subscript_alef BOOLEAN,          -- U+0656
    has_small_high_alef BOOLEAN,         -- U+06D6, U+06D7 (small high alef)
    has_small_high_meem BOOLEAN,         -- U+06E2
    has_small_high_jeem BOOLEAN,         -- U+06DA
    has_small_high_three_dots BOOLEAN,   -- U+06DB
    has_small_high_seen BOOLEAN,         -- U+06DC
    has_small_high_rounded_zero BOOLEAN, -- U+06DF
    has_small_high upright rectangular zero BOOLEAN, -- U+06E0
    has_small_high_dotless_head BOOLEAN, -- U+06E1
    has_small_low_meem BOOLEAN,          -- U+06ED
    
    -- Linguistic metadata
    letter_type TEXT,                    -- 'consonant', 'vowel_carrier', 'long_vowel'
    is_hamza_variant BOOLEAN,            -- Special handling for hamza variants
    
    -- Source tracking
    source_db TEXT,                      -- Which source DB this came from
    
    -- Indexes for efficient queries
    FOREIGN KEY (word_id) REFERENCES mushaf_pages(word_id),
    UNIQUE(word_id, letter_index)
);

-- Indexes for common query patterns
CREATE INDEX idx_letter_breakdown_word ON letter_breakdown(word_id);
CREATE INDEX idx_letter_breakdown_verse ON letter_breakdown(verse_key);
CREATE INDEX idx_letter_breakdown_base_letter ON letter_breakdown(base_letter);
CREATE INDEX idx_letter_breakdown_has_shadda ON letter_breakdown(has_shadda);
CREATE INDEX idx_letter_breakdown_has_fatha ON letter_breakdown(has_fatha);
CREATE INDEX idx_letter_breakdown_has_kasra ON letter_breakdown(has_kasra);
CREATE INDEX idx_letter_breakdown_has_damma ON letter_breakdown(has_damma);
```

### 2. Diacritic Types Reference

The table captures the following diacritic categories:

#### Basic Harakat (Short Vowels)
| Unicode | Character | Name | Type |
|---------|-----------|------|------|
| U+064E | َ | ARABIC FATHA | haraka |
| U+0650 | ِ | ARABIC KASRA | haraka |
| U+064F | ُ | ARABIC DAMMA | haraka |
| U+0652 | ْ | ARABIC SUKUN | sukun |

#### Tanween (Nunation)
| Unicode | Character | Name | Type |
|---------|-----------|------|------|
| U+064B | ً | ARABIC FATHATAN | tanwin |
| U+064D | ٍ | ARABIC KASRATAN | tanwin |
| U+064C | ٌ | ARABIC DAMMATAN | tanwin |

#### Shadda (Gemination)
| Unicode | Character | Name | Type |
|---------|-----------|------|------|
| U+0651 | ّ | ARABIC SHADDA | shadda |

#### Quranic Special Marks
| Unicode | Character | Name | Type |
|---------|-----------|------|------|
| U+0653 | ٓ | ARABIC MADDAH ABOVE | maddah |
| U+0654 | أ | ARABIC HAMZA ABOVE | hamza |
| U+0655 | ٔ | ARABIC HAMZA BELOW | hamza |
| U+0670 | ٰ | ARABIC LETTER SUPERSCRIPT ALEF | special |
| U+0656 | ٖ | ARABIC SUBSCRIPT ALEF | special |

#### Small High Marks (Uthmani Script)
| Unicode | Character | Name | Type |
|---------|-----------|------|------|
| U+06D6 | ۖ | ARABIC SMALL HIGH LIGATURE SAD WITH LAM WITH ALEF MAKSURA | stop_mark |
| U+06D7 | ۗ | ARABIC SMALL HIGH LIGATURE QAF WITH LAM WITH ALEF MAKSURA | stop_mark |
| U+06D8 | ۘ | ARABIC SMALL HIGH MEEM INITIAL FORM | stop_mark |
| U+06D9 | ۙ | ARABIC SMALL HIGH LAM ALEF | stop_mark |
| U+06DA | ۚ | ARABIC SMALL HIGH JEEM | stop_mark |
| U+06DB | ۛ | ARABIC SMALL HIGH THREE DOTS | stop_mark |
| U+06DC | ۜ | ARABIC SMALL HIGH SEEN | stop_mark |
| U+06DF | ۟ | ARABIC SMALL HIGH ROUNDED ZERO | stop_mark |
| U+06E0 | ۠ | ARABIC SMALL HIGH UPRIGHT RECTANGULAR ZERO | stop_mark |
| U+06E1 | ۡ | ARABIC SMALL HIGH DOTLESS HEAD OF KHAH | stop_mark |
| U+06E2 | ۢ | ARABIC SMALL HIGH MEEM ISOLATED FORM | stop_mark |
| U+06E4 | ۤ | ARABIC SMALL HIGH MADDAH | stop_mark |
| U+06ED | ۭ | ARABIC SMALL LOW MEEM | stop_mark |

### 3. Dart Model: `QuranLetter`

```dart
/// Represents a single letter with its diacritics from a Quranic word
class QuranLetter {
  final int id;
  final int wordId;
  final String verseKey;
  final int wordPosition;
  final int letterIndex;
  final int letterPosition;
  
  // Character data
  final String baseLetter;
  final String? letterWithDiacritics;
  
  // Unicode info
  final int baseLetterCodepoint;
  final String baseLetterCategory;
  final String baseLetterName;
  
  // Diacritics
  final List<DiacriticData> diacritics;
  
  // Boolean flags for quick checking
  final bool hasFatha;
  final bool hasKasra;
  final bool hasDamma;
  final bool hasSukun;
  final bool hasShadda;
  final bool hasTanwinFath;
  final bool hasTanwinKasr;
  final bool hasTanwinDamm;
  final bool hasMaddah;
  final bool hasHamzaAbove;
  final bool hasHamzaBelow;
  final bool hasSuperscriptAlef;
  final bool hasSubscriptAlef;
  
  // Linguistic metadata
  final LetterType letterType;
  final bool isHamzaVariant;

  const QuranLetter({
    required this.id,
    required this.wordId,
    required this.verseKey,
    required this.wordPosition,
    required this.letterIndex,
    required this.letterPosition,
    required this.baseLetter,
    this.letterWithDiacritics,
    required this.baseLetterCodepoint,
    required this.baseLetterCategory,
    required this.baseLetterName,
    required this.diacritics,
    this.hasFatha = false,
    this.hasKasra = false,
    this.hasDamma = false,
    this.hasSukun = false,
    this.hasShadda = false,
    this.hasTanwinFath = false,
    this.hasTanwinKasr = false,
    this.hasTanwinDamm = false,
    this.hasMaddah = false,
    this.hasHamzaAbove = false,
    this.hasHamzaBelow = false,
    this.hasSuperscriptAlef = false,
    this.hasSubscriptAlef = false,
    this.letterType = LetterType.consonant,
    this.isHamzaVariant = false,
  });

  /// Factory from database map
  factory QuranLetter.fromDb(Map<String, dynamic> map) {
    return QuranLetter(
      id: map['id'] as int,
      wordId: map['word_id'] as int,
      verseKey: map['verse_key'] as String,
      wordPosition: map['word_position'] as int,
      letterIndex: map['letter_index'] as int,
      letterPosition: map['letter_position'] as int,
      baseLetter: map['base_letter'] as String,
      letterWithDiacritics: map['letter_with_diacritics'] as String?,
      baseLetterCodepoint: map['base_letter_codepoint'] as int,
      baseLetterCategory: map['base_letter_category'] as String,
      baseLetterName: map['base_letter_name'] as String,
      diacritics: _parseDiacritics(map['diacritics_json'] as String?),
      hasFatha: (map['has_fatha'] as int?) == 1,
      hasKasra: (map['has_kasra'] as int?) == 1,
      hasDamma: (map['has_damma'] as int?) == 1,
      hasSukun: (map['has_sukun'] as int?) == 1,
      hasShadda: (map['has_shadda'] as int?) == 1,
      hasTanwinFath: (map['has_tanwin_fath'] as int?) == 1,
      hasTanwinKasr: (map['has_tanwin_kasr'] as int?) == 1,
      hasTanwinDamm: (map['has_tanwin_damm'] as int?) == 1,
      hasMaddah: (map['has_maddah'] as int?) == 1,
      hasHamzaAbove: (map['has_hamza_above'] as int?) == 1,
      hasHamzaBelow: (map['has_hamza_below'] as int?) == 1,
      hasSuperscriptAlef: (map['has_superscript_alef'] as int?) == 1,
      hasSubscriptAlef: (map['has_subscript_alef'] as int?) == 1,
      letterType: LetterType.values[map['letter_type_index'] as int? ?? 0],
      isHamzaVariant: (map['is_hamza_variant'] as int?) == 1,
    );
  }

  static List<DiacriticData> _parseDiacritics(String? json) {
    if (json == null) return [];
    // Parse JSON and return list
    return [];
  }

  /// Get the full phonetic representation
  String get phonetic => letterWithDiacritics ?? baseLetter;
  
  /// Check if letter has any diacritics
  bool get hasDiacritics => diacritics.isNotEmpty;
  
  /// Check if letter has any haraka (fatha, kasra, damma)
  bool get hasHaraka => hasFatha || hasKasra || hasDamma;
  
  /// Check if letter has tanwin
  bool get hasTanwin => hasTanwinFath || hasTanwinKasr || hasTanwinDamm;
}

enum LetterType {
  consonant,
  vowelCarrier,
  longVowel,
}

class DiacriticData {
  final String char;
  final int codepoint;
  final String name;
  final String type;

  const DiacriticData({
    required this.char,
    required this.codepoint,
    required this.name,
    required this.type,
  });
}
```

## Implementation Approach

### TextSpan-based Letter Segmentation

The segmentation algorithm uses Unicode categories to separate:
1. **Base letters** (category `Lo` - Letter, other)
2. **Diacritics** (category `Mn` - Mark, nonspacing)

For each word:
1. Iterate through characters in display order (RTL)
2. When encountering a base letter, start a new letter entry
3. When encountering a diacritic, attach it to the current base letter
4. Store diacritics in JSON array format for flexibility

### Example Segmentation

**Input word:** `بِسۡمِ` (bismi)

| letter_index | base_letter | diacritics_json | letter_with_diacritics |
|--------------|-------------|-----------------|------------------------|
| 0 | ب | [{"char":"ِ","codepoint":1616,"name":"KASRA"}] | بِ |
| 1 | س | [{"char":"ۡ","codepoint":1761,"name":"SMALL HIGH DOTLESS HEAD"}] | سۡ |
| 2 | م | [{"char":"ِ","codepoint":1616,"name":"KASRA"}] | مِ |

### Query Examples

```sql
-- Get all letters of a specific word
SELECT * FROM letter_breakdown 
WHERE word_id = 123 
ORDER BY letter_index;

-- Find all words containing shadda
SELECT DISTINCT word_id FROM letter_breakdown 
WHERE has_shadda = 1;

-- Find all words with tanwin fatha
SELECT DISTINCT word_id FROM letter_breakdown 
WHERE has_tanwin_fath = 1;

-- Count frequency of letters with specific diacritics
SELECT base_letter, COUNT(*) as count 
FROM letter_breakdown 
WHERE has_shadda = 1 AND has_fatha = 1
GROUP BY base_letter;
```

## Integration with QUL Resources

The QUL (Quranic Universal Library) from Tarteel provides:
- Standardized Quranic text resources
- Word-by-word alignment data
- Morphological annotations

This table design aligns with QUL standards by:
1. Using `verse_key` format (surah:ayah) consistent with QUL APIs
2. Supporting Uthmani script characters fully
3. Preserving all diacritical marks for accurate recitation

## External Resources

### PyArabic Library
For Python-based text processing, PyArabic provides utilities for:
- `strip_diacritics()` - Remove tashkeel
- `separate_diacritics()` - Separate letters from diacritics
- Letter classification and normalization

Installation: `pip install pyarabic`

### Unicode Standard
- Arabic block: U+0600 - U+06FF
- Arabic Supplement: U+0750 - U+077F
- Arabic Extended-A: U+08A0 - U+08FF

## Performance Considerations

1. **Indexing**: Multiple indexes for common query patterns
2. **JSON Storage**: Diacritics stored as JSON for flexibility
3. **Boolean Flags**: Quick filtering without JSON parsing
4. **Estimated Size**: ~7 million rows (77,430 words × ~5-10 letters average)
