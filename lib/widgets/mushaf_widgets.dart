import 'package:flutter/material.dart';
import '../models/quran_models.dart';

/// Widgets for displaying Mushaf content with interactive word marking

/// Widget for displaying a single Quran word with tap-to-mark functionality
class MushafWordWidget extends StatelessWidget {
  final QuranWord word;
  final bool isMarked;
  final VoidCallback onTap;

  const MushafWordWidget({
    super.key,
    required this.word,
    required this.isMarked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: BoxDecoration(
          color:
              isMarked ? Colors.red.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          word.text,
          style: TextStyle(
            fontSize: 28,
            fontFamily: 'Amiri',
            fontFamilyFallback: const [
              '.SF Arabic', // iOS/macOS Arabic font
              'Roboto', // Android (has Arabic support)
              'Arial', // Windows/macOS fallback
              'Noto Sans Arabic', // Common system font
              'Scheherazade', // Alternative custom font if available
            ],
            fontWeight: FontWeight.normal,
            color: isMarked ? Colors.red : Colors.black,
            height: 1.5,
          ),
          textAlign: word.isCentered ? TextAlign.center : TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}

/// Widget for displaying a line of Quran text
class MushafLineWidget extends StatelessWidget {
  final QuranLine line;
  final Set<int> markedWordIds;
  final Function(int wordId) onWordTap;

  const MushafLineWidget({
    super.key,
    required this.line,
    required this.markedWordIds,
    required this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the main axis alignment based on line type
    final MainAxisAlignment alignment = line.isCentered
        ? MainAxisAlignment.center
        : MainAxisAlignment.spaceBetween;

    // Build the row of words
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: alignment,
        textDirection: TextDirection.rtl,
        children: line.words.map((word) {
          final isMarked = markedWordIds.contains(word.id);
          return MushafWordWidget(
            word: word,
            isMarked: isMarked,
            onTap: () => onWordTap(word.id),
          );
        }).toList(),
      ),
    );
  }
}

/// Widget for displaying a complete Mushaf page with 15 lines
class MushafPageWidget extends StatelessWidget {
  final QuranPage page;
  final Set<int> markedWordIds;
  final Function(int wordId) onWordTap;

  const MushafPageWidget({
    super.key,
    required this.page,
    required this.markedWordIds,
    required this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Main content area with lines
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: page.lines.map((line) {
                  return MushafLineWidget(
                    line: line,
                    markedWordIds: markedWordIds,
                    onWordTap: onWordTap,
                  );
                }).toList(),
              ),
            ),
            // Page number at bottom
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${page.pageNumber}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
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
