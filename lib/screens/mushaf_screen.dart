/// Mushaf Screen - Main screen for displaying the Quran with interactive features
///
/// This screen displays the Mushaf using a PageView with 604 pages.
/// Each page contains 15 lines of text with block-aligned words.
///
/// Features:
/// - Swipe left/right to navigate between pages (RTL behavior)
/// - Tap any word to mark/unmark it for memorization (black ↔ red)
/// - Jump to specific page via dialog
/// - Clear all marks
/// - Page caching for smooth performance
/// - Preloading of adjacent pages

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/mushaf_widgets.dart';
import '../widgets/color_picker_dialog.dart';
import '../services/database_helper.dart';
import '../models/quran_models.dart';
import '../models/tajweed_models.dart';

/// Main screen for displaying the Mushaf with interactive word marking
class MushafScreen extends StatefulWidget {
  const MushafScreen({super.key});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final PageController _pageController = PageController();

  // Track marked words in-memory (persists while app is running)
  // NOTE: This will be replaced by _customLetterColors in Phase 3
  final Set<int> _markedWordIds = <int>{};

  // Custom letter colors: wordId -> list of colors per letter index
  // Each index in the list corresponds to a letter in the word
  // null means no custom color for that letter
  final Map<int, List<Color?>> _customLetterColors = {};

  // Current page being displayed
  int _currentPage = 1;

  // Cache for loaded pages to avoid reloading
  final Map<int, QuranPage?> _pageCache = {};

  // Rendering and color mode state
  RenderingMode _renderingMode = RenderingMode.textspan;
  ColorMode _colorMode = ColorMode.none;

  @override
  void initState() {
    super.initState();
    // Start at page 1
    _currentPage = 1;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Toggle the marked state of a word
  void _toggleWordMark(int wordId) {
    setState(() {
      if (_markedWordIds.contains(wordId)) {
        _markedWordIds.remove(wordId);
      } else {
        _markedWordIds.add(wordId);
      }
    });
  }

  /// Clear all marks
  void _clearAllMarks() {
    setState(() {
      _markedWordIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم مسح جميع العلامات / All marks cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // Custom Letter Color Management (Phase 1 Implementation)
  // ============================================================

  /// Sets a custom color for a specific letter in a word
  ///
  /// Parameters:
  /// - [wordId]: The unique ID of the word
  /// - [letterIndex]: The index of the letter within the word (0-based)
  /// - [color]: The color to apply to the letter
  void setLetterColor(int wordId, int letterIndex, Color color) {
    setState(() {
      // Initialize the list if this word hasn't been colored yet
      if (!_customLetterColors.containsKey(wordId)) {
        _customLetterColors[wordId] = <Color?>[];
      }

      final letterColors = _customLetterColors[wordId]!;

      // Extend the list if needed to accommodate the letter index
      while (letterColors.length <= letterIndex) {
        letterColors.add(null);
      }

      // Set the color for the specific letter
      letterColors[letterIndex] = color;
    });
  }

  /// Gets the custom color for a specific letter in a word
  ///
  /// Parameters:
  /// - [wordId]: The unique ID of the word
  /// - [letterIndex]: The index of the letter within the word (0-based)
  ///
  /// Returns the custom color if set, or null if no custom color is applied
  Color? getLetterColor(int wordId, int letterIndex) {
    final letterColors = _customLetterColors[wordId];
    if (letterColors == null ||
        letterIndex < 0 ||
        letterIndex >= letterColors.length) {
      return null;
    }
    return letterColors[letterIndex];
  }

  /// Gets all custom colors for a word
  ///
  /// Parameters:
  /// - [wordId]: The unique ID of the word
  ///
  /// Returns a list of colors per letter index, or null if no custom colors are set
  List<Color?>? getWordCustomColors(int wordId) {
    return _customLetterColors[wordId];
  }

  /// Clears a specific letter's custom color
  ///
  /// Parameters:
  /// - [wordId]: The unique ID of the word
  /// - [letterIndex]: The index of the letter within the word (0-based)
  void clearLetterColor(int wordId, int letterIndex) {
    final letterColors = _customLetterColors[wordId];
    if (letterColors != null &&
        letterIndex >= 0 &&
        letterIndex < letterColors.length) {
      setState(() {
        letterColors[letterIndex] = null;
      });
    }
  }

  /// Clears all custom colors for a specific word
  ///
  /// Parameters:
  /// - [wordId]: The unique ID of the word
  void clearWordCustomColors(int wordId) {
    setState(() {
      _customLetterColors.remove(wordId);
    });
  }

  /// Clears all custom colors for all words
  void clearAllCustomColors() {
    setState(() {
      _customLetterColors.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('تم مسح جميع الألوان المخصصة / All custom colors cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Checks if a word has any custom colors applied
  ///
  /// Parameters:
  /// - [wordId]: The unique ID of the word
  ///
  /// Returns true if the word has at least one custom colored letter
  bool hasCustomColors(int wordId) {
    final letterColors = _customLetterColors[wordId];
    if (letterColors == null) return false;
    return letterColors.any((color) => color != null);
  }

  // ============================================================
  // Letter Tap Handler for Custom Coloring (Phase 2 Implementation)
  // ============================================================

  /// Handles a letter tap event by showing the color picker dialog
  ///
  /// This method is called when a user taps a letter in custom color mode.
  /// It displays a color picker dialog and applies the selected color
  /// to the tapped letter.
  ///
  /// Parameters:
  /// - [wordId]: The unique ID of the word containing the letter
  /// - [letterIndex]: The index of the letter within the word (0-based)
  Future<void> _onLetterTap(int wordId, int letterIndex) async {
    // Get the current color for this letter (if any)
    final currentColor = getLetterColor(wordId, letterIndex);

    // Get the letter character for the preview
    // Note: We'd need to fetch the word data to get the actual letter,
    // but for now we'll use a placeholder
    final letterChar = 'ح'; // Arabic letter Ha as placeholder

    // Show the color picker dialog
    final result = await showColorPickerDialog(
      context: context,
      letter: letterChar,
      currentColor: currentColor,
    );

    // Handle the result
    if (result != null) {
      if (result.clearRequested) {
        // Clear the color for this letter
        clearLetterColor(wordId, letterIndex);
      } else if (result.color != null) {
        // Apply the selected color
        setLetterColor(wordId, letterIndex, result.color!);
      }
    }
  }

  /// Get a Quran page (from cache or database)
  Future<QuranPage?> _getQuranPage(int pageNumber) async {
    // Return from cache if available
    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber];
    }

    // Load from database
    final page = await _dbHelper.getQuranPage(pageNumber);
    _pageCache[pageNumber] = page;
    return page;
  }

  /// Handle page changes in PageView
  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index + 1; // Pages are 1-indexed
    });

    // Preload adjacent pages for smoother swiping
    _preloadAdjacentPages(_currentPage);
  }

  /// Preload pages before and after the current page
  void _preloadAdjacentPages(int pageNumber) async {
    // Preload next page
    if (pageNumber < 604 && !_pageCache.containsKey(pageNumber + 1)) {
      final nextPage = await _dbHelper.getQuranPage(pageNumber + 1);
      if (mounted) {
        setState(() {
          _pageCache[pageNumber + 1] = nextPage;
        });
      }
    }

    // Preload previous page
    if (pageNumber > 1 && !_pageCache.containsKey(pageNumber - 1)) {
      final prevPage = await _dbHelper.getQuranPage(pageNumber - 1);
      if (mounted) {
        setState(() {
          _pageCache[pageNumber - 1] = prevPage;
        });
      }
    }
  }

  /// Navigate to a specific page
  void _jumpToPage() {
    showDialog(
      context: context,
      builder: (context) => _JumpToPageDialog(
        currentPage: _currentPage,
        onJump: (pageNumber) {
          if (pageNumber >= 1 && pageNumber <= 604) {
            _pageController.animateToPage(
              pageNumber - 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
      ),
    );
  }

  /// Go to next page
  void _goToNextPage() {
    if (_currentPage < 604) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Go to previous page
  void _goToPreviousPage() {
    if (_currentPage > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('صفحة $_currentPage'),
        centerTitle: true,
        backgroundColor: Colors.green.shade50,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          // Rendering mode toggle
          PopupMenuButton<RenderingMode>(
            icon: const Icon(Icons.compare),
            tooltip: 'وضع العرض / Rendering mode',
            onSelected: (mode) {
              setState(() {
                _renderingMode = mode;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: RenderingMode.textspan,
                child: Row(
                  children: [
                    Icon(
                      _renderingMode == RenderingMode.textspan
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('TextSpan (Flutter Text)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: RenderingMode.glyph,
                child: Row(
                  children: [
                    Icon(
                      _renderingMode == RenderingMode.glyph
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Glyph (CustomPainter)'),
                  ],
                ),
              ),
            ],
          ),
          // Color mode selector
          PopupMenuButton<ColorMode>(
            icon: const Icon(Icons.color_lens),
            tooltip: 'وضع الألوان / Color mode',
            onSelected: (mode) {
              setState(() {
                _colorMode = mode;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ColorMode.none,
                child: Row(
                  children: [
                    Icon(
                      _colorMode == ColorMode.none
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Normal'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ColorMode.tajweed,
                child: Row(
                  children: [
                    Icon(
                      _colorMode == ColorMode.tajweed
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Tajweed'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ColorMode.mistakes,
                child: Row(
                  children: [
                    Icon(
                      _colorMode == ColorMode.mistakes
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Mistakes'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ColorMode.custom,
                child: Row(
                  children: [
                    Icon(
                      _colorMode == ColorMode.custom
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Custom'),
                  ],
                ),
              ),
            ],
          ),
          // Clear all marks button
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'مسح جميع العلامات / Clear all marks',
            onPressed: _markedWordIds.isEmpty ? null : _clearAllMarks,
          ),
          // Clear all custom colors button (only visible in custom mode)
          if (_colorMode == ColorMode.custom)
            IconButton(
              icon: const Icon(Icons.format_color_reset),
              tooltip: 'مسح جميع الألوان المخصصة / Clear all custom colors',
              onPressed:
                  _customLetterColors.isEmpty ? null : clearAllCustomColors,
            ),
          // Jump to page button
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'الانتقال إلى صفحة / Jump to page',
            onPressed: _jumpToPage,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        reverse: true, // RTL: swipe left for next page (next in RTL)
        itemCount: 604,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final pageNumber = index + 1;
          return FutureBuilder<QuranPage?>(
            future: _getQuranPage(pageNumber),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('خطأ في تحميل الصفحة $pageNumber'),
                      Text('Error loading page',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                );
              }

              final page = snapshot.data;
              if (page == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.orange, size: 48),
                      const SizedBox(height: 16),
                      Text('لا توجد بيانات للصفحة $pageNumber'),
                      Text('No data for page',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                );
              }

              return MushafPageWidget(
                page: page,
                markedWordIds: _markedWordIds,
                onWordTap: _toggleWordMark,
                renderingMode: _renderingMode,
                colorMode: _colorMode,
                onLetterTap:
                    _colorMode == ColorMode.custom ? _onLetterTap : null,
                getCustomColors: getWordCustomColors,
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        height: 60,
        color: Colors.green.shade50,
        elevation: 1,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Previous page button
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              tooltip: 'الصفحة السابقة / Previous page',
              onPressed: _currentPage > 1 ? _goToPreviousPage : null,
            ),
            // Page indicator
            InkWell(
              onTap: _jumpToPage,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  '$_currentPage / 604',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Next page button
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              tooltip: 'الصفحة التالية / Next page',
              onPressed: _currentPage < 604 ? _goToNextPage : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for jumping to a specific page
class _JumpToPageDialog extends StatefulWidget {
  final int currentPage;
  final Function(int pageNumber) onJump;

  const _JumpToPageDialog({
    required this.currentPage,
    required this.onJump,
  });

  @override
  State<_JumpToPageDialog> createState() => _JumpToPageDialogState();
}

class _JumpToPageDialogState extends State<_JumpToPageDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentPage.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('الانتقال إلى صفحة'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'رقم الصفحة (1-604)',
          border: OutlineInputBorder(),
          hintText: 'أدخل رقم الصفحة',
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        onSubmitted: (value) {
          final pageNumber = int.tryParse(value);
          if (pageNumber != null && pageNumber >= 1 && pageNumber <= 604) {
            Navigator.of(context).pop();
            widget.onJump(pageNumber);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            final pageNumber = int.tryParse(_controller.text);
            if (pageNumber != null && pageNumber >= 1 && pageNumber <= 604) {
              Navigator.of(context).pop();
              widget.onJump(pageNumber);
            }
          },
          child: const Text('انتقال'),
        ),
      ],
    );
  }
}
