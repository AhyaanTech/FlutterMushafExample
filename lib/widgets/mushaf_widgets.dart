import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../models/tajweed_models.dart';
import 'mushaf_word_factory.dart';

// Note: LetterTapCallback is defined in mushaf_word_factory.dart

/// Enhanced Mushaf Theme Configuration
/// Provides consistent styling for the Quran reading experience
class MushafTheme {
  // Prevent instantiation
  MushafTheme._();

  // Font family fallback chain for Arabic text
  // Primary: UthmanicHafs - Official QPC Hafs font from QUL.Tarteel (ID 245)
  // Fallbacks: System fonts for platform compatibility
  static const List<String> arabicFontFallbacks = [
    'UthmanicHafs', // QPC Hafs font - primary for Uthmani script
    '.SF Arabic', // iOS/macOS Arabic (critical for macOS)
    'Roboto', // Android (has Arabic support)
    'Arial', // Windows/macOS fallback
    'Noto Sans Arabic', // Common system font
    'Scheherazade', // Alternative custom font if available
  ];

  // Warm traditional color palette
  static const Color surahNameColor = Color(0xFFB8860B); // Dark Goldenrod
  static const Color surahNameLightColor = Color(0xFFD4A84B); // Lighter gold
  static const Color basmallahColor = Color(0xFF2C3E50); // Dark slate blue-gray
  static const Color ayahTextColor =
      Color(0xFF1A1A1A); // Near black for readability
  static const Color markedWordColor =
      Color(0xFF27AE60); // Elegant green for marking
  static const Color markedWordBackground =
      Color(0xFFD5F5E3); // Light green background
  static const Color pageBackgroundColor = Color(0xFFFDFCF8); // Warm off-white
  static const Color dividerColor = Color(0xFFE8E4D9); // Subtle warm divider

  // Typography scale for different line types
  static const double surahNameFontSize = 26.0;
  static const double basmallahFontSize = 22.0;
  static const double ayahFontSize = 20.0;

  // Line heights for readability
  static const double surahNameLineHeight = 1.4;
  static const double basmallahLineHeight = 1.5;
  static const double ayahLineHeight = 1.6;

  // Spacing constants
  static const double surahNameVerticalPadding = 12.0;
  static const double basmallahVerticalPadding = 8.0;
  static const double ayahVerticalPadding = 4.0;
  static const double surahTransitionSpacing = 16.0;
  static const double wordHorizontalPadding = 3.0;

  /// Get text style based on line type
  static TextStyle getTextStyle(String lineType, {bool isMarked = false}) {
    switch (lineType) {
      case 'surah_name':
        return TextStyle(
          fontSize: surahNameFontSize,
          fontFamilyFallback: arabicFontFallbacks,
          fontWeight: FontWeight.bold,
          color: isMarked ? markedWordColor : surahNameColor,
          height: surahNameLineHeight,
        );
      case 'basmallah':
        return TextStyle(
          fontSize: basmallahFontSize,
          fontFamilyFallback: arabicFontFallbacks,
          fontWeight: FontWeight.w600,
          color: isMarked ? markedWordColor : basmallahColor,
          height: basmallahLineHeight,
        );
      case 'ayah':
      default:
        return TextStyle(
          fontSize: ayahFontSize,
          fontFamilyFallback: arabicFontFallbacks,
          fontWeight: FontWeight.normal,
          color: isMarked ? markedWordColor : ayahTextColor,
          height: ayahLineHeight,
        );
    }
  }

  /// Get vertical padding based on line type
  static EdgeInsets getLinePadding(String lineType) {
    switch (lineType) {
      case 'surah_name':
        return const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: surahNameVerticalPadding,
        );
      case 'basmallah':
        return const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: basmallahVerticalPadding,
        );
      case 'ayah':
      default:
        return const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: ayahVerticalPadding,
        );
    }
  }

  /// Get background color for marked words based on line type
  static Color getMarkedBackgroundColor(String lineType) {
    // Slightly different tint based on line type for visual interest
    switch (lineType) {
      case 'surah_name':
        return markedWordColor.withValues(alpha: 0.12);
      case 'basmallah':
        return markedWordColor.withValues(alpha: 0.10);
      case 'ayah':
      default:
        return markedWordBackground.withValues(alpha: 0.8);
    }
  }

  /// Check if a line type represents a surah transition
  static bool isSurahTransition(String lineType) {
    return lineType == 'surah_name' || lineType == 'basmallah';
  }
}

/// Widget for displaying a single Quran word with tap-to-mark functionality
/// Enhanced with context-aware styling based on line type
class MushafWordWidget extends StatelessWidget {
  final QuranWord word;
  final bool isMarked;
  final VoidCallback onTap;
  final String lineType;

  const MushafWordWidget({
    super.key,
    required this.word,
    required this.isMarked,
    required this.onTap,
    required this.lineType,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = MushafTheme.getTextStyle(lineType, isMarked: isMarked);
    final backgroundColor = isMarked
        ? MushafTheme.getMarkedBackgroundColor(lineType)
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
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
          border: isMarked
              ? Border.all(
                  color: MushafTheme.markedWordColor.withValues(alpha: 0.3),
                  width: 1.0,
                )
              : null,
        ),
        child: Text(
          word.text,
          style: textStyle,
          textAlign: word.isCentered ? TextAlign.center : TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}

/// Widget for displaying a line of Quran text
/// Enhanced with line-type specific styling and spacing
class MushafLineWidget extends StatelessWidget {
  final QuranLine line;
  final Set<int> markedWordIds;
  final Function(int wordId) onWordTap;
  final bool isFirstLine;
  final bool isAfterSurahTransition;
  final RenderingMode renderingMode;
  final ColorMode colorMode;

  /// Optional callback when a letter is tapped (for custom coloring)
  final LetterTapCallback? onLetterTap;

  /// Function to get custom colors for a word (returns null if no custom colors)
  final List<Color?>? Function(int wordId)? getCustomColors;

  const MushafLineWidget({
    super.key,
    required this.line,
    required this.markedWordIds,
    required this.onWordTap,
    this.isFirstLine = false,
    this.isAfterSurahTransition = false,
    this.renderingMode = RenderingMode.textspan,
    this.colorMode = ColorMode.none,
    this.onLetterTap,
    this.getCustomColors,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the main axis alignment based on line type
    final MainAxisAlignment alignment =
        line.isCentered ? MainAxisAlignment.center : MainAxisAlignment.center;

    // Get line-specific padding
    final padding = MushafTheme.getLinePadding(line.lineType);

    // Add extra top spacing after surah transitions
    final effectivePadding = isAfterSurahTransition && !isFirstLine
        ? padding.copyWith(
            top: padding.top + MushafTheme.surahTransitionSpacing)
        : padding;

    // Build the row of words with enhanced word widgets
    Widget lineContent = Container(
      width: double.infinity,
      padding: effectivePadding,
      decoration: _getLineDecoration(),
      child: Row(
        mainAxisAlignment: alignment,
        textDirection: TextDirection.rtl,
        children: line.words.map((word) {
          final isMarked = markedWordIds.contains(word.id);
          return MushafWordFactory.build(
            word: word,
            mode: renderingMode,
            colorMode: colorMode,
            isMarked: isMarked,
            onTap: () => onWordTap(word.id),
            lineType: line.lineType,
            onLetterTap: onLetterTap,
            customColors: getCustomColors?.call(word.id),
          );
        }).toList(),
      ),
    );

    // Add subtle divider after surah name lines
    if (line.isSurahName) {
      lineContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          lineContent,
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 48.0),
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  MushafTheme.surahNameColor.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      );
    }

    return lineContent;
  }

  /// Get decoration based on line type
  BoxDecoration? _getLineDecoration() {
    if (line.isSurahName) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MushafTheme.surahNameColor.withValues(alpha: 0.05),
            Colors.transparent,
            MushafTheme.surahNameColor.withValues(alpha: 0.05),
          ],
        ),
      );
    }
    return null;
  }
}

/// Widget for displaying a complete Mushaf page with 15 lines
/// Enhanced with responsive design and visual hierarchy
class MushafPageWidget extends StatelessWidget {
  final QuranPage page;
  final Set<int> markedWordIds;
  final Function(int wordId) onWordTap;
  final RenderingMode renderingMode;
  final ColorMode colorMode;

  /// Optional callback when a letter is tapped (for custom coloring)
  final LetterTapCallback? onLetterTap;

  /// Function to get custom colors for a word (returns null if no custom colors)
  final List<Color?>? Function(int wordId)? getCustomColors;

  const MushafPageWidget({
    super.key,
    required this.page,
    required this.markedWordIds,
    required this.onWordTap,
    this.renderingMode = RenderingMode.textspan,
    this.colorMode = ColorMode.none,
    this.onLetterTap,
    this.getCustomColors,
  });

  @override
  Widget build(BuildContext context) {
    // Get responsive sizing based on screen dimensions
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    // Calculate adaptive font scale (clamped between 0.85 and 1.15)
    final baseScale = (screenHeight / 800).clamp(0.85, 1.15);
    final widthScale = (screenWidth / 400).clamp(0.9, 1.1);
    final scaleFactor = (baseScale * widthScale).clamp(0.85, 1.15);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: MushafTheme.pageBackgroundColor,
        child: Column(
          children: [
            // Decorative top border
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MushafTheme.surahNameColor.withValues(alpha: 0.0),
                    MushafTheme.surahNameColor.withValues(alpha: 0.3),
                    MushafTheme.surahNameColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            // Main content area with lines
            Expanded(
              child: MediaQuery(
                // Apply responsive text scaling
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(scaleFactor),
                ),
                child: _buildLinesList(),
              ),
            ),
            // Decorative element above page number
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 64.0, vertical: 4.0),
              height: 1,
              color: MushafTheme.dividerColor,
            ),
            // Page number at bottom
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: MushafTheme.pageBackgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${page.pageNumber}',
                style: TextStyle(
                  fontSize: 14 * scaleFactor,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                  fontFamilyFallback: MushafTheme.arabicFontFallbacks,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  /// Build the list of lines with proper spacing
  Widget _buildLinesList() {
    final List<Widget> lineWidgets = [];
    bool wasPreviousSurahTransition = false;

    for (int i = 0; i < page.lines.length; i++) {
      final line = page.lines[i];

      // Check if this line follows a surah transition
      final isAfterTransition = wasPreviousSurahTransition;

      // Update transition tracking for next iteration
      wasPreviousSurahTransition = MushafTheme.isSurahTransition(line.lineType);

      lineWidgets.add(
        MushafLineWidget(
          line: line,
          markedWordIds: markedWordIds,
          onWordTap: onWordTap,
          isFirstLine: i == 0,
          isAfterSurahTransition: isAfterTransition,
          renderingMode: renderingMode,
          colorMode: colorMode,
          onLetterTap: onLetterTap,
          getCustomColors: getCustomColors,
        ),
      );
    }

    // Use spaceEvenly for consistent vertical distribution
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: lineWidgets,
    );
  }
}

/// Legacy widgets - kept for compatibility but not used in the new implementation

class MushafPage extends StatelessWidget {
  final int pageNumber;
  final List<Ayah> ayahs;

  const MushafPage({super.key, required this.pageNumber, required this.ayahs});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class AyahWidget extends StatelessWidget {
  final Ayah ayah;
  final bool showIndopak;

  const AyahWidget({super.key, required this.ayah, this.showIndopak = false});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class WordWidget extends StatelessWidget {
  final Word word;
  final VoidCallback? onTap;

  const WordWidget({super.key, required this.word, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class BismillahWidget extends StatelessWidget {
  const BismillahWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class SurahHeader extends StatelessWidget {
  final Surah surah;

  const SurahHeader({super.key, required this.surah});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
