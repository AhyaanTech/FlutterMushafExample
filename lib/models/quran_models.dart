/// Data models for Quran-related entities

/// Represents a single word in the Quran text
class QuranWord {
  final int id;
  final String text;
  final String verseKey;
  final String lineType;
  final bool isCentered;

  QuranWord({
    required this.id,
    required this.text,
    required this.verseKey,
    required this.lineType,
    required this.isCentered,
  });

  /// Factory constructor to create a QuranWord from a database map
  factory QuranWord.fromDb(Map<String, dynamic> map) {
    return QuranWord(
      id: map['word_id'] as int,
      text: map['arabic_text'] as String,
      verseKey: map['verse_key'] as String,
      lineType: map['line_type'] as String,
      isCentered: (map['is_centered'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'word_id': id,
      'arabic_text': text,
      'verse_key': verseKey,
      'line_type': lineType,
      'is_centered': isCentered ? 1 : 0,
    };
  }
}

/// Represents a line of text on a Mushaf page
class QuranLine {
  final int lineNumber;
  final String lineType;
  final bool isCentered;
  final List<QuranWord> words;

  QuranLine({
    required this.lineNumber,
    required this.lineType,
    required this.isCentered,
    required this.words,
  });

  /// Factory constructor to create a QuranLine from words belonging to the same line
  factory QuranLine.fromWords(
    List<QuranWord> lineWords,
    int lineNumber,
    String lineType,
    bool isCentered,
  ) {
    return QuranLine(
      lineNumber: lineNumber,
      lineType: lineType,
      isCentered: isCentered,
      words: List.unmodifiable(lineWords),
    );
  }

  /// Get the full text of this line by joining all words
  String get fullText => words.map((w) => w.text).join(' ');

  /// Check if this line is a surah name header
  bool get isSurahName => lineType == 'surah_name';

  /// Check if this line is a basmallah
  bool get isBasmallah => lineType == 'basmallah';

  /// Check if this line contains regular ayah text
  bool get isAyah => lineType == 'ayah';
}

/// Represents a complete Mushaf page with all its lines
class QuranPage {
  final int pageNumber;
  final List<QuranLine> lines;

  QuranPage({required this.pageNumber, required this.lines});

  /// Factory constructor to create a QuranPage from database rows
  /// Groups words by line number to create QuranLine objects
  factory QuranPage.fromDbRows(
    int pageNumber,
    List<Map<String, dynamic>> rows,
  ) {
    // Group rows by line number
    final lineGroups = <int, List<QuranWord>>{};
    final lineTypes = <int, String>{};
    final lineCentered = <int, bool>{};

    for (final row in rows) {
      final lineNumber = row['line_number'] as int;
      final word = QuranWord.fromDb(row);

      lineGroups.putIfAbsent(lineNumber, () => []).add(word);
      lineTypes[lineNumber] = row['line_type'] as String;
      lineCentered[lineNumber] = (row['is_centered'] as int) == 1;
    }

    // Create QuranLine objects sorted by line number
    final sortedLineNumbers = lineGroups.keys.toList()..sort();
    final lines = sortedLineNumbers.map((lineNum) {
      return QuranLine.fromWords(
        lineGroups[lineNum]!,
        lineNum,
        lineTypes[lineNum]!,
        lineCentered[lineNum]!,
      );
    }).toList();

    return QuranPage(pageNumber: pageNumber, lines: List.unmodifiable(lines));
  }

  /// Get the number of lines on this page (typically 15 for Indo-Pak Mushaf)
  int get lineCount => lines.length;

  /// Get all words on this page
  List<QuranWord> get allWords => lines.expand((line) => line.words).toList();
}

/// Legacy model: Represents a Surah (chapter) in the Quran
class Surah {
  final int id;
  final String name;
  final String englishName;
  final int verseCount;
  final int pageStart;
  final int pageEnd;

  Surah({
    required this.id,
    required this.name,
    required this.englishName,
    required this.verseCount,
    required this.pageStart,
    required this.pageEnd,
  });

  factory Surah.fromMap(Map<String, dynamic> map) {
    return Surah(
      id: map['id'] as int,
      name: map['name'] as String,
      englishName: map['english_name'] as String,
      verseCount: map['verse_count'] as int,
      pageStart: map['page_start'] as int,
      pageEnd: map['page_end'] as int,
    );
  }
}

/// Legacy model: Represents an Ayah (verse) in the Quran
class Ayah {
  final int id;
  final int surahId;
  final int ayahNumber;
  final String uthmaniText;
  final String? indopakText;
  final int page;
  final int juz;
  final int hizb;
  final int manzil;

  Ayah({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.uthmaniText,
    this.indopakText,
    required this.page,
    required this.juz,
    required this.hizb,
    required this.manzil,
  });

  factory Ayah.fromMap(Map<String, dynamic> map) {
    return Ayah(
      id: map['id'] as int,
      surahId: map['surah_id'] as int,
      ayahNumber: map['ayah_number'] as int,
      uthmaniText: map['uthmani_text'] as String,
      indopakText: map['indopak_text'] as String?,
      page: map['page'] as int,
      juz: map['juz'] as int,
      hizb: map['hizb'] as int,
      manzil: map['manzil'] as int,
    );
  }
}

/// Legacy model: Represents a single word in an Ayah
class Word {
  final int id;
  final int ayahId;
  final String text;
  final String? translation;
  final int position;

  Word({
    required this.id,
    required this.ayahId,
    required this.text,
    this.translation,
    required this.position,
  });

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'] as int,
      ayahId: map['ayah_id'] as int,
      text: map['text'] as String,
      translation: map['translation'] as String?,
      position: map['position'] as int,
    );
  }
}
