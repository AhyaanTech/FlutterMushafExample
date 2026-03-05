# AGENTS.md - Architect Mode

This file provides guidance to agents in ARCHITECT mode when working with this Flutter Mushaf app.

## Project Architecture Rules (Non-Obvious Only)

### Design Decisions
- **Intentionally simple state management**: Chose prop drilling over Provider/Bloc because mark state is ephemeral and local to screen - adding state management would be over-engineering
- **In-memory marks by design**: Persistence deliberately not implemented to keep dependencies minimal - documented as "future enhancement"
- **Pre-built database over migrations**: Bundling 6.88MB SQLite DB avoids complex migration logic and ensures consistent data

### Data Flow Constraints
- **Unidirectional flow**: `MushafScreen` owns all state → passes callbacks down → widgets call back up → `setState()` triggers rebuild
- **No context-based access**: Database helper accessed directly in screen, not via `BuildContext` - makes testing harder but code simpler
- **Page cache is mutable**: `_pageCache` Map is modified in-place during preloading - not a pure functional approach

### Performance Architecture
- **Lazy loading with preloading**: Pages load on-demand but adjacent pages preload in background - balance between memory and UX
- **No pagination within pages**: Entire page (15 lines) loaded at once - simpler than virtualized lists but memory heavier
- **Widget tree depth**: `MushafScreen` → `MushafPageWidget` → `MushafLineWidget` → `MushafWordWidget` - 4 levels for tap handling

### Database Design
- **Single table denormalization**: `mushaf_pages` repeats verse_key and line_type per word - trades storage for query simplicity
- **Indexes on query columns**: `page_number`, `page_number+line_number`, `verse_key` indexed - optimized for page-based reads
- **Metadata table**: Separate `metadata` table tracks source info and generation timestamp

### RTL Architecture
- **Forced RTL at app level**: `locale: const Locale('ar', 'SA')` sets entire app direction - no per-widget directionality switching
- **Reverse PageView**: `reverse: true` achieves correct swipe direction without custom scroll physics
- **TextDirection.rtl explicit**: Even with forced locale, widgets explicitly set `textDirection: TextDirection.rtl`

### Extensibility Points
- **Mark color is hardcoded**: `Colors.red` in [`MushafWordWidget`](lib/widgets/mushaf_widgets.dart:43) - theming not implemented
- **Line types are string enums**: 'surah_name', 'basmallah', 'ayah' - could be formal enum but strings allow DB flexibility
- **Font stack is static**: No runtime font switching - font fallbacks are compile-time list

### Future Architecture Considerations
- **Adding persistence**: Would require `shared_preferences` or `hive` dependency + serialization of `Set<int>` + load on init
- **Multiple Mushaf layouts**: Would need separate DB tables or `layout_type` column + layout selection UI
- **Audio integration**: Would need separate audio player service + word-level timing data (not in current DB)
