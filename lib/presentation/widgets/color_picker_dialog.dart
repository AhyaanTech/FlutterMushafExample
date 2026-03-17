import 'package:flutter/material.dart';

class ColorPickerDialog extends StatelessWidget {
  final Color? currentColor;
  final Function(Color?) onColorSelected;
  
  const ColorPickerDialog({
    super.key,
    this.currentColor,
    required this.onColorSelected,
  });
  
  static const List<Color> _presetColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];
  
  static Future<void> show(BuildContext context, {
    Color? currentColor,
    required Function(Color?) onColorSelected,
  }) {
    print('ColorPicker: Opening bottom sheet');
    return showModalBottomSheet(
      context: context,
      builder: (context) => ColorPickerDialog(
        currentColor: currentColor,
        onColorSelected: (color) {
          print('ColorPicker: Color picked: $color');
          Navigator.pop(context);
          print('ColorPicker: Calling onColorSelected');
          onColorSelected(color);
        },
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select Color',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _presetColors.map((color) => _buildColorOption(color)).toList(),
          ),
          const SizedBox(height: 16),
          if (currentColor != null)
            TextButton.icon(
              onPressed: () => onColorSelected(null),
              icon: const Icon(Icons.clear),
              label: const Text('Clear Color'),
            ),
        ],
      ),
    );
  }
  
  Widget _buildColorOption(Color color) {
    final isSelected = currentColor != null && 
        currentColor!.r == color.r && 
        currentColor!.g == color.g && 
        currentColor!.b == color.b;
    
    return GestureDetector(
      onTap: () => onColorSelected(color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              )
            : null,
      ),
    );
  }
}
