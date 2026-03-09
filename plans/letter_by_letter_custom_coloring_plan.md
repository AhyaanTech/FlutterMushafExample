# Letter-by-Letter Custom Coloring Implementation Plan

## Overview
This plan outlines the implementation of letter-by-letter custom coloring for the Flutter Mushaf app, supporting both existing QPC V4 tajweed rules and completely custom user-defined colors. The goal is to replace the current word marking feature with flexible letter-level coloring capabilities.

## Requirements Analysis
- Support both predefined QPC V4 tajweed rules AND custom user-defined colors per letter
- Compare TextSpan vs Glyph rendering approaches to determine best fit
- Replace existing word marking feature with letter coloring functionality  
- Maintain POC flexibility for experimentation and iteration

## Architecture Recommendation
**Primary Focus: TextSpan Approach**
- Better suited for custom coloring due to dynamic color flexibility
- Easier integration with Flutter's built-in color pickers and UI components
- Faster development cycle for POC validation
- Lower complexity while maintaining good visual quality

**Secondary: Glyph Approach** 
- Superior visual fidelity and Arabic shaping
- Better for static, predefined coloring schemes
- More complex for dynamic custom colors
- Keep infrastructure intact for comparison if needed

## Data Model Design

### Enhanced Color Modes
```dart
enum ColorMode {
  none,           // No coloring (default text)
  tajweed,        // Predefined QPC V4 tajweed rules  
  mistakes,       // Mistake highlighting (existing)
  custom,         // User-defined custom colors per letter
}
```

### Custom Letter Color Model (Separate Layer)
```dart
class CustomLetterColor {
  final int wordId;
  final int letterIndex; // 0-based index within the word
  final Color color;
  
  const CustomLetterColor({
    required this.wordId,
    required this.letterIndex, 
    required this.color,
  });
}
```

### Color Resolution Logic
```dart
Color resolveLetterColor({
  required LetterData? letterData, // From V4 database
  required CustomLetterColor? customColor, // User-defined
  required ColorMode colorMode,
}) {
  if (colorMode == ColorMode.custom && customColor != null) {
    return customColor.color;
  }
  if (colorMode == ColorMode.tajweed && letterData?.hasTajweedRule == true) {
    return DatabaseHelper.tajweedColors[letterData!.tajweedRule] ?? Colors.black;
  }
  return Colors.black; // Default
}
```

## State Management Strategy

### In-Memory Custom Colors (POC-Friendly)
```dart
// In MushafScreen state
final Map<int, List<Color?>> _customLetterColors = {}; // wordId -> [color1, color2, ...]

void setLetterColor(int wordId, int letterIndex, Color color) {
  if (!_customLetterColors.containsKey(wordId)) {
    _customLetterColors[wordId] = [];
  }
  final colors = _customLetterColors[wordId]!;
  if (colors.length <= letterIndex) {
    colors.addAll(List.filled(letterIndex - colors.length + 1, null));
  }
  colors[letterIndex] = color;
  setState(() {}); // Trigger rebuild
}

Color? getLetterColor(int wordId, int letterIndex) {
  return _customLetterColors[wordId]?[letterIndex];
}
```

## Implementation Priority Order

### Phase 1: Core Infrastructure (High Priority)
- [ ] Extend `ColorMode` enum with `custom`
- [ ] Implement custom color state management in `MushafScreen`
- [ ] Create color resolution utility functions
- [ ] Update `MushafWordFactory` to handle custom mode

### Phase 2: TextSpan Implementation (Primary Focus)
- [ ] Modify `MushafWordTextSpan` to support custom letter colors
- [ ] Implement letter-level tap detection with `GestureDetector`
- [ ] Add color picker dialog with predefined palette
- [ ] Integrate custom color state with widget rendering

### Phase 3: UI Integration
- [ ] Replace word marking controls with color mode selector
- [ ] Add visual indicators for custom coloring mode
- [ ] Implement clear/reset functionality for custom colors

### Phase 4: Glyph Support (Secondary)
- [ ] Minimal update to `MushafWordGlyph` for custom color support
- [ ] Basic comparison capability

### Phase 5: Testing & Documentation
- [ ] Test with various Arabic text samples
- [ ] Document performance characteristics
- [ ] Provide usage recommendations

## Letter Identification Strategy

### TextSpan Approach
- Each `TextSpan` gets unique key: `(wordId, letterIndex)`
- Wrap each `TextSpan` in `GestureDetector` for tap detection
- Use `LayoutBuilder` for position data if needed

### Glyph Approach  
- Use existing glyph coordinate data from V4 database
- Implement hit testing with `CustomPainter` and `onTapDown`
- Calculate tapped glyph based on coordinates

## UI/UX Flow

### Color Mode Selection
```
None → Tajweed Rules → Custom Coloring
```

### Custom Coloring Workflow
1. User selects "Custom Coloring" mode
2. Taps any letter in any word  
3. Color picker dialog appears
4. User selects color (predefined palette or full picker)
5. Letter immediately updates with selected color
6. Color persists in memory for session

## Performance Considerations

### Caching Strategy
- Cache V4 letter data (already implemented)
- Cache custom color assignments in memory
- Use `const` constructors where possible
- Implement lazy loading for color picker

### Memory Management
- In-memory only (no persistence overhead for POC)
- Clear custom colors when switching pages/modes
- Limit cache size for large sessions

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Arabic text joining breaks with multiple TextSpans | Test thoroughly with UthmanicHafs font; fallback to single TextSpan if needed |
| Letter tap detection inaccurate | Add visual feedback (highlight on tap) to confirm selection |
| Performance degradation with many colored letters | Implement efficient caching and consider limiting simultaneous custom colors |
| Color picker UI complexity | Start with simple predefined palette, add full picker later |

## Expected Outcomes

**TextSpan Advantages for Custom Coloring:**
- ✅ Easy dynamic color changes
- ✅ Native Flutter integration  
- ✅ Supports text selection
- ✅ Lower development complexity
- ✅ Better user interaction support

**Glyph Advantages for Visual Fidelity:**
- ✅ Pixel-perfect Mushaf reproduction
- ✅ Guaranteed correct Arabic shaping
- ✅ Perfect diacritic positioning
- ✅ Scholar-approved layout

## Conclusion
This architecture provides a solid foundation for implementing letter-by-letter custom coloring while maintaining the flexibility needed for POC experimentation. The focus on TextSpan for custom coloring balances development speed with functionality, while keeping Glyph support available for comparison and future enhancement.