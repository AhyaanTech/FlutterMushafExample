import 'package:flutter/material.dart';
import '../../models/quran_page.dart';
import '../../services/page_repository.dart';

class MushafProvider extends ChangeNotifier {
  final PageRepository _repository = PageRepository();
  
  int _currentPage = 1;
  QuranPage? _currentPageData;
  bool _isLoading = false;
  String? _error;
  
  int get currentPage => _currentPage;
  QuranPage? get currentPageData => _currentPageData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  MushafProvider() {
    loadPage(_currentPage);
  }
  
  Future<void> loadPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > 604) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _currentPage = pageNumber;
      _currentPageData = await _repository.getPage(pageNumber);
      
      // Preload adjacent pages
      _preloadAdjacentPages(pageNumber);
    } catch (e) {
      _error = 'Failed to load page: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _preloadAdjacentPages(int pageNumber) {
    // Preload next and previous pages in background
    if (pageNumber > 1) {
      _repository.preloadPage(pageNumber - 1);
    }
    if (pageNumber < 604) {
      _repository.preloadPage(pageNumber + 1);
    }
  }
  
  void nextPage() {
    if (_currentPage < 604) {
      loadPage(_currentPage + 1);
    }
  }
  
  void previousPage() {
    if (_currentPage > 1) {
      loadPage(_currentPage - 1);
    }
  }
  
  void goToPage(int pageNumber) {
    loadPage(pageNumber);
  }
}
