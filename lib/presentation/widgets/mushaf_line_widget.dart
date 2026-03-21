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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: line.isCentered
            ? _buildCenteredLine()
            : _buildJustifiedLine(),
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
        ...line.words.map((word) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: MushafWordWidget(
            word: word,
            letterColors: letterColors,
            onTap: onWordTap != null ? () => onWordTap!(word) : null,
            font: font,
          ),
        )),
      ],
    );
  }
}
