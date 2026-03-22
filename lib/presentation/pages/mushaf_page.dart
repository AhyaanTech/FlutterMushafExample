import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mushaf_provider.dart';
import '../providers/color_provider.dart';
import '../../models/quran_word.dart';
import '../widgets/letter_picker_dialog.dart';
import '../widgets/mushaf_page_view.dart';

class MushafPage extends StatelessWidget {
  const MushafPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MushafProvider()),
        ChangeNotifierProvider(create: (_) => ColorProvider()),
      ],
      child: const _MushafPageContent(),
    );
  }
}

class _MushafPageContent extends StatefulWidget {
  const _MushafPageContent();
  
  @override
  State<_MushafPageContent> createState() => _MushafPageContentState();
}

class _MushafPageContentState extends State<_MushafPageContent> {
  late PageController _pageController;
  
  @override
  void initState() {
    super.initState();
    final initialPage = context.read<MushafProvider>().currentPage - 1;
    _pageController = PageController(initialPage: initialPage);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _syncControllerWithProvider(int page) {
    if (_pageController.hasClients && 
        _pageController.page?.round() != page - 1) {
      _pageController.animateToPage(
        page - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    const paperColor = Color(0xFFFDF6E3);
    const borderColor = Color(0xFFD4C5A0);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E6),
      appBar: AppBar(
        title: const Text('Mushaf', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: paperColor,
        elevation: 1,
        shadowColor: Colors.black12,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.font_download),
                onPressed: () {
                  _showFontPicker(context, context.read<ColorProvider>());
                },
                tooltip: 'Change font',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              context.read<ColorProvider>().clearAllColors();
            },
            tooltip: 'Clear all colors',
          ),
        ],
      ),
      body: Consumer2<MushafProvider, ColorProvider>(
        builder: (context, mushafProvider, colorProvider, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _syncControllerWithProvider(mushafProvider.currentPage);
          });
          
          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  reverse: true,
                  controller: _pageController,
                  onPageChanged: (index) {
                    mushafProvider.goToPage(index + 1);
                  },
                  itemCount: 604,
                  itemBuilder: (context, index) {
                    final pageNum = index + 1;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: paperColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor, width: 0.8),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              border: Border.all(color: borderColor, width: 0.8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: MushafPageView(
                                pageNumber: pageNum,
                                letterColors: colorProvider.letterColors,
                                font: colorProvider.selectedFont,
                                onWordTap: (word) {
                                  _showLetterPicker(
                                    context,
                                    word,
                                    colorProvider,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildPageNavigation(context, mushafProvider, paperColor),
            ],
          );
        },
      ),
    );
  }
  
  void _showFontPicker(BuildContext context, ColorProvider colorProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Font'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: QuranFont.values.map((font) => ListTile(
            title: Text(font.displayName),
            leading: Radio<QuranFont>(
              value: font,
              groupValue: colorProvider.selectedFont,
              onChanged: (value) {
                if (value != null) {
                  colorProvider.setFont(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            onTap: () {
              colorProvider.setFont(font);
              Navigator.of(context).pop();
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showLetterPicker(
    BuildContext context,
    QuranWord word,
    ColorProvider colorProvider,
  ) {
    LetterPickerDialog.show(
      context,
      word: word,
      letterColors: colorProvider.letterColors,
      onColorSelected: (wordId, letterIndex, color) {
        print('MushafPage: onColorSelected called with wordId=$wordId, letterIndex=$letterIndex, color=$color');
        if (color != null) {
          colorProvider.setLetterColor(wordId, letterIndex, color);
        } else {
          colorProvider.clearLetterColor(wordId, letterIndex);
        }
      },
    );
  }
  
  Widget _buildPageNavigation(BuildContext context, MushafProvider provider, Color paperColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: paperColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: provider.currentPage > 1 ? provider.previousPage : null,
            ),
            Text(
              'Page ${provider.currentPage}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: provider.currentPage < 604 ? provider.nextPage : null,
            ),
          ],
        ),
      ),
    );
  }
}
