import 'package:flutter/material.dart';

enum QuranFont {
  uthmanicHafs('UthmanicHafs', 'Uthmanic Hafs'),
  digitalKhattIndoPak('DigitalKhattIndoPak', 'Digital Khatt Indopak');

  final String family;
  final String displayName;
  
  const QuranFont(this.family, this.displayName);
}

class ColorProvider extends ChangeNotifier {
  // Key format: "wordId_letterIndex"
  final Map<String, Color> _letterColors = {};
  
  // Font selection
  QuranFont _selectedFont = QuranFont.uthmanicHafs;
  
  Map<String, Color> get letterColors => Map.unmodifiable(_letterColors);
  
  QuranFont get selectedFont => _selectedFont;
  
  void setFont(QuranFont font) {
    _selectedFont = font;
    notifyListeners();
  }
  
  Color? getLetterColor(int wordId, int letterIndex) {
    final key = '${wordId}_$letterIndex';
    return _letterColors[key];
  }
  
  void setLetterColor(int wordId, int letterIndex, Color color) {
    final key = '${wordId}_$letterIndex';
    print('Setting color: wordId=$wordId, letterIndex=$letterIndex, key=$key, color=$color');
    _letterColors[key] = color;
    print('Current colors: $_letterColors');
    notifyListeners();
  }
  
  void clearLetterColor(int wordId, int letterIndex) {
    final key = '${wordId}_$letterIndex';
    _letterColors.remove(key);
    notifyListeners();
  }
  
  void clearAllColors() {
    _letterColors.clear();
    notifyListeners();
  }
  
  bool hasCustomColor(int wordId, int letterIndex) {
    final key = '${wordId}_$letterIndex';
    return _letterColors.containsKey(key);
  }
}
