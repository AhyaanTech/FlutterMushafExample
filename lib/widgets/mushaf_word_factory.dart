import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../models/tajweed_models.dart';
import 'mushaf_word_textspan.dart';
import 'mushaf_word_glyph.dart';

/// Type definition for callback when a letter is tapped
///
/// Parameters:
/// - [wordId]: The unique ID of the word containing the letter
/// - [letterIndex]: The index of the letter within the word (0-based)
typedef LetterTapCallback = void Function(int wordId, int letterIndex);

/// Factory class for creating Mushaf word widgets based on rendering mode
///
/// This factory implements the strategy pattern to switch between:
/// - TextSpan mode: Using Flutter's RichText with multiple TextSpans
/// - Glyph mode: Using CustomPainter with positioned glyphs
///
/// Usage:
/// ```dart
/// Widget wordWidget = MushafWordFactory.build(
///   word: quranWord,
///   mode: RenderingMode.textspan,
///   colorMode: ColorMode.custom,
///   isMarked: false,
///   onTap: () => handleWordTap(word.id),
///   onLetterTap: (wordId, letterIndex) => handleLetterTap(wordId, letterIndex),
///   customColors: letterColors,
///   lineType: 'ayah',
/// );
/// ```
class MushafWordFactory {
  /// Builds the appropriate word widget based on the rendering mode
  ///
  /// Parameters:
  /// - [word]: The QuranWord data containing id, text, verseKey, etc.
  /// - [mode]: The rendering mode (textspan or glyph)
  /// - [colorMode]: The color mode (none, tajweed, mistakes, or custom)
  /// - [isMarked]: Whether this word is currently marked by the user
  /// - [onTap]: Callback when the word is tapped (for word-level interaction)
  /// - [onLetterTap]: Optional callback when a specific letter is tapped
  /// - [customColors]: Optional list of custom colors per letter index (for custom mode)
  /// - [lineType]: The type of line ('ayah', 'surah_name', 'basmallah')
  ///
  /// Returns a widget configured for the specified rendering mode
  static Widget build({
    required QuranWord word,
    required RenderingMode mode,
    required ColorMode colorMode,
    required bool isMarked,
    required VoidCallback onTap,
    LetterTapCallback? onLetterTap,
    List<Color?>? customColors,
    required String lineType,
  }) {
    switch (mode) {
      case RenderingMode.textspan:
        return _buildTextSpanWidget(
          word: word,
          colorMode: colorMode,
          isMarked: isMarked,
          onTap: onTap,
          onLetterTap: onLetterTap,
          customColors: customColors,
          lineType: lineType,
        );
      case RenderingMode.glyph:
        return _buildGlyphWidget(
          word: word,
          colorMode: colorMode,
          isMarked: isMarked,
          onTap: onTap,
          onLetterTap: onLetterTap,
          customColors: customColors,
          lineType: lineType,
        );
    }
  }

  /// Builds a TextSpan-based widget using MushafWordTextSpan
  ///
  /// Uses Flutter's RichText with multiple TextSpans for per-letter coloring
  /// based on Tajweed rules or custom colors.
  static Widget _buildTextSpanWidget({
    required QuranWord word,
    required ColorMode colorMode,
    required bool isMarked,
    required VoidCallback onTap,
    LetterTapCallback? onLetterTap,
    List<Color?>? customColors,
    required String lineType,
  }) {
    return MushafWordTextSpan(
      word: word,
      colorMode: colorMode,
      isMarked: isMarked,
      onTap: onTap,
      lineType: lineType,
      onLetterTap: onLetterTap,
      customColors: customColors,
    );
  }

  /// Builds a Glyph-based widget using MushafWordGlyph
  ///
  /// Uses CustomPainter with positioned glyphs from the glyph database
  /// for pixel-perfect Mushaf reproduction.
  /// Note: Glyph mode has limited custom color support - colors are applied at
  /// glyph level but tap detection is at word level (not letter level).
  static Widget _buildGlyphWidget({
    required QuranWord word,
    required ColorMode colorMode,
    required bool isMarked,
    required VoidCallback onTap,
    LetterTapCallback? onLetterTap,
    List<Color?>? customColors,
    required String lineType,
  }) {
    return MushafWordGlyph(
      word: word,
      colorMode: colorMode,
      isMarked: isMarked,
      onTap: onTap,
      lineType: lineType,
      onLetterTap: onLetterTap,
      customColors: customColors,
    );
  }
}

/// Widget key generator for word widgets
///
/// Ensures proper widget identity for Flutter's reconciliation
class MushafWordKey {
  /// Generate a unique key for a word widget
  static Key generate(int wordId, RenderingMode mode) {
    return ValueKey('word_${wordId}_${mode.name}');
  }
}
