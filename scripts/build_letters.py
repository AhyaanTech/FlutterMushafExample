#!/usr/bin/env python3
"""Build letter breakdown table.

Run this after build_db.py to generate character-level analysis.

Usage:
    uv run scripts/build_letters.py           # Build letter breakdown
    uv run scripts/build_letters.py --stats   # Show statistics
"""

import sys
import argparse
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from quran_db.database import connect_output
from quran_db.letter_builder import LetterBreakdownBuilder
from quran_db.config import OUTPUT_DB


def build_letters():
    """Build letter breakdown table."""
    if not OUTPUT_DB.exists():
        print(f"[ERR] Database not found: {OUTPUT_DB}")
        print("Run 'uv run scripts/build_db.py' first")
        return False
    
    print("=" * 60)
    print("Letter Breakdown Builder")
    print("=" * 60)
    
    with connect_output() as conn:
        builder = LetterBreakdownBuilder(conn)
        stats = builder.build()
        
        print("\n" + "=" * 60)
        print("Complete!")
        print("=" * 60)
        print(f"Words processed: {stats['words_processed']:,}")
        print(f"Letters inserted: {stats['letters_inserted']:,}")
        print(f"Average letters per word: {stats['letters_inserted'] / stats['words_processed']:.1f}")
    
    return True


def show_stats():
    """Show letter breakdown statistics."""
    if not OUTPUT_DB.exists():
        print(f"[ERR] Database not found: {OUTPUT_DB}")
        return False
    
    with connect_output() as conn:
        cursor = conn.cursor()
        
        # Check if table exists
        exists = cursor.execute("""
            SELECT name FROM sqlite_master WHERE type='table' AND name='letter_breakdown'
        """).fetchone()
        
        if not exists:
            print("[ERR] letter_breakdown table not found")
            return False
        
        print("=" * 60)
        print("Letter Breakdown Statistics")
        print("=" * 60)
        
        cursor.execute("SELECT COUNT(*) FROM letter_breakdown")
        total_letters = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(DISTINCT word_id) FROM letter_breakdown")
        total_words = cursor.fetchone()[0]
        
        print(f"\nTotal letters: {total_letters:,}")
        print(f"Total words: {total_words:,}")
        print(f"Average: {total_letters / total_words:.1f} letters/word")
        
        # Diacritic statistics
        print("\nDiacritic frequencies:")
        diacritics = [
            ("has_shadda", "Shadda"),
            ("has_fatha", "Fatha"),
            ("has_kasra", "Kasra"),
            ("has_damma", "Damma"),
            ("has_sukun", "Sukun"),
        ]
        
        for column, name in diacritics:
            cursor.execute(f"SELECT COUNT(*) FROM letter_breakdown WHERE {column} = 1")
            count = cursor.fetchone()[0]
            pct = (count / total_letters) * 100
            print(f"  {name:12} {count:>8,} ({pct:5.1f}%)")
    
    return True


def main():
    parser = argparse.ArgumentParser(description="Build letter breakdown table")
    parser.add_argument("--stats", "-s", action="store_true", help="Show statistics only")
    
    args = parser.parse_args()
    
    if args.stats:
        return 0 if show_stats() else 1
    else:
        return 0 if build_letters() else 1


if __name__ == "__main__":
    sys.exit(main())
