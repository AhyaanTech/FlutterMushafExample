import '../models/quran_page.dart';
import '../models/quran_line.dart';
import '../models/quran_word.dart';
import 'database_helper.dart';

class PageRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Map<int, QuranPage> _pageCache = {};
  static const int _maxCacheSize = 5;
  final List<int> _cacheOrder = [];
  
  Future<QuranPage?> getPage(int pageNumber) async {
    // Check cache first
    if (_pageCache.containsKey(pageNumber)) {
      _updateCacheOrder(pageNumber);
      return _pageCache[pageNumber];
    }
    
    // Fetch from database
    final pageData = await _dbHelper.getPageData(pageNumber);
    if (pageData.isEmpty) return null;
    
    // Build page structure
    final lines = await _buildLines(pageData);
    final page = QuranPage(pageNumber: pageNumber, lines: lines);
    
    // Add to cache
    _addToCache(pageNumber, page);
    
    return page;
  }
  
  Future<List<QuranLine>> _buildLines(List<Map<String, dynamic>> pageData) async {
    final Map<int, List<QuranWord>> lineWords = {};
    
    for (final row in pageData) {
      final lineNumber = row['line_number'] as int;
      
      if (!lineWords.containsKey(lineNumber)) {
        lineWords[lineNumber] = [];
      }
      
      final word = QuranWord(
        id: row['word_id'] as int,
        text: row['arabic_text'] as String? ?? '',
        verseKey: row['verse_key'] as String? ?? '',
        lineType: row['line_type'] as String? ?? 'ayah',
        isCentered: (row['is_centered'] as int?) == 1,
      );
      
      // Load letters for this word
      word.letters = await _dbHelper.getWordLetters(word.id);
      
      lineWords[lineNumber]!.add(word);
    }
    
    // Build lines
    final lines = <QuranLine>[];
    final sortedLineNumbers = lineWords.keys.toList()..sort();
    
    for (final lineNumber in sortedLineNumbers) {
      final words = lineWords[lineNumber]!;
      if (words.isNotEmpty) {
        lines.add(QuranLine(
          lineNumber: lineNumber,
          lineType: words.first.lineType,
          isCentered: words.first.isCentered,
          words: words,
        ));
      }
    }
    
    return lines;
  }
  
  void _addToCache(int pageNumber, QuranPage page) {
    // Evict oldest if cache is full
    if (_pageCache.length >= _maxCacheSize && !_pageCache.containsKey(pageNumber)) {
      final oldest = _cacheOrder.removeAt(0);
      _pageCache.remove(oldest);
    }
    
    _pageCache[pageNumber] = page;
    _updateCacheOrder(pageNumber);
  }
  
  void _updateCacheOrder(int pageNumber) {
    _cacheOrder.remove(pageNumber);
    _cacheOrder.add(pageNumber);
  }
  
  void clearCache() {
    _pageCache.clear();
    _cacheOrder.clear();
  }
  
  Future<void> preloadPage(int pageNumber) async {
    if (!_pageCache.containsKey(pageNumber)) {
      await getPage(pageNumber);
    }
  }
}
