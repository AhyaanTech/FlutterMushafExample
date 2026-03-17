import 'quran_letter.dart';

class QuranWord {
  final int id;
  final String text;
  final String verseKey;
  final String lineType;
  final bool isCentered;
  List<QuranLetter>? letters;

  QuranWord({
    required this.id,
    required this.text,
    required this.verseKey,
    this.lineType = 'ayah',
    this.isCentered = false,
    this.letters,
  });
}
