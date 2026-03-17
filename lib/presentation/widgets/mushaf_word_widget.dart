import 'package:flutter/material.dart';
import '../../models/quran_word.dart';
import '../../models/quran_letter.dart';

class MushafWordWidget extends StatelessWidget {
  final QuranWord word;
  final Map<String, Color> letterColors;
  final VoidCallback? onTap;
  
  const MushafWordWidget({
    super.key,
    required this.word,
    required this.letterColors,
    this.onTap,
  });
  
  Color? _getLetterColor(int letterIndex) {
    final key = '${word.id}_$letterIndex';
    final color = letterColors[key];
    print('Getting color for word ${word.id}, letter $letterIndex: key=$key, color=$color');
    return color;
  }
  
  String _getLetterText(QuranLetter letter, bool isFirst, bool isLast) {
    // Just return the letter with diacritics - let the font handle shaping
    return letter.letterWithDiacritics;
  }
  
  @override
  Widget build(BuildContext context) {
    final letters = word.letters;
    
    if (letters == null || letters.isEmpty) {
      // Fallback to whole word
      return GestureDetector(
        onTap: onTap,
        child: Text(
          word.text,
          style: const TextStyle(
            fontSize: 22,
            fontFamily: 'UthmanicHafs',
            fontFamilyFallback: ['.SF Arabic', 'Roboto', 'Arial'],
            color: Color(0xFF1A1A1A),
          ),
        ),
      );
    }
    
    // Build the word as a single RichText with TextSpans
    // This allows Arabic shaping to work properly
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        text: TextSpan(
          children: _buildLetterSpans(letters),
        ),
      ),
    );
  }
  
  List<TextSpan> _buildLetterSpans(List<QuranLetter> letters) {
    final spans = <TextSpan>[];
    
    for (int i = 0; i < letters.length; i++) {
      final letter = letters[i];
      final isFirst = i == 0;
      final isLast = i == letters.length - 1;
      
      final text = _getLetterText(letter, isFirst, isLast);
      final color = _getLetterColor(i);
      
      spans.add(
        TextSpan(
          text: text,
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'UthmanicHafs',
            fontFamilyFallback: const [
              '.SF Arabic',
              'Roboto',
              'Arial',
            ],
            color: color ?? const Color(0xFF1A1A1A),
          ),
        ),
      );
    }
    
    return spans;
  }
}
