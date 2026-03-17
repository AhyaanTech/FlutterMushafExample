import 'quran_word.dart';

class QuranLine {
  final int lineNumber;
  final String lineType;
  final bool isCentered;
  final List<QuranWord> words;

  QuranLine({
    required this.lineNumber,
    required this.lineType,
    required this.isCentered,
    required this.words,
  });
}
