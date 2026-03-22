import 'package:flutter/material.dart';

class MushafProvider extends ChangeNotifier {
  int _currentPage = 1;
  
  int get currentPage => _currentPage;
  
  void nextPage() {
    if (_currentPage < 604) {
      _currentPage++;
      notifyListeners();
    }
  }
  
  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
    }
  }
  
  void goToPage(int pageNumber) {
    if (pageNumber >= 1 && pageNumber <= 604) {
      _currentPage = pageNumber;
      notifyListeners();
    }
  }
}
