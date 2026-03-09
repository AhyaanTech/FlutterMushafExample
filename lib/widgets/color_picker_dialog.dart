import 'package:flutter/material.dart';

/// Result from the color picker dialog
///
/// Contains either a selected color or a clear action
class ColorPickerResult {
  /// The selected color, or null if clearing
  final Color? color;

  /// Whether the user requested to clear the color
  final bool clearRequested;

  const ColorPickerResult._({this.color, this.clearRequested = false});

  /// Create a result with a selected color
  factory ColorPickerResult.withColor(Color color) =>
      ColorPickerResult._(color: color);

  /// Create a result indicating the user wants to clear the color
  factory ColorPickerResult.clear() =>
      const ColorPickerResult._(clearRequested: true);

  /// Create a result indicating the user cancelled
  factory ColorPickerResult.cancel() => const ColorPickerResult._();
}

/// Predefined color option for the color picker
class PredefinedColor {
  final Color color;
  final String name;
  final String description;

  const PredefinedColor({
    required this.color,
    required this.name,
    required this.description,
  });
}

/// Predefined colors suitable for tajweed-style letter coloring
const List<PredefinedColor> kPredefinedColors = [
  PredefinedColor(
    color: Color(0xFFE53935), // Red
    name: 'Red',
    description: 'Hamzah, heavy letters',
  ),
  PredefinedColor(
    color: Color(0xFF1E88E5), // Blue
    name: 'Blue',
    description: 'Ghunnah, nasal sounds',
  ),
  PredefinedColor(
    color: Color(0xFF43A047), // Green
    name: 'Green',
    description: 'Correct pronunciation',
  ),
  PredefinedColor(
    color: Color(0xFFFB8C00), // Orange
    name: 'Orange',
    description: 'Idgham, merging',
  ),
  PredefinedColor(
    color: Color(0xFF8E24AA), // Purple
    name: 'Purple',
    description: 'Ikhfa, hiding',
  ),
  PredefinedColor(
    color: Color(0xFF00ACC1), // Teal
    name: 'Teal',
    description: 'Qalqalah, bouncing',
  ),
  PredefinedColor(
    color: Color(0xFFEC407A), // Pink
    name: 'Pink',
    description: 'Madd, prolongation',
  ),
  PredefinedColor(
    color: Color(0xFF3949AB), // Indigo
    name: 'Indigo',
    description: 'Iqlab, conversion',
  ),
  PredefinedColor(
    color: Color(0xFF6D4C41), // Brown
    name: 'Brown',
    description: 'Tafkhim, emphasis',
  ),
  PredefinedColor(
    color: Color(0xFF00897B), // Cyan
    name: 'Cyan',
    description: 'Tarqiq, thinning',
  ),
];

/// Shows a color picker dialog for selecting letter colors
///
/// This dialog provides:
/// - A grid of 10 predefined colors for quick selection
/// - A custom color picker button for more options
/// - A clear color button to remove custom coloring
/// - A preview of the selected letter with the chosen color
///
/// Returns a [ColorPickerResult] with the selected action
Future<ColorPickerResult?> showColorPickerDialog({
  required BuildContext context,
  required String letter,
  Color? currentColor,
}) async {
  return await showModalBottomSheet<ColorPickerResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ColorPickerDialogContent(
      letter: letter,
      currentColor: currentColor,
    ),
  );
}

/// The content of the color picker bottom sheet
class _ColorPickerDialogContent extends StatefulWidget {
  final String letter;
  final Color? currentColor;

  const _ColorPickerDialogContent({
    required this.letter,
    this.currentColor,
  });

  @override
  State<_ColorPickerDialogContent> createState() =>
      _ColorPickerDialogContentState();
}

class _ColorPickerDialogContentState extends State<_ColorPickerDialogContent> {
  Color? _selectedColor;
  bool _showCustomPicker = false;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: AnimatedCrossFade(
        firstChild: _buildPredefinedColorsView(),
        secondChild: _buildCustomColorPicker(),
        crossFadeState: _showCustomPicker
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    );
  }

  Widget _buildPredefinedColorsView() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Choose Letter Color',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap a color for "${widget.letter}"',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Letter preview
          _buildLetterPreview(),
          const Divider(height: 1),
          // Color grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: kPredefinedColors.length,
              itemBuilder: (context, index) {
                final predefinedColor = kPredefinedColors[index];
                final isSelected = _selectedColor?.toARGB32() ==
                    predefinedColor.color.toARGB32();

                return Tooltip(
                  message:
                      '${predefinedColor.name}\n${predefinedColor.description}',
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedColor = predefinedColor.color;
                      });
                      // Return result immediately for quick selection
                      Navigator.of(context).pop(
                        ColorPickerResult.withColor(predefinedColor.color),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: predefinedColor.color,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: predefinedColor.color.withValues(alpha: 0.3),
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
                  ),
                );
              },
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Custom color button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showCustomPicker = true;
                      });
                    },
                    icon: const Icon(Icons.palette),
                    label: const Text('Custom'),
                  ),
                ),
                const SizedBox(width: 12),
                // Clear button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.currentColor != null
                        ? () {
                            Navigator.of(context)
                                .pop(ColorPickerResult.clear());
                          }
                        : null,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Cancel button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomColorPicker() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header with back button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showCustomPicker = false;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                const Expanded(
                  child: Text(
                    'Custom Color',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Balance the back button
              ],
            ),
          ),
          // Letter preview with selected color
          _buildLetterPreview(),
          const Divider(height: 1),
          // Material color picker
          Padding(
            padding: const EdgeInsets.all(16),
            child: _MaterialColorPicker(
              selectedColor: _selectedColor ?? Colors.red,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showCustomPicker = false;
                      });
                    },
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _selectedColor != null
                        ? () {
                            Navigator.of(context).pop(
                              ColorPickerResult.withColor(_selectedColor!),
                            );
                          }
                        : null,
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Preview: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  _selectedColor?.withValues(alpha: 0.1) ?? Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.letter,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _selectedColor ?? Colors.black,
                fontFamily: 'UthmanicHafs',
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple material-style color picker
class _MaterialColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;

  const _MaterialColorPicker({
    required this.selectedColor,
    required this.onColorChanged,
  });

  /// Material primary colors
  static const List<Color> _primaryColors = [
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select a color:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _primaryColors.map((color) {
            final isSelected = selectedColor.toARGB32() == color.toARGB32();
            return InkWell(
              onTap: () => onColorChanged(color),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: Colors.black, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
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
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Shade selector
        _buildShadeSelector(),
      ],
    );
  }

  Widget _buildShadeSelector() {
    // Find the primary color that matches the selected color
    Color primaryColor = _primaryColors.first;
    for (final color in _primaryColors) {
      if (selectedColor.toARGB32() == color.toARGB32()) {
        primaryColor = color;
        break;
      }
    }

    // Get shades for the primary color
    final shades = _getShadesForColor(primaryColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shade:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shades.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final shade = shades[index];
              final isSelected = selectedColor.toARGB32() == shade.toARGB32();
              return InkWell(
                onTap: () => onColorChanged(shade),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: shade,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: Colors.black, width: 2)
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: _getLuminance(shade) > 0.5
                              ? Colors.black
                              : Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Color> _getShadesForColor(Color color) {
    // Material color shades
    final materialColors = {
      Colors.red: [
        Colors.red.shade50,
        Colors.red.shade100,
        Colors.red.shade200,
        Colors.red.shade300,
        Colors.red.shade400,
        Colors.red.shade500,
        Colors.red.shade600,
        Colors.red.shade700,
        Colors.red.shade800,
        Colors.red.shade900,
      ],
      Colors.pink: [
        Colors.pink.shade50,
        Colors.pink.shade100,
        Colors.pink.shade200,
        Colors.pink.shade300,
        Colors.pink.shade400,
        Colors.pink.shade500,
        Colors.pink.shade600,
        Colors.pink.shade700,
        Colors.pink.shade800,
        Colors.pink.shade900,
      ],
      Colors.purple: [
        Colors.purple.shade50,
        Colors.purple.shade100,
        Colors.purple.shade200,
        Colors.purple.shade300,
        Colors.purple.shade400,
        Colors.purple.shade500,
        Colors.purple.shade600,
        Colors.purple.shade700,
        Colors.purple.shade800,
        Colors.purple.shade900,
      ],
      Colors.deepPurple: [
        Colors.deepPurple.shade50,
        Colors.deepPurple.shade100,
        Colors.deepPurple.shade200,
        Colors.deepPurple.shade300,
        Colors.deepPurple.shade400,
        Colors.deepPurple.shade500,
        Colors.deepPurple.shade600,
        Colors.deepPurple.shade700,
        Colors.deepPurple.shade800,
        Colors.deepPurple.shade900,
      ],
      Colors.indigo: [
        Colors.indigo.shade50,
        Colors.indigo.shade100,
        Colors.indigo.shade200,
        Colors.indigo.shade300,
        Colors.indigo.shade400,
        Colors.indigo.shade500,
        Colors.indigo.shade600,
        Colors.indigo.shade700,
        Colors.indigo.shade800,
        Colors.indigo.shade900,
      ],
      Colors.blue: [
        Colors.blue.shade50,
        Colors.blue.shade100,
        Colors.blue.shade200,
        Colors.blue.shade300,
        Colors.blue.shade400,
        Colors.blue.shade500,
        Colors.blue.shade600,
        Colors.blue.shade700,
        Colors.blue.shade800,
        Colors.blue.shade900,
      ],
      Colors.lightBlue: [
        Colors.lightBlue.shade50,
        Colors.lightBlue.shade100,
        Colors.lightBlue.shade200,
        Colors.lightBlue.shade300,
        Colors.lightBlue.shade400,
        Colors.lightBlue.shade500,
        Colors.lightBlue.shade600,
        Colors.lightBlue.shade700,
        Colors.lightBlue.shade800,
        Colors.lightBlue.shade900,
      ],
      Colors.cyan: [
        Colors.cyan.shade50,
        Colors.cyan.shade100,
        Colors.cyan.shade200,
        Colors.cyan.shade300,
        Colors.cyan.shade400,
        Colors.cyan.shade500,
        Colors.cyan.shade600,
        Colors.cyan.shade700,
        Colors.cyan.shade800,
        Colors.cyan.shade900,
      ],
      Colors.teal: [
        Colors.teal.shade50,
        Colors.teal.shade100,
        Colors.teal.shade200,
        Colors.teal.shade300,
        Colors.teal.shade400,
        Colors.teal.shade500,
        Colors.teal.shade600,
        Colors.teal.shade700,
        Colors.teal.shade800,
        Colors.teal.shade900,
      ],
      Colors.green: [
        Colors.green.shade50,
        Colors.green.shade100,
        Colors.green.shade200,
        Colors.green.shade300,
        Colors.green.shade400,
        Colors.green.shade500,
        Colors.green.shade600,
        Colors.green.shade700,
        Colors.green.shade800,
        Colors.green.shade900,
      ],
      Colors.lightGreen: [
        Colors.lightGreen.shade50,
        Colors.lightGreen.shade100,
        Colors.lightGreen.shade200,
        Colors.lightGreen.shade300,
        Colors.lightGreen.shade400,
        Colors.lightGreen.shade500,
        Colors.lightGreen.shade600,
        Colors.lightGreen.shade700,
        Colors.lightGreen.shade800,
        Colors.lightGreen.shade900,
      ],
      Colors.lime: [
        Colors.lime.shade50,
        Colors.lime.shade100,
        Colors.lime.shade200,
        Colors.lime.shade300,
        Colors.lime.shade400,
        Colors.lime.shade500,
        Colors.lime.shade600,
        Colors.lime.shade700,
        Colors.lime.shade800,
        Colors.lime.shade900,
      ],
      Colors.yellow: [
        Colors.yellow.shade50,
        Colors.yellow.shade100,
        Colors.yellow.shade200,
        Colors.yellow.shade300,
        Colors.yellow.shade400,
        Colors.yellow.shade500,
        Colors.yellow.shade600,
        Colors.yellow.shade700,
        Colors.yellow.shade800,
        Colors.yellow.shade900,
      ],
      Colors.amber: [
        Colors.amber.shade50,
        Colors.amber.shade100,
        Colors.amber.shade200,
        Colors.amber.shade300,
        Colors.amber.shade400,
        Colors.amber.shade500,
        Colors.amber.shade600,
        Colors.amber.shade700,
        Colors.amber.shade800,
        Colors.amber.shade900,
      ],
      Colors.orange: [
        Colors.orange.shade50,
        Colors.orange.shade100,
        Colors.orange.shade200,
        Colors.orange.shade300,
        Colors.orange.shade400,
        Colors.orange.shade500,
        Colors.orange.shade600,
        Colors.orange.shade700,
        Colors.orange.shade800,
        Colors.orange.shade900,
      ],
      Colors.deepOrange: [
        Colors.deepOrange.shade50,
        Colors.deepOrange.shade100,
        Colors.deepOrange.shade200,
        Colors.deepOrange.shade300,
        Colors.deepOrange.shade400,
        Colors.deepOrange.shade500,
        Colors.deepOrange.shade600,
        Colors.deepOrange.shade700,
        Colors.deepOrange.shade800,
        Colors.deepOrange.shade900,
      ],
      Colors.brown: [
        Colors.brown.shade50,
        Colors.brown.shade100,
        Colors.brown.shade200,
        Colors.brown.shade300,
        Colors.brown.shade400,
        Colors.brown.shade500,
        Colors.brown.shade600,
        Colors.brown.shade700,
        Colors.brown.shade800,
        Colors.brown.shade900,
      ],
      Colors.grey: [
        Colors.grey.shade50,
        Colors.grey.shade100,
        Colors.grey.shade200,
        Colors.grey.shade300,
        Colors.grey.shade400,
        Colors.grey.shade500,
        Colors.grey.shade600,
        Colors.grey.shade700,
        Colors.grey.shade800,
        Colors.grey.shade900,
      ],
      Colors.blueGrey: [
        Colors.blueGrey.shade50,
        Colors.blueGrey.shade100,
        Colors.blueGrey.shade200,
        Colors.blueGrey.shade300,
        Colors.blueGrey.shade400,
        Colors.blueGrey.shade500,
        Colors.blueGrey.shade600,
        Colors.blueGrey.shade700,
        Colors.blueGrey.shade800,
        Colors.blueGrey.shade900,
      ],
      Colors.black: [
        Colors.black,
        Colors.grey.shade900,
        Colors.grey.shade800,
        Colors.grey.shade700,
        Colors.grey.shade600,
        Colors.grey.shade500,
      ],
    };

    return materialColors[color] ?? [color];
  }

  double _getLuminance(Color color) {
    return color.computeLuminance();
  }
}
