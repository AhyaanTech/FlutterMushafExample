#!/usr/bin/env python3
"""Configuration and constants for Quran database building."""

from pathlib import Path

# Project paths
PROJECT_ROOT = Path(__file__).parent.parent.parent.resolve()
SCRIPTS_DIR = PROJECT_ROOT / "scripts"
ASSETS_DIR = PROJECT_ROOT / "assets"
DB_DIR = ASSETS_DIR / "db"
OUTPUT_DB = DB_DIR / "quran_offline.db"

# Source databases
DB_WORDS = PROJECT_ROOT / "qpc-hafs-word-by-word.db"
DB_LAYOUT = PROJECT_ROOT / "qudratullah-indopak-15-lines.db"
DB_QPC_V4 = PROJECT_ROOT / "qpc-v4.db"  # Currently unused (redundant)

# Schema constants
TOTAL_PAGES = 610
LINES_PER_PAGE = 15
TOTAL_SURAHS = 114

# Table names
TABLE_WORDS = "words"
TABLE_AYAHS = "ayahs"
TABLE_SURAHS = "surahs"
TABLE_MUSHAF_PAGES = "mushaf_pages"
TABLE_LETTER_BREAKDOWN = "letter_breakdown"
TABLE_METADATA = "metadata"

# Letter breakdown flags
DIACRITIC_FLAGS = [
    "has_fatha",
    "has_kasra", 
    "has_damma",
    "has_sukun",
    "has_shadda",
    "has_tanwin_fath",
    "has_tanwin_kasr",
    "has_tanwin_damm",
    "has_maddah",
    "has_hamza_above",
    "has_hamza_below",
    "has_superscript_alef",
    "has_subscript_alef",
    "has_small_high_alef",
    "has_small_high_meem",
    "has_small_high_jeem",
    "has_small_high_three_dots",
    "has_small_high_seen",
    "has_small_high_rounded_zero",
    "has_small_high_upright_zero",
    "has_small_high_dotless_head",
    "has_small_low_meem",
]

# Unicode codepoints for diacritics
DIACRITIC_TYPES = {
    0x064E: ("haraka", "fatha"),
    0x0650: ("haraka", "kasra"),
    0x064F: ("haraka", "damma"),
    0x0652: ("sukun", "sukun"),
    0x064B: ("tanwin", "tanwin_fath"),
    0x064D: ("tanwin", "tanwin_kasr"),
    0x064C: ("tanwin", "tanwin_damm"),
    0x0651: ("shadda", "shadda"),
    0x0653: ("maddah", "maddah"),
    0x0654: ("hamza", "hamza_above"),
    0x0655: ("hamza", "hamza_below"),
    0x0670: ("special", "superscript_alef"),
    0x0656: ("special", "subscript_alef"),
}
