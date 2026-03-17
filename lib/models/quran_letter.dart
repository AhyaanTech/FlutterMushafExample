class QuranLetter {
  final int wordId;
  final int letterIndex;
  final String baseLetter;
  final String letterWithDiacritics;
  final bool hasFatha;
  final bool hasKasra;
  final bool hasDamma;
  final bool hasSukun;
  final bool hasShadda;
  final bool hasMaddah;

  QuranLetter({
    required this.wordId,
    required this.letterIndex,
    required this.baseLetter,
    required this.letterWithDiacritics,
    this.hasFatha = false,
    this.hasKasra = false,
    this.hasDamma = false,
    this.hasSukun = false,
    this.hasShadda = false,
    this.hasMaddah = false,
  });

  factory QuranLetter.fromMap(Map<String, dynamic> map) {
    return QuranLetter(
      wordId: map['word_id'] as int,
      letterIndex: map['letter_index'] as int,
      baseLetter: map['base_letter'] as String,
      letterWithDiacritics: map['letter_with_diacritics'] as String,
      hasFatha: map['has_fatha'] == 1,
      hasKasra: map['has_kasra'] == 1,
      hasDamma: map['has_damma'] == 1,
      hasSukun: map['has_sukun'] == 1,
      hasShadda: map['has_shadda'] == 1,
      hasMaddah: map['has_maddah'] == 1,
    );
  }
}
