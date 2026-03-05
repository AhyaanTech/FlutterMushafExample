# AGENTS.md - Ask Mode

This file provides guidance to agents in ASK mode when working with this Flutter Mushaf app.

## Project Documentation Rules (Non-Obvious Only)

### Documentation Sources
- **README.md is comprehensive**: Contains full setup instructions, architecture diagrams, and customization guide - always check here first
- **Plan in plans/ directory**: [`plans/mushaf_poc_plan.md`](plans/mushaf_poc_plan.md) has original design decisions and data flow diagrams
- **No API docs**: This is a self-contained offline app with no external APIs

### Architecture Misconceptions
- **Not a typical Flutter architecture**: Uses prop drilling instead of Provider/Bloc/Riverpod - state flows down through widget tree only
- **Database is NOT generated at build time**: `quran_offline.db` is pre-built and bundled - rebuilding requires Python script
- **Page numbers are 1-indexed**: DB uses 1-610, but PageView uses 0-603 (index = page - 1)

### Code Organization Quirks
- **Two sets of models**: Legacy `Surah`, `Ayah`, `Word` in [`quran_models.dart`](lib/models/quran_models.dart:132) are unused - active models are `QuranWord`, `QuranLine`, `QuranPage`
- **Unused widgets exist**: `MushafPage`, `AyahWidget`, `WordWidget` at bottom of [`mushaf_widgets.dart`](lib/widgets/mushaf_widgets.dart:148) are stubs returning empty Container
- **Font configuration is unusual**: No custom fonts bundled - relies entirely on system fonts with fallback chain

### Data Sources
- **Quran data from Tarteel QUL**: Uses two databases merged together:
  - `qpc-hafs-word-by-word.db` - Uthmani script from King Fahd Complex
  - `qudratullah-indopak-15-lines.db` - Page/line layout data
- **Merged via Python script**: `scripts/merge_quran_dbs.py` creates final `quran_offline.db`

### Key Behaviors
- **Marks are ephemeral**: No persistence layer - all marked words reset on app restart (documented as known limitation)
- **RTL is forced**: App hardcodes Arabic locale - English strings are secondary
- **15-line layout**: Specific to IndoPak Mushaf style, not Madani or other layouts
