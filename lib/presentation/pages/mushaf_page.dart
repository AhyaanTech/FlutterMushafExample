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

class _MushafPageContent extends StatelessWidget {
  const _MushafPageContent();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        title: const Text('Mushaf'),
        backgroundColor: const Color(0xFFFDFCF8),
        elevation: 0,
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
          if (mushafProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (mushafProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${mushafProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => mushafProvider.loadPage(mushafProvider.currentPage),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          final page = mushafProvider.currentPageData;
          if (page == null) {
            return const Center(child: Text('No page data'));
          }
          
          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  reverse: true, // RTL
                  controller: PageController(
                    initialPage: mushafProvider.currentPage - 1,
                  ),
                  onPageChanged: (index) {
                    mushafProvider.goToPage(index + 1);
                  },
                  itemCount: 604,
                  itemBuilder: (context, index) {
                    final pageNum = index + 1;
                    
                    // Each page loads its own data
                    return Consumer<ColorProvider>(
                      builder: (context, colorProvider, child) {
                        return MushafPageView(
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
                        );
                      },
                    );
                  },
                ),
              ),
              _buildPageNavigation(context, mushafProvider),
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
  
  Widget _buildPageNavigation(BuildContext context, MushafProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFCF8),
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
