/// Data models for Tajweed letter coloring and glyph-based rendering
///
/// These models support the letter coloring comparison experiment between
/// TextSpan (rich text) and Glyph (custom painter) rendering approaches.
library tajweed_models;

import 'package:flutter/material.dart';

/// Enum representing different color modes for Tajweed rendering
enum ColorMode {
  /// No coloring - display text in normal/default color
  none,

  /// Tajweed rules coloring - letters colored by Tajweed rules (red, blue, etc.)
  tajweed,

  /// Mistake highlighting - colors indicating memorization mistakes
  mistakes,

  /// Custom letter coloring - user-defined colors for individual letters
  custom,
}

/// Enum representing the rendering mode for word widgets
enum RenderingMode {
  /// TextSpan approach - using Flutter's RichText with multiple TextSpans
  textspan,

  /// Glyph approach - using CustomPainter with positioned glyphs
  glyph,
}

/// Holds letter-level data for the TextSpan rendering approach
///
/// Contains a word ID and the list of individual letters with their
/// Tajweed rule assignments for per-letter coloring.
class WordLetterData {
  /// The unique word ID from the database
  final int wordId;

  /// List of letter data for this word, in display order (RTL)
  final List<LetterData> letters;

  const WordLetterData({
    required this.wordId,
    required this.letters,
  });

  /// Factory constructor to create WordLetterData from a database map
  /// Expects columns: word_id
  /// Letters are typically joined from a separate letter_data query
  factory WordLetterData.fromDb(
    Map<String, dynamic> map,
    List<LetterData> letterList,
  ) {
    return WordLetterData(
      wordId: map['word_id'] as int,
      letters: List.unmodifiable(letterList),
    );
  }

  /// Get the full word text by joining all letters
  String get fullText => letters.map((l) => l.char).join();

  @override
  String toString() =>
      'WordLetterData(wordId: $wordId, letters: ${letters.length})';
}

/// Represents a single letter/character with its Tajweed rule
///
/// Used by the TextSpan approach to build colored RichText widgets.
class LetterData {
  /// The character/letter as a string (may include diacritics)
  final String char;

  /// The Tajweed rule identifier (e.g., 'ghunnah', 'ikhfa', 'idgham', 'normal')
  /// Can be empty or 'normal' if no special rule applies
  final String tajweedRule;

  const LetterData({
    required this.char,
    this.tajweedRule = 'normal',
  });

  /// Factory constructor to create LetterData from a database map
  /// Expects columns: char, tajweed_rule
  factory LetterData.fromDb(Map<String, dynamic> map) {
    return LetterData(
      char: map['char'] as String,
      tajweedRule: map['tajweed_rule'] as String? ?? 'normal',
    );
  }

  /// Check if this letter has a special Tajweed rule applied
  bool get hasTajweedRule => tajweedRule.isNotEmpty && tajweedRule != 'normal';

  @override
  String toString() => 'LetterData(char: $char, rule: $tajweedRule)';
}

/// Holds glyph data for the Glyph-based rendering approach
///
/// Each glyph represents a positioned character with specific styling
/// for precise Mushaf reproduction using CustomPainter.
class GlyphData {
  /// The character/glyph as a string
  final String char;

  /// X-coordinate position for placement
  final double x;

  /// Y-coordinate position for placement
  final double y;

  /// Font size for this glyph
  final double fontSize;

  /// Hex color string (e.g., 'FFEF5350' or '#EF5350')
  final String colorHex;

  /// Optional: glyph type (base, diacritic, ligature)
  final String? glyphType;

  /// Optional: width of the glyph bounding box
  final double? width;

  /// Optional: height of the glyph bounding box
  final double? height;

  const GlyphData({
    required this.char,
    required this.x,
    required this.y,
    required this.fontSize,
    required this.colorHex,
    this.glyphType,
    this.width,
    this.height,
  });

  /// Factory constructor to create GlyphData from a database map
  /// Expects columns: glyph_char, x_position, y_position, font_size, color_hex
  /// Optional columns: glyph_type, width, height
  factory GlyphData.fromDb(Map<String, dynamic> map) {
    return GlyphData(
      char: map['glyph_char'] as String,
      x: map['x_position'] as double,
      y: map['y_position'] as double,
      fontSize: map['font_size'] as double,
      colorHex: map['color_hex'] as String,
      glyphType: map['glyph_type'] as String?,
      width: map['width'] as double?,
      height: map['height'] as double?,
    );
  }

  /// Parse the hex color string into a Flutter Color
  /// Supports both 'AARRGGBB' and '#RRGGBB' formats
  int get colorValue {
    String hex = colorHex.trim();

    // Remove # prefix if present
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }

    // Handle RGB format (convert to ARGB with full opacity)
    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    // Parse the hex value
    return int.tryParse(hex, radix: 16) ?? 0xFF000000;
  }

  @override
  String toString() =>
      'GlyphData(char: $char, x: $x, y: $y, size: $fontSize, color: $colorHex)';
}

/// Extension on ColorMode for utility methods
extension ColorModeExtension on ColorMode {
  /// Get a display name for the color mode
  String get displayName {
    switch (this) {
      case ColorMode.none:
        return 'Normal';
      case ColorMode.tajweed:
        return 'Tajweed Rules';
      case ColorMode.mistakes:
        return 'Mistake Highlighting';
      case ColorMode.custom:
        return 'Custom Colors';
    }
  }

  /// Get an icon name suggestion for the color mode
  String get iconName {
    switch (this) {
      case ColorMode.none:
        return 'text_format';
      case ColorMode.tajweed:
        return 'palette';
      case ColorMode.mistakes:
        return 'warning';
      case ColorMode.custom:
        return 'brush';
    }
  }
}

/// Represents a custom color applied to a specific letter within a word
///
/// Used for letter-by-letter custom coloring feature where users can
/// apply custom colors to individual letters for memorization or study.
class CustomLetterColor {
  /// The unique word ID from the database
  final int wordId;

  /// The index of the letter within the word (0-based)
  final int letterIndex;

  /// The color to apply to this letter
  final Color color;

  const CustomLetterColor({
    required this.wordId,
    required this.letterIndex,
    required this.color,
  });

  /// Create a copy with optionally updated fields
  CustomLetterColor copyWith({
    int? wordId,
    int? letterIndex,
    Color? color,
  }) {
    return CustomLetterColor(
      wordId: wordId ?? this.wordId,
      letterIndex: letterIndex ?? this.letterIndex,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomLetterColor &&
        other.wordId == wordId &&
        other.letterIndex == letterIndex &&
        other.color == color;
  }

  @override
  int get hashCode => Object.hash(wordId, letterIndex, color);

  @override
  String toString() =>
      'CustomLetterColor(wordId: $wordId, letterIndex: $letterIndex, color: $color)';
}

/// Extension on RenderingMode for utility methods
extension RenderingModeExtension on RenderingMode {
  /// Get a display name for the rendering mode
  String get displayName {
    switch (this) {
      case RenderingMode.textspan:
        return 'TextSpan (Flutter Text)';
      case RenderingMode.glyph:
        return 'Glyph (CustomPainter)';
    }
  }

  /// Get a short display name for the rendering mode
  String get shortName {
    switch (this) {
      case RenderingMode.textspan:
        return 'TextSpan';
      case RenderingMode.glyph:
        return 'Glyph';
    }
  }
}
