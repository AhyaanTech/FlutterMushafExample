import 'package:flutter/material.dart';
import '../../models/quran_word.dart';
import '../../models/quran_letter.dart';
import 'color_picker_dialog.dart';

class LetterPickerDialog extends StatefulWidget {
  final QuranWord word;
  final Map<String, Color> letterColors;
  final Function(int wordId, int letterIndex, Color? color) onColorSelected;
  
  const LetterPickerDialog({
    super.key,
    required this.word,
    required this.letterColors,
    required this.onColorSelected,
  });
  
  static Future<void> show(
    BuildContext context, {
    required QuranWord word,
    required Map<String, Color> letterColors,
    required Function(int wordId, int letterIndex, Color? color) onColorSelected,
  }) {
    return showDialog(
      context: context,
      builder: (context) => LetterPickerDialog(
        word: word,
        letterColors: letterColors,
        onColorSelected: onColorSelected,
      ),
    );
  }
  
  @override
  State<LetterPickerDialog> createState() => _LetterPickerDialogState();
}

class _LetterPickerDialogState extends State<LetterPickerDialog> {
  int? _selectedLetterIndex;
  
  Color? _getLetterColor(int letterIndex) {
    final key = '${widget.word.id}_$letterIndex';
    return widget.letterColors[key];
  }
  
  @override
  Widget build(BuildContext context) {
    final letters = widget.word.letters;
    
    if (letters == null || letters.isEmpty) {
      return AlertDialog(
        title: const Text('Error'),
        content: const Text('No letter data available'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }
    
    print('LetterPickerDialog build: _selectedLetterIndex=$_selectedLetterIndex');
    
    return AlertDialog(
      title: const Text(
        'Color Letters',
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Word display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.word.text,
                style: const TextStyle(
                  fontSize: 28,
                  fontFamily: 'UthmanicHafs',
                  fontFamilyFallback: ['.SF Arabic', 'Roboto', 'Arial'],
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select a letter to color:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            // Letter grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: letters.asMap().entries.map((entry) {
                final index = entry.key;
                final letter = entry.value;
                final isSelected = _selectedLetterIndex == index;
                final currentColor = _getLetterColor(index);
                
                return _buildLetterButton(
                  letter: letter,
                  index: index,
                  isSelected: isSelected,
                  currentColor: currentColor,
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        if (_selectedLetterIndex != null)
          TextButton.icon(
            onPressed: () {
              widget.onColorSelected(
                widget.word.id,
                _selectedLetterIndex!,
                null,
              );
              setState(() {
                _selectedLetterIndex = null;
              });
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear Color'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
  
  Widget _buildLetterButton({
    required QuranLetter letter,
    required int index,
    required bool isSelected,
    required Color? currentColor,
  }) {
    return GestureDetector(
      onTap: () {
        print('Letter button tapped: index=$index, isSelected=$isSelected, _selectedLetterIndex=$_selectedLetterIndex');
        if (isSelected) {
          // Already selected, show color picker
          print('Opening color picker for letter $index');
          _showColorPicker(index);
        } else {
          // Select this letter
          print('Selecting letter $index (was $_selectedLetterIndex)');
          setState(() {
            _selectedLetterIndex = index;
          });
          print('After setState: _selectedLetterIndex=$_selectedLetterIndex');
        }
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.blue.shade100 
              : Colors.white,
          border: Border.all(
            color: isSelected 
                ? Colors.blue 
                : currentColor ?? Colors.grey.shade300,
            width: isSelected ? 3 : (currentColor != null ? 3 : 1),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            letter.letterWithDiacritics,
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'UthmanicHafs',
              fontFamilyFallback: const ['.SF Arabic', 'Roboto', 'Arial'],
              color: currentColor ?? Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
  
  void _showColorPicker(int letterIndex) {
    final currentColor = _getLetterColor(letterIndex);
    print('LetterPicker: Showing color picker for letter $letterIndex');
    
    ColorPickerDialog.show(
      context,
      currentColor: currentColor,
      onColorSelected: (color) {
        print('LetterPicker: Color selected: $color for letter $letterIndex');
        widget.onColorSelected(
          widget.word.id,
          letterIndex,
          color,
        );
        print('LetterPicker: Called widget.onColorSelected');
        setState(() {
          _selectedLetterIndex = null;
        });
      },
    );
  }
}
