import 'package:flutter/material.dart';
import '../../models/quran_line.dart';
import '../../models/quran_word.dart';
import '../providers/color_provider.dart';
import 'mushaf_word_widget.dart';

class MushafLineWidget extends StatelessWidget {
  final QuranLine line;
  final Map<String, Color> letterColors;
  final Function(QuranWord word)? onWordTap;
  final QuranFont font;
  
  const MushafLineWidget({
    super.key,
    required this.line,
    required this.letterColors,
    this.onWordTap,
    this.font = QuranFont.uthmanicHafs,
  });
  
  @override
  Widget build(BuildContext context) {
    if (line.lineType == 'surah_name') {
      return _buildSurahHeader();
    }
    
    if (line.lineType == 'basmallah') {
      return _buildBasmallah();
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: line.isCentered
            ? _buildCenteredLine()
            : _buildJustifiedLine(),
      ),
    );
  }

  Widget _buildSurahHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8DFB3), // A soft golden/beige for the header
        border: Border.all(color: const Color(0xFFD4C5A0), width: 2),
        borderRadius: BorderRadius.circular(6),
        image: const DecorationImage(
          image: AssetImage('assets/images/header_pattern.png'), // Will fail gracefully if missing
          repeat: ImageRepeat.repeat,
          opacity: 0.1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: line.words.map((word) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: MushafWordWidget(
            word: word,
            letterColors: letterColors,
            onTap: onWordTap != null ? () => onWordTap!(word) : null,
            font: font,
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildBasmallah() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('﴾', style: TextStyle(fontSize: 22, color: Color(0xFFC4B592))),
          const SizedBox(width: 12),
          ...line.words.map((word) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: MushafWordWidget(
              word: word,
              letterColors: letterColors,
              onTap: onWordTap != null ? () => onWordTap!(word) : null,
              font: font,
            ),
          )),
          const SizedBox(width: 12),
          const Text('﴿', style: TextStyle(fontSize: 22, color: Color(0xFFC4B592))),
        ],
      ),
    );
  }
  
  Widget _buildCenteredLine() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: line.words.map((word) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: MushafWordWidget(
          word: word,
          letterColors: letterColors,
          onTap: onWordTap != null ? () => onWordTap!(word) : null,
          font: font,
        ),
      )).toList(),
    );
  }

  Widget _buildJustifiedLine() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ...line.words.map((word) => MushafWordWidget(
          word: word,
          letterColors: letterColors,
          onTap: onWordTap != null ? () => onWordTap!(word) : null,
          font: font,
        )),
      ],
    );
  }
}
