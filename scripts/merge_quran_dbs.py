#!/usr/bin/env python3
"""
Quran Database Merger Script

Merges two SQLite databases into a unified mobile-ready database:
- qpc-hafs-word-by-word.db: Contains Arabic word-by-word script (Uthmani script)
- qudratullah-indopak-15-lines.db: Contains layout data with page_number and line_number coordinates

Output: assets/db/quran_offline.db with unified mushaf_pages table
"""

import sqlite3
import os
import sys
from pathlib import Path


# Configuration
SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_ROOT = SCRIPT_DIR.parent

DB_WORDS = PROJECT_ROOT / "qpc-hafs-word-by-word.db"
DB_LAYOUT = PROJECT_ROOT / "qudratullah-indopak-15-lines.db"
OUTPUT_DIR = PROJECT_ROOT / "assets" / "db"
OUTPUT_DB = OUTPUT_DIR / "quran_offline.db"


def ensure_directories():
    """Create output directories if they don't exist."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"✓ Output directory ready: {OUTPUT_DIR}")


def validate_inputs():
    """Check that source databases exist."""
    if not DB_WORDS.exists():
        raise FileNotFoundError(f"Words database not found: {DB_WORDS}")
    if not DB_LAYOUT.exists():
        raise FileNotFoundError(f"Layout database not found: {DB_LAYOUT}")
    print(f"✓ Found words database: {DB_WORDS}")
    print(f"✓ Found layout database: {DB_LAYOUT}")


def get_schema_info(conn, db_name):
    """Get table schema information for debugging."""
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = cursor.fetchall()
    print(f"\n{db_name} tables:")
    for (table,) in tables:
        cursor.execute(f"PRAGMA table_info({table});")
        columns = cursor.fetchall()
        col_info = ", ".join([f"{col[1]} ({col[2]})" for col in columns])
        print(f"  - {table}: {col_info}")


def merge_databases():
    """
    Merge the two databases into a unified mobile-ready database.
    
    Schema mapping:
    - qudratullah-indopak-15-lines.db.pages: page_number, line_number, line_type, 
                                             is_centered, first_word_id, last_word_id
    - qpc-hafs-word-by-word.db.words: id, location (surah:ayah:word), text
    
    Output mushaf_pages table:
    - page_number: Mushaf page number (1-610)
    - line_number: Line number on page (1-15)
    - word_id: Unique word identifier from words table
    - arabic_text: Uthmani Arabic script
    - verse_key: Format "surah:ayah" (e.g., "1:1")
    """
    print("\n" + "=" * 60)
    print("Starting database merge process...")
    print("=" * 60)
    
    # Remove existing output database if it exists
    if OUTPUT_DB.exists():
        OUTPUT_DB.unlink()
        print(f"✓ Removed existing output database")
    
    # Create new output database
    output_conn = sqlite3.connect(OUTPUT_DB)
    output_cursor = output_conn.cursor()
    print(f"✓ Created output database: {OUTPUT_DB}")
    
    # Attach source databases
    output_cursor.execute(f"ATTACH DATABASE '{DB_WORDS}' AS words_db;")
    output_cursor.execute(f"ATTACH DATABASE '{DB_LAYOUT}' AS layout_db;")
    print("✓ Attached source databases")
    
    # Get schema info for verification
    get_schema_info(output_conn, "Output DB (initial)")
    
    # Create the unified mushaf_pages table
    print("\nCreating unified mushaf_pages table...")
    output_cursor.execute("""
        CREATE TABLE mushaf_pages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            page_number INTEGER NOT NULL,
            line_number INTEGER NOT NULL,
            word_id INTEGER NOT NULL,
            arabic_text TEXT NOT NULL,
            verse_key TEXT NOT NULL,
            line_type TEXT,
            is_centered INTEGER
        );
    """)
    
    # Create indexes for efficient mobile queries
    output_cursor.execute("""
        CREATE INDEX idx_mushaf_pages_page ON mushaf_pages(page_number);
    """)
    output_cursor.execute("""
        CREATE INDEX idx_mushaf_pages_page_line ON mushaf_pages(page_number, line_number);
    """)
    output_cursor.execute("""
        CREATE INDEX idx_mushaf_pages_verse ON mushaf_pages(verse_key);
    """)
    print("✓ Created mushaf_pages table with indexes")
    
    # Insert data using JOIN between layout and words tables
    # The layout table defines ranges (first_word_id to last_word_id) for each line
    print("\nMerging data (this may take a moment)...")
    
    output_cursor.execute("""
        INSERT INTO mushaf_pages 
            (page_number, line_number, word_id, arabic_text, verse_key, line_type, is_centered)
        SELECT 
            p.page_number,
            p.line_number,
            w.id AS word_id,
            w.text AS arabic_text,
            w.surah || ':' || w.ayah AS verse_key,
            p.line_type,
            p.is_centered
        FROM layout_db.pages p
        JOIN words_db.words w ON w.id BETWEEN p.first_word_id AND p.last_word_id
        WHERE p.first_word_id IS NOT NULL AND p.last_word_id IS NOT NULL
        ORDER BY p.page_number, p.line_number, w.id;
    """)
    
    rows_inserted = output_cursor.rowcount
    print(f"✓ Inserted {rows_inserted:,} rows into mushaf_pages")
    
    # Create metadata table with source info
    output_cursor.execute("""
        CREATE TABLE metadata (
            key TEXT PRIMARY KEY,
            value TEXT
        );
    """)
    
    metadata = [
        ("source_words_db", "qpc-hafs-word-by-word.db (Uthmani script)"),
        ("source_layout_db", "qudratullah-indopak-15-lines.db (15-line layout)"),
        ("total_pages", "610"),
        ("lines_per_page", "15"),
        ("merged_at", "datetime('now')"),
    ]
    output_cursor.executemany(
        "INSERT INTO metadata (key, value) VALUES (?, ?);",
        metadata
    )
    print("✓ Created metadata table")
    
    # Commit and close
    output_conn.commit()
    
    # Get statistics
    output_cursor.execute("SELECT COUNT(DISTINCT page_number) FROM mushaf_pages;")
    total_pages = output_cursor.fetchone()[0]
    
    output_cursor.execute("SELECT COUNT(DISTINCT verse_key) FROM mushaf_pages;")
    total_verses = output_cursor.fetchone()[0]
    
    output_cursor.execute("SELECT COUNT(*) FROM mushaf_pages;")
    total_words = output_cursor.fetchone()[0]
    
    print("\n" + "=" * 60)
    print("Merge Complete!")
    print("=" * 60)
    print(f"Output file: {OUTPUT_DB}")
    print(f"File size: {OUTPUT_DB.stat().st_size / 1024 / 1024:.2f} MB")
    print(f"Total pages: {total_pages}")
    print(f"Total verses: {total_verses}")
    print(f"Total words: {total_words:,}")
    print("=" * 60)
    
    output_conn.close()
    print("\n✓ Database merge completed successfully!")
    
    return rows_inserted


def verify_output():
    """Verify the output database by sampling some records."""
    print("\n" + "=" * 60)
    print("Verifying output database...")
    print("=" * 60)
    
    conn = sqlite3.connect(OUTPUT_DB)
    cursor = conn.cursor()
    
    # Sample: First page (Al-Fatiha)
    print("\nSample: Page 1 (Al-Fatiha)")
    cursor.execute("""
        SELECT page_number, line_number, arabic_text, verse_key 
        FROM mushaf_pages 
        WHERE page_number = 1 
        ORDER BY line_number, id 
        LIMIT 10;
    """)
    for row in cursor.fetchall():
        print(f"  Page {row[0]}, Line {row[1]} [{row[3]}]: {row[2]}")
    
    # Sample: Page 2 (start of Al-Baqarah)
    print("\nSample: Page 2 (Al-Baqarah)")
    cursor.execute("""
        SELECT page_number, line_number, arabic_text, verse_key 
        FROM mushaf_pages 
        WHERE page_number = 2 
        ORDER BY line_number, id 
        LIMIT 10;
    """)
    for row in cursor.fetchall():
        print(f"  Page {row[0]}, Line {row[1]} [{row[3]}]: {row[2]}")
    
    # Metadata
    print("\nMetadata:")
    cursor.execute("SELECT * FROM metadata;")
    for row in cursor.fetchall():
        print(f"  {row[0]}: {row[1]}")
    
    conn.close()
    print("\n✓ Verification complete!")


def main():
    """Main entry point."""
    try:
        print("Quran Database Merger")
        print("=" * 60)
        
        ensure_directories()
        validate_inputs()
        merge_databases()
        verify_output()
        
        return 0
        
    except FileNotFoundError as e:
        print(f"\n✗ Error: {e}")
        return 1
    except sqlite3.Error as e:
        print(f"\n✗ Database error: {e}")
        return 1
    except Exception as e:
        print(f"\n✗ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
