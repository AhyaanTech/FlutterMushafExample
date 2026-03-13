/// Data models for letter-by-letter Quranic text analysis
///
/// These models support character-level segmentation with diacritical markers
/// for precise Quranic text analysis, Tajweed study, and recitation.
library quran_letter_models;

import 'dart:convert';

/// Enum representing the type of Arabic letter
enum LetterType {
  /// Regular consonant letters
  consonant,

  /// Letters that primarily carry vowel sounds (like alif)
  vowelCarrier,

  /// Letters that extend vowel sounds (waw, yeh, alif maddah)
  longVowel,
}

/// Extension for LetterType display names
extension LetterTypeExtension on LetterType {
  String get displayName {
    switch (this) {
      case LetterType.consonant:
        return 'Consonant';
      case LetterType.vowelCarrier:
        return 'Vowel Carrier';
      case LetterType.longVowel:
        return 'Long Vowel';
    }
  }

  int get indexValue {
    switch (this) {
      case LetterType.consonant:
        return 0;
      case LetterType.vowelCarrier:
        return 1;
      case LetterType.longVowel:
        return 2;
    }
  }

  static LetterType fromIndex(int index) {
    switch (index) {
      case 0:
        return LetterType.consonant;
      case 1:
        return LetterType.vowelCarrier;
      case 2:
        return LetterType.longVowel;
      default:
        return LetterType.consonant;
    }
  }
}

/// Represents information about a single diacritic mark
class DiacriticData {
  /// The diacritic character
  final String char;

  /// Unicode codepoint
  final int codepoint;

  /// Unicode name of the diacritic
  final String name;

  /// Diacritic type: haraka, tanwin, shadda, sukun, maddah, hamza, special, stop_mark
  final String type;

  /// Unicode category (Mn = Mark, nonspacing)
  final String? category;

  const DiacriticData({
    required this.char,
    required this.codepoint,
    required this.name,
    required this.type,
    this.category,
  });

  /// Factory constructor from JSON map
  factory DiacriticData.fromJson(Map<String, dynamic> json) {
    return DiacriticData(
      char: json['char'] as String,
      codepoint: json['codepoint'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      category: json['category'] as String?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'char': char,
      'codepoint': codepoint,
      'name': name,
      'type': type,
      if (category != null) 'category': category,
    };
  }

  /// Check if this is a haraka (short vowel)
  bool get isHaraka => type == 'haraka';

  /// Check if this is tanwin (nunation)
  bool get isTanwin => type == 'tanwin';

  /// Check if this is shadda
  bool get isShadda => type == 'shadda';

  /// Check if this is sukun
  bool get isSukun => type == 'sukun';

  /// Get the diacritic type display name
  String get typeDisplayName {
    switch (type) {
      case 'haraka':
        return 'Haraka';
      case 'tanwin':
        return 'Tanwin';
      case 'shadda':
        return 'Shadda';
      case 'sukun':
        return 'Sukun';
      case 'maddah':
        return 'Maddah';
      case 'hamza':
        return 'Hamza';
      case 'special':
        return 'Special';
      case 'stop_mark':
        return 'Stop Mark';
      default:
        return type;
    }
  }

  @override
  String toString() => 'DiacriticData($char - $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiacriticData &&
        other.char == char &&
        other.codepoint == codepoint;
  }

  @override
  int get hashCode => Object.hash(char, codepoint);
}

/// Represents a single letter with its diacritics from a Quranic word
///
/// This model provides complete information about a letter's Unicode properties,
/// attached diacritics, and linguistic metadata for text analysis.
class QuranLetter {
  /// Database ID
  final int id;

  /// Reference to the parent word ID
  final int wordId;

  /// Verse key in format "surah:ayah" (e.g., "1:1")
  final String verseKey;

  /// Position of word within the verse (1-based)
  final int wordPosition;

  /// Index of letter within the word (0-based, RTL order)
  final int letterIndex;

  /// Display position (same as letterIndex for RTL)
  final int letterPosition;

  /// The base Arabic letter without diacritics
  final String baseLetter;

  /// Base letter with directly attached diacritics
  final String? letterWithDiacritics;

  /// Unicode codepoint of base letter
  final int baseLetterCodepoint;

  /// Unicode category (e.g., "Lo" for Letter, other)
  final String baseLetterCategory;

  /// Unicode name of base letter
  final String baseLetterName;

  /// List of attached diacritics
  final List<DiacriticData> diacritics;

  // Boolean flags for quick querying

  /// Has fatha (U+064E)
  final bool hasFatha;

  /// Has kasra (U+0650)
  final bool hasKasra;

  /// Has damma (U+064F)
  final bool hasDamma;

  /// Has sukun (U+0652)
  final bool hasSukun;

  /// Has shadda (U+0651)
  final bool hasShadda;

  /// Has tanwin fatha (U+064B)
  final bool hasTanwinFath;

  /// Has tanwin kasra (U+064D)
  final bool hasTanwinKasr;

  /// Has tanwin damma (U+064C)
  final bool hasTanwinDamm;

  /// Has maddah (U+0653)
  final bool hasMaddah;

  /// Has hamza above (U+0654)
  final bool hasHamzaAbove;

  /// Has hamza below (U+0655)
  final bool hasHamzaBelow;

  /// Has superscript alef/dagger alef (U+0670)
  final bool hasSuperscriptAlef;

  /// Has subscript alef (U+0656)
  final bool hasSubscriptAlef;

  /// Has small high alef (U+06D6, U+06D7, U+06D8)
  final bool hasSmallHighAlef;

  /// Has small high meem (U+06E2)
  final bool hasSmallHighMeem;

  /// Has small high jeem (U+06DA)
  final bool hasSmallHighJeem;

  /// Has small high three dots (U+06DB)
  final bool hasSmallHighThreeDots;

  /// Has small high seen (U+06DC)
  final bool hasSmallHighSeen;

  /// Has small high rounded zero (U+06DF)
  final bool hasSmallHighRoundedZero;

  /// Has small high upright rectangular zero (U+06E0)
  final bool hasSmallHighUprightZero;

  /// Has small high dotless head (U+06E1)
  final bool hasSmallHighDotlessHead;

  /// Has small low meem (U+06ED)
  final bool hasSmallLowMeem;

  /// Type of letter (consonant, vowelCarrier, longVowel)
  final LetterType letterType;

  /// Whether this is a hamza variant
  final bool isHamzaVariant;

  /// Source database
  final String sourceDb;

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
    this.hasSmallHighAlef = false,
    this.hasSmallHighMeem = false,
    this.hasSmallHighJeem = false,
    this.hasSmallHighThreeDots = false,
    this.hasSmallHighSeen = false,
    this.hasSmallHighRoundedZero = false,
    this.hasSmallHighUprightZero = false,
    this.hasSmallHighDotlessHead = false,
    this.hasSmallLowMeem = false,
    this.letterType = LetterType.consonant,
    this.isHamzaVariant = false,
    this.sourceDb = 'qpc-hafs-word-by-word.db',
  });

  /// Factory constructor from database map
  factory QuranLetter.fromDb(Map<String, dynamic> map) {
    // Parse diacritics JSON
    List<DiacriticData> diacriticsList = [];
    final diacriticsJson = map['diacritics_json'] as String?;
    if (diacriticsJson != null && diacriticsJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(diacriticsJson);
        diacriticsList = decoded.map((d) => DiacriticData.fromJson(d)).toList();
      } catch (e) {
        // If parsing fails, return empty list
        diacriticsList = [];
      }
    }

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
      diacritics: diacriticsList,
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
      hasSmallHighAlef: (map['has_small_high_alef'] as int?) == 1,
      hasSmallHighMeem: (map['has_small_high_meem'] as int?) == 1,
      hasSmallHighJeem: (map['has_small_high_jeem'] as int?) == 1,
      hasSmallHighThreeDots: (map['has_small_high_three_dots'] as int?) == 1,
      hasSmallHighSeen: (map['has_small_high_seen'] as int?) == 1,
      hasSmallHighRoundedZero: (map['has_small_high_rounded_zero'] as int?) == 1,
      hasSmallHighUprightZero: (map['has_small_high_upright_zero'] as int?) == 1,
      hasSmallHighDotlessHead: (map['has_small_high_dotless_head'] as int?) == 1,
      hasSmallLowMeem: (map['has_small_low_meem'] as int?) == 1,
      letterType: LetterTypeExtension.fromIndex(map['letter_type_index'] as int? ?? 0),
      isHamzaVariant: (map['is_hamza_variant'] as int?) == 1,
      sourceDb: map['source_db'] as String? ?? 'qpc-hafs-word-by-word.db',
    );
  }

  /// Convert to database map
  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'word_id': wordId,
      'verse_key': verseKey,
      'word_position': wordPosition,
      'letter_index': letterIndex,
      'letter_position': letterPosition,
      'base_letter': baseLetter,
      'letter_with_diacritics': letterWithDiacritics,
      'base_letter_codepoint': baseLetterCodepoint,
      'base_letter_category': baseLetterCategory,
      'base_letter_name': baseLetterName,
      'diacritics_json': jsonEncode(diacritics.map((d) => d.toJson()).toList()),
      'has_fatha': hasFatha ? 1 : 0,
      'has_kasra': hasKasra ? 1 : 0,
      'has_damma': hasDamma ? 1 : 0,
      'has_sukun': hasSukun ? 1 : 0,
      'has_shadda': hasShadda ? 1 : 0,
      'has_tanwin_fath': hasTanwinFath ? 1 : 0,
      'has_tanwin_kasr': hasTanwinKasr ? 1 : 0,
      'has_tanwin_damm': hasTanwinDamm ? 1 : 0,
      'has_maddah': hasMaddah ? 1 : 0,
      'has_hamza_above': hasHamzaAbove ? 1 : 0,
      'has_hamza_below': hasHamzaBelow ? 1 : 0,
      'has_superscript_alef': hasSuperscriptAlef ? 1 : 0,
      'has_subscript_alef': hasSubscriptAlef ? 1 : 0,
      'has_small_high_alef': hasSmallHighAlef ? 1 : 0,
      'has_small_high_meem': hasSmallHighMeem ? 1 : 0,
      'has_small_high_jeem': hasSmallHighJeem ? 1 : 0,
      'has_small_high_three_dots': hasSmallHighThreeDots ? 1 : 0,
      'has_small_high_seen': hasSmallHighSeen ? 1 : 0,
      'has_small_high_rounded_zero': hasSmallHighRoundedZero ? 1 : 0,
      'has_small_high_upright_zero': hasSmallHighUprightZero ? 1 : 0,
      'has_small_high_dotless_head': hasSmallHighDotlessHead ? 1 : 0,
      'has_small_low_meem': hasSmallLowMeem ? 1 : 0,
      'letter_type_index': letterType.indexValue,
      'is_hamza_variant': isHamzaVariant ? 1 : 0,
      'source_db': sourceDb,
    };
  }

  // Convenience getters

  /// Get the full phonetic representation (base letter + diacritics)
  String get phonetic => letterWithDiacritics ?? baseLetter;

  /// Check if this letter has any diacritics attached
  bool get hasDiacritics => diacritics.isNotEmpty;

  /// Check if this letter has any haraka (fatha, kasra, or damma)
  bool get hasHaraka => hasFatha || hasKasra || hasDamma;

  /// Check if this letter has tanwin (any type)
  bool get hasTanwin => hasTanwinFath || hasTanwinKasr || hasTanwinDamm;

  /// Check if this letter has any special Quranic marks
  bool get hasSpecialMarks =>
      hasMaddah ||
      hasSuperscriptAlef ||
      hasSubscriptAlef ||
      hasSmallHighAlef ||
      hasSmallHighMeem ||
      hasSmallHighJeem ||
      hasSmallHighThreeDots ||
      hasSmallHighSeen ||
      hasSmallHighRoundedZero ||
      hasSmallHighUprightZero ||
      hasSmallHighDotlessHead ||
      hasSmallLowMeem;

  /// Check if this letter has any hamza marks
  bool get hasHamza => hasHamzaAbove || hasHamzaBelow;

  /// Get all diacritic characters as a single string
  String get diacriticsString => diacritics.map((d) => d.char).join();

  /// Get the Tajweed rule that applies to this letter based on diacritics
  ///
  /// This is a simplified version - full Tajweed analysis requires context
  String? get tajweedHint {
    if (hasShadda) return 'Shadda - Gemination';
    if (hasMaddah) return 'Maddah - Elongation';
    if (hasSukun) return 'Sukun - No vowel';
    if (hasTanwin) return 'Tanwin - Nunation';
    return null;
  }

  @override
  String toString() =>
      'QuranLetter($baseLetter [$diacriticsString] @ $verseKey:$wordPosition:$letterIndex)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuranLetter &&
        other.id == id &&
        other.wordId == wordId &&
        other.letterIndex == letterIndex;
  }

  @override
  int get hashCode => Object.hash(id, wordId, letterIndex);
}

/// Aggregated letter data for a complete word
class WordLetterData {
  /// The word ID
  final int wordId;

  /// Verse key
  final String verseKey;

  /// Word position in verse
  final int wordPosition;

  /// List of letters in display order (RTL)
  final List<QuranLetter> letters;

  const WordLetterData({
    required this.wordId,
    required this.verseKey,
    required this.wordPosition,
    required this.letters,
  });

  /// Factory constructor from list of letter data
  factory WordLetterData.fromLetters(List<QuranLetter> letters) {
    if (letters.isEmpty) {
      throw ArgumentError('Cannot create WordLetterData from empty list');
    }

    return WordLetterData(
      wordId: letters.first.wordId,
      verseKey: letters.first.verseKey,
      wordPosition: letters.first.wordPosition,
      letters: List.unmodifiable(letters),
    );
  }

  /// Get the full word text by joining all letters
  String get fullText => letters.map((l) => l.phonetic).join();

  /// Get just the base letters without diacritics
  String get baseText => letters.map((l) => l.baseLetter).join();

  /// Get the number of letters in this word
  int get letterCount => letters.length;

  /// Get letters with specific diacritic
  List<QuranLetter> getLettersWithDiacritic(bool Function(QuranLetter) predicate) {
    return letters.where(predicate).toList();
  }

  /// Get all letters with shadda
  List<QuranLetter> get lettersWithShadda =>
      getLettersWithDiacritic((l) => l.hasShadda);

  /// Get all letters with haraka
  List<QuranLetter> get lettersWithHaraka =>
      getLettersWithDiacritic((l) => l.hasHaraka);

  @override
  String toString() =>
      'WordLetterData(wordId: $wordId, letters: ${letters.length})';
}

/// Statistics for letter analysis
class LetterStatistics {
  /// Total number of letters analyzed
  final int totalLetters;

  /// Count of each base letter
  final Map<String, int> letterFrequency;

  /// Count of each diacritic type
  final Map<String, int> diacriticFrequency;

  /// Average letters per word
  final double averageLettersPerWord;

  const LetterStatistics({
    required this.totalLetters,
    required this.letterFrequency,
    required this.diacriticFrequency,
    required this.averageLettersPerWord,
  });

  /// Get the most frequent letter
  String? get mostFrequentLetter {
    if (letterFrequency.isEmpty) return null;
    return letterFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get the most common diacritic
  String? get mostCommonDiacritic {
    if (diacriticFrequency.isEmpty) return null;
    return diacriticFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}
