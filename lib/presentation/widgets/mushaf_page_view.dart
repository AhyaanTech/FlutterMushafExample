import 'package:flutter/material.dart';
import '../../models/quran_page.dart';
import '../../services/page_repository.dart';
import '../providers/color_provider.dart';
import 'mushaf_line_widget.dart';
import '../../models/quran_word.dart';

class MushafPageView extends StatefulWidget {
  final int pageNumber;
  final Map<String, Color> letterColors;
  final Function(QuranWord word)? onWordTap;
  final QuranFont font;

  const MushafPageView({
    super.key,
    required this.pageNumber,
    required this.letterColors,
    this.onWordTap,
    this.font = QuranFont.uthmanicHafs,
  });
  
  @override
  State<MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends State<MushafPageView> {
  final PageRepository _repository = PageRepository();
  QuranPage? _page;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadPage();
  }
  
  @override
  void didUpdateWidget(MushafPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _loadPage();
    }
  }
  
  Future<void> _loadPage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final page = await _repository.getPage(widget.pageNumber);
      if (mounted) {
        setState(() {
          _page = page;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load page: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPage,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    final page = _page;
    if (page == null) {
      return const Center(child: Text('No page data'));
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: page.lines.map<Widget>((line) => MushafLineWidget(
          line: line,
          letterColors: widget.letterColors,
          onWordTap: widget.onWordTap,
          font: widget.font,
        )).toList(),
      ),
    );
  }
}
