import 'package:flutter/material.dart';
import '../../models/quran_letter.dart';

class LetterSpanWidget extends StatelessWidget {
  final QuranLetter letter;
  final Color? customColor;
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;
  final bool isNonConnecting;
  
  const LetterSpanWidget({
    super.key,
    required this.letter,
    this.customColor,
    this.onTap,
    this.isFirst = false,
    this.isLast = false,
    this.isNonConnecting = false,
  });
  
  // Non-connecting Arabic letters
  static const Set<String> _nonConnectingLetters = {
    'ا', 'أ', 'إ', 'آ', 'د', 'ذ', 'ر', 'ز', 'و'
  };
  
  static bool isNonConnectingLetter(String letter) {
    return _nonConnectingLetters.contains(letter);
  }
  
  String _applyZWJ() {
    final base = letter.letterWithDiacritics;
    
    if (isNonConnecting) {
      // Non-connecting letters don't need ZWJ
      return base;
    }
    
    if (isFirst && isLast) {
      // Isolated
      return base;
    } else if (isFirst) {
      // Initial: letter + ZWJ (connect to next)
      return '$base\u200D';
    } else if (isLast) {
      // Final: ZWJ + letter (connect to previous)
      return '\u200D$base';
    } else {
      // Medial: ZWJ + letter + ZWJ (connect both sides)
      return '\u200D$base\u200D';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // This widget is now just a wrapper - the actual rendering happens
    // in MushafWordWidget with RichText
    final text = _applyZWJ();
    
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 22,
          fontFamily: 'UthmanicHafs',
          fontFamilyFallback: const [
            '.SF Arabic',
            'Roboto',
            'Arial',
          ],
          color: customColor ?? const Color(0xFF1A1A1A),
        ),
      ),
    );
  }
}
