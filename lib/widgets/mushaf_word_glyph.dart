import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../models/tajweed_models.dart';
import '../services/database_helper.dart';
import 'mushaf_widgets.dart';
import 'mushaf_word_factory.dart' show LetterTapCallback;

/// Glyph-based word widget for Tajweed letter coloring using CustomPainter
///
/// This widget uses Flutter's CustomPainter with positioned glyphs to render
/// each character at its precise (x, y) position for pixel-perfect Mushaf
/// reproduction. It fetches glyph data from the database and gracefully falls
/// back to plain text if the V4 glyph data is not available.
///
/// Usage:
/// ```dart
/// MushafWordGlyph(
///   word: quranWord,
///   colorMode: ColorMode.tajweed,
///   isMarked: false,
///   onTap: () => handleWordTap(word.id),
///   lineType: 'ayah',
/// )
/// ```
class MushafWordGlyph extends StatefulWidget {
  /// The Quran word data containing id, text, and metadata
  final QuranWord word;

  /// The color mode for rendering (none, tajweed, or mistakes)
  final ColorMode colorMode;

  /// Whether this word is currently marked by the user
  final bool isMarked;

  /// Callback when the word is tapped
  final VoidCallback onTap;

  /// The type of line this word belongs to ('surah_name', 'basmallah', 'ayah')
  final String lineType;

  /// Optional callback when a specific letter is tapped (for custom coloring)
  /// Note: Glyph mode has limited support - taps are detected at word level
  final LetterTapCallback? onLetterTap;

  /// Optional list of custom colors per letter index (for custom mode)
  /// Each index corresponds to a letter in the word; null means no custom color
  final List<Color?>? customColors;

  const MushafWordGlyph({
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
  State<MushafWordGlyph> createState() => _MushafWordGlyphState();
}

class _MushafWordGlyphState extends State<MushafWordGlyph> {
  /// Future that fetches glyph data for this word
  late Future<List<GlyphData>> _glyphDataFuture;

  @override
  void initState() {
    super.initState();
    _glyphDataFuture = _fetchGlyphData();
  }

  @override
  void didUpdateWidget(MushafWordGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refetch if word ID changes
    if (oldWidget.word.id != widget.word.id) {
      _glyphDataFuture = _fetchGlyphData();
    }
  }

  /// Fetches glyph data from the database
  Future<List<GlyphData>> _fetchGlyphData() async {
    return DatabaseHelper().getWordGlyphs(widget.word.id);
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

  /// Gets the color for a specific glyph based on the current color mode
  /// and optional custom colors
  ///
  /// [glyph] - The glyph data containing character and position info
  /// [glyphIndex] - The index of the glyph in the word (maps to letter index)
  /// [customColor] - Optional override color (used by painter)
  Color _getGlyphColor(GlyphData glyph, int glyphIndex, {Color? customColor}) {
    switch (widget.colorMode) {
      case ColorMode.none:
        // No coloring - use default text color
        return _getDefaultTextColor();

      case ColorMode.tajweed:
        // Use glyph's defined color from the database
        return Color(glyph.colorValue);

      case ColorMode.mistakes:
        // Simulate mistake highlighting with random assignment
        // In a real implementation, this would come from user mistake data
        final isCorrect = _simulateMistakeCheck(glyph);
        return isCorrect ? Colors.green : Colors.red;

      case ColorMode.custom:
        // Custom color from parameter takes precedence
        if (customColor != null) {
          return customColor;
        }
        // Try to get custom color from the customColors list at this index
        if (widget.customColors != null &&
            glyphIndex >= 0 &&
            glyphIndex < widget.customColors!.length) {
          final color = widget.customColors![glyphIndex];
          if (color != null) {
            return color;
          }
        }
        // Fall back to default color if no custom color is set
        return _getDefaultTextColor();
    }
  }

  /// Simulates mistake checking for demonstration purposes
  /// In production, this would check actual user mistake history
  bool _simulateMistakeCheck(GlyphData glyph) {
    // Use a deterministic "random" based on glyph char and position
    // so the same glyph always shows the same result during the session
    final hash = (glyph.char.hashCode + glyph.x.toInt() + glyph.y.toInt()) % 10;
    return hash < 7; // 70% correct, 30% mistakes
  }

  /// Calculates the size needed to display all glyphs
  /// Based on the bounding box of all glyph positions plus padding
  Size _calculateGlyphSize(List<GlyphData> glyphs) {
    if (glyphs.isEmpty) {
      // Return default size for empty glyphs
      return Size(_getFontSize() * 2, _getFontSize() * 1.5);
    }

    // Find the bounds of all glyphs
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final glyph in glyphs) {
      final glyphWidth = glyph.width ?? _getFontSize() * 0.7;
      final glyphHeight = glyph.height ?? _getFontSize() * 1.2;

      minX = minX < glyph.x ? minX : glyph.x;
      minY = minY < glyph.y ? minY : glyph.y;
      maxX = maxX > glyph.x + glyphWidth ? maxX : glyph.x + glyphWidth;
      maxY = maxY > glyph.y + glyphHeight ? maxY : glyph.y + glyphHeight;
    }

    // Add padding for marked state overlay
    const padding = 8.0;
    final width = (maxX - minX) + (padding * 2);
    final height = (maxY - minY) + (padding * 2);

    return Size(width, height);
  }

  /// Builds the CustomPaint widget with the TajweedGlyphPainter
  Widget _buildGlyphPaint(List<GlyphData> glyphs) {
    final size = _calculateGlyphSize(glyphs);

    return CustomPaint(
      size: size,
      painter: TajweedGlyphPainter(
        glyphs: glyphs,
        colorMode: widget.colorMode,
        isMarked: widget.isMarked,
        lineType: widget.lineType,
        customColors: widget.customColors,
        getGlyphColor: _getGlyphColor,
        getFontSize: _getFontSize,
      ),
    );
  }

  /// Builds the word with custom color support
  ///
  /// In glyph mode, custom color support is limited - colors are applied to glyphs
  /// but tap detection is at word level rather than letter level
  Widget _buildWithCustomColorSupport(
      List<GlyphData> glyphs, BuildContext context) {
    // Check if we have custom colors for this word
    final hasCustomColors = widget.customColors?.any((c) => c != null) ?? false;

    if (widget.colorMode == ColorMode.custom &&
        hasCustomColors &&
        widget.onLetterTap != null) {
      // Apply custom colors to glyphs, with word-level tap interaction
      return GestureDetector(
        onTap: () {
          // Show snackbar about limited glyph mode support
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Glyph mode has limited custom color support. Use TextSpan mode for letter-level coloring.'),
              duration: Duration(seconds: 2),
            ),
          );
          widget.onTap();
        },
        child: _buildGlyphPaint(glyphs),
      );
    }
    return _buildGlyphPaint(glyphs);
  }

  /// Builds the fallback plain text widget when glyph data is not available
  Widget _buildPlainTextFallback() {
    final textStyle = MushafTheme.getTextStyle(
      widget.lineType,
      isMarked: widget.isMarked,
    ).copyWith(
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
    // Fall back to plain text on error
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
        child: FutureBuilder<List<GlyphData>>(
          future: _glyphDataFuture,
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

            if (!snapshot.hasData ||
                snapshot.data == null ||
                snapshot.data!.isEmpty) {
              // No glyph data available - use plain text fallback
              return _buildPlainTextFallback();
            }

            // Success - build glyph-based CustomPaint with custom color support
            return _buildWithCustomColorSupport(snapshot.data!, context);
          },
        ),
      ),
    );
  }
}

/// CustomPainter that renders positioned glyphs for pixel-perfect Mushaf reproduction
///
/// This painter iterates through each glyph and paints it at its precise (x, y)
/// position using TextPainter. Supports color modes for Tajweed rules and
/// mistake highlighting.
class TajweedGlyphPainter extends CustomPainter {
  /// List of glyph data to render
  final List<GlyphData> glyphs;

  /// Current color mode for rendering
  final ColorMode colorMode;

  /// Whether the word is marked
  final bool isMarked;

  /// Type of line for styling context
  final String lineType;

  /// Optional list of custom colors per letter index (for custom mode)
  final List<Color?>? customColors;

  /// Function to determine the color for each glyph
  /// Takes the glyph data and its index in the word
  final Color Function(GlyphData, int, {Color? customColor}) getGlyphColor;

  /// Function to get the base font size
  final double Function() getFontSize;

  /// Cache for text painters to avoid recreating them
  final Map<String, TextPainter> _textPainterCache = {};

  TajweedGlyphPainter({
    required this.glyphs,
    required this.colorMode,
    required this.isMarked,
    required this.lineType,
    this.customColors,
    required this.getGlyphColor,
    required this.getFontSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (glyphs.isEmpty) return;

    // Paint marked state overlay first (behind the text)
    if (isMarked) {
      _paintMarkedOverlay(canvas, size);
    }

    // Find the minimum x and y to normalize positions
    double minX = double.infinity;
    double minY = double.infinity;

    for (final glyph in glyphs) {
      minX = minX < glyph.x ? minX : glyph.x;
      minY = minY < glyph.y ? minY : glyph.y;
    }

    // Add padding offset
    const padding = 8.0;

    // Paint each glyph at its position with index tracking
    for (int i = 0; i < glyphs.length; i++) {
      _paintGlyph(canvas, glyphs[i], i, minX, minY, padding);
    }
  }

  /// Paints the marked state overlay as a semi-transparent rectangle
  void _paintMarkedOverlay(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(4),
    );

    canvas.drawRRect(rect, paint);

    // Draw border for marked state
    final borderPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(rect, borderPaint);
  }

  /// Paints a single glyph at its specified position
  void _paintGlyph(
    Canvas canvas,
    GlyphData glyph,
    int glyphIndex,
    double minX,
    double minY,
    double padding,
  ) {
    // Calculate the actual position with offset
    final x = glyph.x - minX + padding;
    final y = glyph.y - minY + padding;

    // Get custom color for this glyph index if available
    Color? customColor;
    if (customColors != null &&
        glyphIndex >= 0 &&
        glyphIndex < customColors!.length) {
      customColor = customColors![glyphIndex];
    }

    // Get the color for this glyph using index
    final color = getGlyphColor(glyph, glyphIndex, customColor: customColor);

    // Use glyph's font size if available, otherwise use base font size
    final fontSize = glyph.fontSize > 0 ? glyph.fontSize : getFontSize();

    // Create or retrieve cached text painter
    final cacheKey = '${glyph.char}_${color.toARGB32()}_${fontSize}_$lineType';
    TextPainter? textPainter = _textPainterCache[cacheKey];

    if (textPainter == null) {
      textPainter = TextPainter(
        text: TextSpan(
          text: glyph.char,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontFamily: 'UthmanicHafs',
            fontFamilyFallback: MushafTheme.arabicFontFallbacks,
            fontWeight:
                lineType == 'surah_name' ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
      );

      textPainter.layout();
      _textPainterCache[cacheKey] = textPainter;
    }

    // Paint the glyph at the calculated position
    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant TajweedGlyphPainter oldDelegate) {
    // Repaint if glyphs, color mode, or marked state changes
    if (oldDelegate.glyphs.length != glyphs.length) return true;
    if (oldDelegate.colorMode != colorMode) return true;
    if (oldDelegate.isMarked != isMarked) return true;
    if (oldDelegate.lineType != lineType) return true;

    // Check if custom colors changed
    if (oldDelegate.customColors != customColors) {
      // Check if any custom color actually changed
      if (oldDelegate.customColors == null || customColors == null) {
        return true;
      }
      if (oldDelegate.customColors!.length != customColors!.length) {
        return true;
      }
      for (int i = 0; i < customColors!.length; i++) {
        if (oldDelegate.customColors![i] != customColors![i]) {
          return true;
        }
      }
    }

    // Check if any glyph changed
    for (int i = 0; i < glyphs.length; i++) {
      if (oldDelegate.glyphs[i].char != glyphs[i].char ||
          oldDelegate.glyphs[i].x != glyphs[i].x ||
          oldDelegate.glyphs[i].y != glyphs[i].y ||
          oldDelegate.glyphs[i].colorHex != glyphs[i].colorHex) {
        return true;
      }
    }

    return false;
  }
}

/// Extension to provide additional functionality for glyph rendering
extension GlyphRenderingExtension on ColorMode {
  /// Checks if this color mode requires glyph-level data
  bool get requiresGlyphData {
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
