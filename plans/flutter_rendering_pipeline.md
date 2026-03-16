# Flutter Quran App - Master Architecture Pipeline

**Status:** Architecture v3 - Line-by-Line Dual Mode | **Priority:** High

## Critical Fix: Script Consistency

**The database sources MUST use the same script tradition.**

| Database | Script | Issue |
|----------|--------|-------|
| `qpc-hafs-word-by-word.db` | **Uthmani (Hafs)** | Source words |
| `qudratullah-indopak-15-lines.db` | **IndoPak** | ❌ WRONG - Different page breaks |
| `digital-khatt-15-lines.db` | **Uthmani (Hafs)** | ✅ CORRECT - Matches words |

**Using IndoPak layout with Hafs words will break page boundaries** (ayahs split mid-page).

---

## 1. Database Architecture & Download List

### 1.1 Validated Download List (QUL Sources)

| File | QUL Source | Purpose | Script |
|------|------------|---------|--------|
| `qpc-hafs-word-by-word.db` | KFGQPC Hafs script | Source words | Uthmani |
| `qpc-hafs-tajweed-word.db` | QPC Hafs Script - With Tajweed | Official Tajweed colors | Uthmani |
| `digital-khatt-15-lines.db` | **Digital Khatt (KFGQPC V2)** | Line & Page coordinates | Uthmani |

### 1.2 Table Schema: `mushaf_pages` (Layout Blueprint)

**Source:** `digital-khatt-15-lines.db`

| Column | Type | Notes |
|--------|------|-------|
| `page_number` | INTEGER | 1-604 (Hafs 15-line Mushaf) |
| `line_number` | INTEGER | 1-15 per page |
| `first_word_id` | INTEGER | Start of line boundary |
| `last_word_id` | INTEGER | End of line boundary |
| `line_type` | TEXT | 'ayah', 'surah_name', 'basmallah' |
| `is_centered` | BOOLEAN | 1 for headers/basmallah |

**Query pattern:** "For Page 1, Line 1, give me `first_word_id` to `last_word_id`."

### 1.3 Table Schema: `words` (Source Words)

**Source:** `qpc-hafs-word-by-word.db`

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER | Global word_id (1-83668) |
| `text` | TEXT | Uthmani script Arabic |
| `verse_key` | TEXT | Format "surah:ayah" |

### 1.4 Table Schema: `words_tajweed` (Tajweed Colors)

**Source:** `qpc-hafs-tajweed-word.db`

| Column | Type | Notes |
|--------|------|-------|
| `word_id` | INTEGER | FK to words.id |
| `text` | TEXT | Uthmani script (verification) |
| `tajweed_color` | TEXT | Hex color (e.g., '#FF0000') |
| `tajweed_rule` | TEXT | Rule name: 'idgham', 'ikhfa', etc. |

### 1.5 Table Schema: `letter_breakdown` (Custom Mode Engine)

**Built from:** `words` table via `scripts/build_letters.py`

**Estimated size:** ~387,000 rows (77,430 words × ~5 letters/word)

```sql
CREATE TABLE letter_breakdown (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    word_id INTEGER NOT NULL,
    verse_key TEXT NOT NULL,
    word_position INTEGER NOT NULL,    -- Position within verse
    letter_index INTEGER NOT NULL,     -- Position within word (0-based, RTL)
    letter_position INTEGER NOT NULL,  -- Same as letter_index
    
    -- Letter content
    base_letter TEXT NOT NULL,         -- Base Arabic letter without diacritics
    letter_with_diacritics TEXT,       -- Full letter + tashkeel (HARAKAT ATTACHED)
    
    -- Unicode metadata
    base_letter_codepoint INTEGER,
    base_letter_category TEXT,
    base_letter_name TEXT,
    diacritics_json TEXT,              -- JSON array of diacritic objects
    
    -- Diacritic flags (for computing fallback Tajweed colors)
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
    -- ... (other small high/low marks)
    
    -- Letter classification
    letter_type TEXT,                  -- 'consonant', 'vowelCarrier', 'longVowel'
    is_hamza_variant INTEGER DEFAULT 0,
    source_db TEXT,
    
    FOREIGN KEY (word_id) REFERENCES words(id),
    UNIQUE(word_id, letter_index)
);

-- Indexes for performance
CREATE INDEX idx_letter_word ON letter_breakdown(word_id);
CREATE INDEX idx_letter_verse ON letter_breakdown(verse_key);
CREATE INDEX idx_letter_base ON letter_breakdown(base_letter);
CREATE INDEX idx_letter_shadda ON letter_breakdown(has_shadda);
```

---

## 2. Dual Rendering Modes

### 2.1 Mode Switching

```dart
enum RenderMode {
  tajweed,  // Official colors from words_tajweed
  custom,   // Letter-by-letter with user colors
}

// Dropdown in app bar
DropdownButton<RenderMode>(
  value: renderMode,
  onChanged: (mode) => setState(() => renderMode = mode),
  items: [
    DropdownMenuItem(value: RenderMode.tajweed, child: Text('Tajweed')),
    DropdownMenuItem(value: RenderMode.custom, child: Text('Custom')),
  ],
)
```

### 2.2 The Line-by-Line Rendering Strategy

**Critical for performance:** Use `ListView.builder` with exact lines from `mushaf_pages`.

```dart
// Page widget - renders exactly 15 lines
ListView.builder(
  itemCount: 15,
  itemBuilder: (context, lineIndex) {
    return MushafLineWidget(
      pageNumber: currentPage,
      lineNumber: lineIndex + 1,
      mode: currentMode,
    );
  },
)
```

**Why this works:**
- No text wrapping calculations needed
- Exact control over 15-line layout
- `TextAlign.justify` stretches words to fill line width
- Scoped rebuilds (only affected line updates)

---

## 3. Data Flow & Rendering

### 3.1 Macro-to-Micro Query Pipeline

```
MushafLineWidget (Page X, Line Y)
    ↓
Query mushaf_pages: "Get first_word_id, last_word_id for this line"
    ↓
Query words by ID range (all modes)
    ↓
IF Tajweed Mode:
    Query words_tajweed for colors
    Render word-level TextSpans
    
IF Custom Mode:
    Query letter_breakdown for each word
    Group letters by word
    Inject ZWJ + build letter-level TextSpans
```

### 3.2 Tajweed Mode (Word-Level)

```dart
TextSpan buildTajweedWord(WordTajweed word) {
  return TextSpan(
    text: word.text + ' ',  // Word + trailing space
    style: TextStyle(
      color: parseColor(word.tajweedColor),
      fontFamily: 'KFGQPC',
      fontSize: 24,
    ),
  );
}
```

### 3.3 Custom Mode (Letter-Level with ZWJ)

#### ZWJ Injection Algorithm

```dart
String injectZWJ(List<QuranLetter> letters, int index) {
  final letter = letters[index];
  final isFirst = index == 0;
  final isLast = index == letters.length - 1;
  
  final connectsToNext = !isLast && isConnectingLetter(letter.baseLetter);
  final connectsToPrev = !isFirst && isConnectingLetter(letters[index - 1].baseLetter);
  
  if (connectsToPrev && connectsToNext) {
    // Medial: joins on both sides
    return '\u200D${letter.letterWithDiacritics}\u200D';
  } else if (connectsToNext) {
    // Initial: joins to next letter
    return '${letter.letterWithDiacritics}\u200D';
  } else if (connectsToPrev) {
    // Final: joins to previous letter
    return '\u200D${letter.letterWithDiacritics}';
  } else {
    // Isolated: no connection
    return letter.letterWithDiacritics;
  }
}

bool isConnectingLetter(String letter) {
  // These letters don't connect to the next letter
  const nonConnecting = ['ا', 'د', 'ذ', 'ر', 'ز', 'و'];
  return !nonConnecting.contains(letter);
}
```

#### Ligature Handling

Mandatory ligatures must be single `TextSpan` units:

```dart
// Detect Lam-Alif sequence
bool isLamAlif(String current, String next) {
  return current == 'ل' && ['ا', 'أ', 'إ', 'آ'].contains(next);
}

// Merge into single span
if (isLamAlif(letters[i].baseLetter, letters[i+1].baseLetter)) {
  return TextSpan(text: 'لا'); // Font handles ligature
}
```

#### Word Spacing

**Critical:** Add space after each word for `TextAlign.justify`:

```dart
List<TextSpan> buildLine(List<Word> words) {
  final spans = <TextSpan>[];
  
  for (final word in words) {
    // Add word spans (letters or whole word)
    spans.addAll(buildWordSpans(word));
    
    // Add space between words (REQUIRED for justify)
    spans.add(TextSpan(text: ' '));
  }
  
  return spans;
}

// Final render
RichText(
  textAlign: TextAlign.justify,  // Stretches to fill line width
  text: TextSpan(children: spans),
)
```

---

## 4. Performance & State Management

### 4.1 Line-Scoped Rebuilds

When user taps a letter in Custom Mode:

1. `TapGestureRecognizer` fires on specific letter
2. Update color in state management
3. Call `setState()` ONLY on the containing `MushafLineWidget`
4. Other 14 lines remain untouched → 60 FPS maintained

```dart
class LineController extends ChangeNotifier {
  Map<int, Color?> letterColors; // wordId -> color list
  
  void setLetterColor(int wordId, int letterIndex, Color color) {
    letterColors[wordId]?[letterIndex] = color;
    notifyListeners(); // Only this line rebuilds
  }
}
```

### 4.2 Caching Strategy

```dart
class RenderCache {
  // Cache key: "page_line_mode" 
  final Map<String, List<TextSpan>> _lineCache = {};
  
  String _cacheKey(int page, int line, RenderMode mode) {
    return '${page}_${line}_${mode.name}';
  }
  
  List<TextSpan>? getLine(int page, int line, RenderMode mode) {
    return _lineCache[_cacheKey(page, line, mode)];
  }
  
  void setLine(int page, int line, RenderMode mode, List<TextSpan> spans) {
    _lineCache[_cacheKey(page, line, mode)] = spans;
  }
  
  // Invalidate only affected line when color changes
  void invalidateLine(int page, int line) {
    _lineCache.remove('${page}_${line}_${RenderMode.custom.name}');
  }
}
```

### 4.3 Async Processing

Build spans in Isolate for heavy operations:

```dart
Future<List<TextSpan>> buildLineAsync(int page, int line, RenderMode mode) {
  return compute(_buildLineIsolate, {
    'page': page,
    'line': line,
    'mode': mode.index,
  });
}
```

---

## 5. Implementation Phases

### Phase 1: Database & Layout Engine
- [ ] Download `digital-khatt-15-lines.db` (KFGQPC V2 15-line layout)
- [ ] Verify word_id ranges match `qpc-hafs-word-by-word.db`
- [ ] Implement `mushaf_pages` macro-query logic
- [ ] Render raw text line-by-line using `TextAlign.justify`

### Phase 2: Tajweed Mode
- [ ] Download `qpc-hafs-tajweed-word.db`
- [ ] Build `words_tajweed` table in pipeline
- [ ] Map to word-level `TextSpan`s
- [ ] Verify visual accuracy against standard Mushaf

### Phase 3: Custom Mode
- [ ] Build `letter_breakdown` table (~387k rows)
- [ ] Implement ZWJ injection in Dart
- [ ] Implement ligature detection
- [ ] Attach `TapGestureRecognizer` to letter spans
- [ ] Implement line-scoped state management

### Phase 4: Polish
- [ ] Color picker dialog
- [ ] Local storage (Hive/SQLite) for user colors
- [ ] Pre-cache adjacent pages in background
- [ ] Export/share colored pages

---

## 6. Common Pitfalls

| Issue | Cause | Solution |
|-------|-------|----------|
| Page breaks mid-ayah | Using IndoPak layout with Hafs words | Use `digital-khatt-15-lines.db` |
| Broken Arabic shaping | Missing ZWJ injection | Always use ZWJ algorithm |
| Ligatures split | `ل` and `ا` in separate spans | Detect and merge Lam-Alif |
| Lines not justified | Missing space between words | Add `TextSpan(text: ' ')` |
| 15 FPS on tap | Rebuilding entire page | Line-scoped rebuilds only |

---

## 7. Row Count Verification

| Table | Source | Estimated Rows |
|-------|--------|----------------|
| `words` | QPC | ~83,668 |
| `words_tajweed` | QPC | ~83,668 |
| `letter_breakdown` | Computed | ~387,000 (83k × ~4.6) |
| `mushaf_pages` | QPC 15-line | ~83,668 |

**Total database size:** ~15-20 MB

---

**Last Updated:** 2026-03-13 (v3 - Script Consistency Fix)  
**Next Review:** After Phase 1 layout verification
