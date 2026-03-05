# AGENTS.md - Debug Mode

This file provides guidance to agents in DEBUG mode when working with this Flutter Mushaf app.

## Project Debug Rules (Non-Obvious Only)

### Database Issues
- **"table not found" on first run**: Database copy from assets may have failed - check app documents directory for `quran_offline.db` file size (should be ~6.88MB)
- **Silent DB failures**: [`DatabaseHelper._initDatabase()`](lib/services/database_helper.dart:34) catches and prints errors but app shows generic error UI - check console for actual SQLite error
- **Asset loading fails silently**: `rootBundle.load()` in [`_copyDatabaseFromAssets()`](lib/services/database_helper.dart:66) can fail if asset not declared in `pubspec.yaml` - verify `assets/db/quran_offline.db` is listed

### RTL/Text Rendering Issues
- **Arabic shows as boxes**: Missing `.SF Arabic` font on macOS - check system font availability, fallback to `Scheherazade` works but looks different
- **Text direction wrong**: Verify `Directionality(textDirection: TextDirection.rtl)` wrapper exists - missing this causes LTR layout
- **Page swipe direction reversed**: This is intentional - `reverse: true` in PageView gives correct RTL behavior (left swipe = next page visually)

### Performance Issues
- **Jank on page swipe**: [`_pageCache`](lib/screens/mushaf_screen.dart:39) may not have page yet - check if preloading is working in `_preloadAdjacentPages()`
- **Memory leak on marks**: `Set<int> _markedWordIds` grows unbounded if user marks many words - not currently an issue but could be with persistence
- **Database connections**: Multiple `DatabaseHelper()` calls return same instance, but check `_database` is not null before operations

### State Issues
- **Marks disappear on restart**: This is expected behavior - `Set<int>` is in-memory only, no persistence implemented
- **Mark state out of sync**: If word IDs from DB don't match what widgets expect, marks appear on wrong words - verify `word.id` matches DB's `word_id` column

### Logging
- **Print statements in code**: Look for `print()` in [`DatabaseHelper`](lib/services/database_helper.dart) and [`main.dart`](lib/main.dart) - these go to Flutter console
- **Error screens**: App has custom error UI in [`main.dart`](lib/main.dart:104-160) that catches initialization errors with retry button

### Platform-Specific
- **macOS entitlements**: Debug builds may need additional entitlements for file system access - check `macos/Runner/DebugProfile.entitlements`
- **iOS simulator font issues**: `.SF Arabic` may not be available in simulator - use physical device or add `Scheherazade` custom font
