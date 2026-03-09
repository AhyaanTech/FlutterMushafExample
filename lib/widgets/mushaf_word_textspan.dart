import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../models/tajweed_models.dart';
import '../services/database_helper.dart';
import 'mushaf_widgets.dart';
import 'mushaf_word_factory.dart';

/// TextSpan-based word widget for Tajweed letter coloring
///
/// This widget uses Flutter's RichText with multiple TextSpans to render
/// each letter with its own color based on Tajweed rules. It fetches
/// letter-level data from the database and gracefully falls back to
/// plain text if the V4 tajweed data is not available.
///
/// Usage:
/// ```dart
/// MushafWordTextSpan(
///   word: quranWord,
///   colorMode: ColorMode.tajweed,
///   isMarked: false,
///   onTap: () => handleWordTap(word.id),
///   onLetterTap: (wordId, letterIndex) => handleLetterTap(wordId, letterIndex),
///   customColors: letterColors,
///   lineType: 'ayah',
/// )
/// ```
class MushafWordTextSpan extends StatefulWidget {
  /// The Quran word data containing id, text, and metadata
  final QuranWord word;

  /// The color mode for rendering (none, tajweed, mistakes, or custom)
  final ColorMode colorMode;

  /// Whether this word is currently marked by the user
  final bool isMarked;

  /// Callback when the word is tapped
  final VoidCallback onTap;

  /// The type of line this word belongs to ('surah_name', 'basmallah', 'ayah')
  final String lineType;

  /// Optional callback when a specific letter is tapped (for custom coloring)
  /// Only invoked when [colorMode] is [ColorMode.custom]
  final LetterTapCallback? onLetterTap;

  /// Optional list of custom colors per letter index (for custom mode)
  /// Each index corresponds to a letter in the word; null means no custom color
  final List<Color?>? customColors;

  const MushafWordTextSpan({
    super.key,
    required this.word,
    required this.colorMode,
    required this.isMarked,
    required this.onTap,
    required this.lineType,
    this.onLetterTap,
    this.customColors,
  });

  @override
  State<MushafWordTextSpan> createState() => _MushafWordTextSpanState();
}

class _MushafWordTextSpanState extends State<MushafWordTextSpan> {
  /// Future that fetches letter data for this word
  late Future<WordLetterData?> _letterDataFuture;

  @override
  void initState() {
    super.initState();
    _letterDataFuture = _fetchLetterData();
  }

  @override
  void didUpdateWidget(MushafWordTextSpan oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refetch if word ID changes
    if (oldWidget.word.id != widget.word.id) {
      _letterDataFuture = _fetchLetterData();
    }
  }

  /// Fetches letter data from the database
  Future<WordLetterData?> _fetchLetterData() async {
    return DatabaseHelper().getWordLetterData(widget.word.id);
  }

  /// Gets the base text style based on line type and marked state
  TextStyle _getBaseTextStyle() {
    return MushafTheme.getTextStyle(widget.lineType, isMarked: widget.isMarked);
  }

  /// Gets the font size based on line type
  double _getFontSize() {
    switch (widget.lineType) {
      case 'surah_name':
        return MushafTheme.surahNameFontSize;
      case 'basmallah':
        return MushafTheme.basmallahFontSize;
      case 'ayah':
      default:
        return MushafTheme.ayahFontSize;
    }
  }

  /// Gets the default text color based on line type
  Color _getDefaultTextColor() {
    if (widget.isMarked) {
      return MushafTheme.markedWordColor;
    }

    switch (widget.lineType) {
      case 'surah_name':
        return MushafTheme.surahNameColor;
      case 'basmallah':
        return MushafTheme.basmallahColor;
      case 'ayah':
      default:
        return MushafTheme.ayahTextColor;
    }
  }

  /// Gets the background color for marked state
  Color _getMarkedBackgroundColor() {
    return MushafTheme.getMarkedBackgroundColor(widget.lineType);
  }

  /// Builds the colored TextSpan representation of the word
  ///
  /// When [colorMode] is [ColorMode.custom] and [onLetterTap] is provided,
  /// each letter is wrapped with a GestureDetector for individual tap detection.
  /// Otherwise, uses standard TextSpans for better performance.
  Widget _buildColoredText(WordLetterData data, {List<Color?>? customColors}) {
    final isCustomModeWithTap =
        widget.colorMode == ColorMode.custom && widget.onLetterTap != null;

    if (isCustomModeWithTap) {
      // Build with tappable letters using WidgetSpan
      return _buildTappableLetters(data, customColors: customColors);
    } else {
      // Build with standard TextSpans for better performance
      return _buildStandardText(data, customColors: customColors);
    }
  }

  /// Builds the word with tappable letter widgets
  ///
  /// Each letter is wrapped in a GestureDetector for individual tap detection.
  /// This is used when in custom color mode with an onLetterTap callback.
  Widget _buildTappableLetters(WordLetterData data,
      {List<Color?>? customColors}) {
    // Create a WidgetSpan for each letter with tap detection
    final List<WidgetSpan> letterSpans = <WidgetSpan>[];

    for (int i = 0; i < data.letters.length; i++) {
      final letter = data.letters[i];
      final Color letterColor = _getLetterColor(
        letter,
        letterIndex: i,
        customColors: customColors,
      );

      letterSpans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          onTap: () => widget.onLetterTap?.call(widget.word.id, i),
          behavior: HitTestBehavior.opaque,
          child: Container(
            // Small padding for easier tapping
            padding: const EdgeInsets.symmetric(horizontal: 1.0),
            child: Text(
              letter.char,
              style: TextStyle(
                color: letterColor,
                fontSize: _getFontSize(),
                fontFamily: 'UthmanicHafs',
                fontFamilyFallback: MushafTheme.arabicFontFallbacks,
                fontWeight: widget.lineType == 'surah_name'
                    ? FontWeight.bold
                    : FontWeight.normal,
                height: _getLineHeight(),
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: letterSpans),
      textDirection: TextDirection.rtl,
      textAlign: widget.word.isCentered ? TextAlign.center : TextAlign.right,
    );
  }

  /// Builds the word with standard TextSpans (no letter-level tap detection)
  ///
  /// Used for all color modes except custom mode with onLetterTap callback.
  Widget _buildStandardText(WordLetterData data, {List<Color?>? customColors}) {
    // Create a TextSpan for each letter with appropriate color
    final List<TextSpan> letterSpans = <TextSpan>[];
    for (int i = 0; i < data.letters.length; i++) {
      final letter = data.letters[i];
      final Color letterColor = _getLetterColor(
        letter,
        letterIndex: i,
        customColors: customColors,
      );

      letterSpans.add(TextSpan(
        text: letter.char,
        style: TextStyle(
          color: letterColor,
          fontSize: _getFontSize(),
          fontFamily: 'UthmanicHafs',
          fontFamilyFallback: MushafTheme.arabicFontFallbacks,
          fontWeight: widget.lineType == 'surah_name'
              ? FontWeight.bold
              : FontWeight.normal,
          height: _getLineHeight(),
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: letterSpans),
      textDirection: TextDirection.rtl,
      textAlign: widget.word.isCentered ? TextAlign.center : TextAlign.right,
    );
  }

  /// Gets the color for a specific letter based on the current color mode
  /// and optional custom letter colors
  Color _getLetterColor(
    LetterData letter, {
    required int letterIndex,
    List<Color?>? customColors,
  }) {
    return resolveLetterColor(
      colorMode: widget.colorMode,
      letter: letter,
      letterIndex: letterIndex,
      defaultColor: _getDefaultTextColor(),
      customColors: customColors,
      wordId: widget.word.id,
    );
  }

  /// Gets the line height based on line type
  double _getLineHeight() {
    switch (widget.lineType) {
      case 'surah_name':
        return MushafTheme.surahNameLineHeight;
      case 'basmallah':
        return MushafTheme.basmallahLineHeight;
      case 'ayah':
      default:
        return MushafTheme.ayahLineHeight;
    }
  }

  /// Builds the fallback plain text widget when letter data is not available
  Widget _buildPlainTextFallback() {
    final textStyle = _getBaseTextStyle().copyWith(
      fontSize: _getFontSize(),
      fontFamily: 'UthmanicHafs',
      fontFamilyFallback: MushafTheme.arabicFontFallbacks,
    );

    return Text(
      widget.word.text,
      style: textStyle,
      textDirection: TextDirection.rtl,
      textAlign: widget.word.isCentered ? TextAlign.center : TextAlign.right,
    );
  }

  /// Builds the loading placeholder
  Widget _buildLoadingWidget() {
    // Show plain text while loading for immediate display
    return _buildPlainTextFallback();
  }

  /// Builds the error state widget
  Widget _buildErrorWidget(Object? error) {
    // Fall back to plain text on error, but could add visual indicator
    return _buildPlainTextFallback();
  }

  @override
  Widget build(BuildContext context) {
    // Determine visual feedback for marked state
    final backgroundColor =
        widget.isMarked ? _getMarkedBackgroundColor() : Colors.transparent;

    final border = widget.isMarked
        ? Border.all(
            color: MushafTheme.markedWordColor.withValues(alpha: 0.3),
            width: 1.0,
          )
        : null;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: MushafTheme.wordHorizontalPadding,
          vertical: 2.0,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: border,
        ),
        child: FutureBuilder<WordLetterData?>(
          future: _letterDataFuture,
          builder: (context, snapshot) {
            // Handle different states
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show plain text while loading
              return _buildLoadingWidget();
            }

            if (snapshot.hasError) {
              // Error state - fall back to plain text
              return _buildErrorWidget(snapshot.error);
            }

            if (!snapshot.hasData || snapshot.data == null) {
              // No letter data available - use plain text fallback
              return _buildPlainTextFallback();
            }

            // Success - build colored TextSpan representation
            return _buildColoredText(
              snapshot.data!,
              customColors: widget.customColors,
            );
          },
        ),
      ),
    );
  }
}

/// Extension to provide additional functionality for ColorMode
extension ColorModeTextSpanExtension on ColorMode {
  /// Checks if this color mode requires letter-level data
  bool get requiresLetterData {
    switch (this) {
      case ColorMode.none:
        return false;
      case ColorMode.tajweed:
      case ColorMode.mistakes:
      case ColorMode.custom:
        return true;
    }
  }
}

/// Resolves the color for a letter based on color mode and custom colors
///
/// This function determines the appropriate color for a letter by checking:
/// 1. Custom color (if provided and in custom mode) - takes precedence
/// 2. Tajweed rule color (if applicable and in tajweed mode)
/// 3. Mistake highlighting (if in mistakes mode)
/// 4. Default color (fallback)
///
/// Parameters:
/// - [colorMode]: The current color mode
/// - [letter]: The letter data containing tajweed rule info
/// - [letterIndex]: The index of the letter in the word (for custom colors)
/// - [defaultColor]: The default color to use as fallback
/// - [customColors]: Optional list of custom colors per letter index
/// - [wordId]: The word ID (used for mistake simulation)
///
/// Returns the resolved color for the letter
Color resolveLetterColor({
  required ColorMode colorMode,
  required LetterData letter,
  required int letterIndex,
  required Color defaultColor,
  List<Color?>? customColors,
  int? wordId,
}) {
  switch (colorMode) {
    case ColorMode.none:
      // No coloring - use default text color
      return defaultColor;

    case ColorMode.tajweed:
      // Use Tajweed rule colors from DatabaseHelper
      if (letter.hasTajweedRule) {
        return DatabaseHelper.tajweedColors[letter.tajweedRule] ?? defaultColor;
      }
      return defaultColor;

    case ColorMode.mistakes:
      // Simulate mistake highlighting with deterministic assignment
      // In a real implementation, this would come from user mistake data
      final hash = (letter.char.hashCode + (wordId ?? 0)) % 10;
      final isCorrect = hash < 7; // 70% correct, 30% mistakes
      return isCorrect ? Colors.green : Colors.red;

    case ColorMode.custom:
      // Custom color takes precedence if available
      if (customColors != null &&
          letterIndex >= 0 &&
          letterIndex < customColors.length) {
        final customColor = customColors[letterIndex];
        if (customColor != null) {
          return customColor;
        }
      }
      // Fall back to default color if no custom color is set
      return defaultColor;
  }
}
