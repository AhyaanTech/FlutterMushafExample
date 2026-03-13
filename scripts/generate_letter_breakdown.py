#!/usr/bin/env python3
"""
Quran Letter Breakdown Generator

Generates a detailed letter-by-letter breakdown table for Quranic text analysis.
Segments each word into individual Arabic letters with their corresponding diacritics.

Output: Updates assets/db/quran_offline.db with letter_breakdown table
"""

import sqlite3
import json
import unicodedata
import os
import sys
from pathlib import Path
from typing import List, Dict, Any, Tuple, Optional
from dataclasses import dataclass, asdict
from collections import defaultdict

# Configuration
SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_ROOT = SCRIPT_DIR.parent
OUTPUT_DB = PROJECT_ROOT / "assets" / "db" / "quran_offline.db"


@dataclass
class DiacriticInfo:
    """Information about a single diacritic mark"""
    char: str
    codepoint: int
    name: str
    category: str
    type: str  # haraka, tanwin, shadda, sukun, maddah, hamza, special, stop_mark


@dataclass
class LetterBreakdown:
    """Represents a single letter with its diacritics"""
    word_id: int
    verse_key: str
    word_position: int
    letter_index: int
    letter_position: int
    base_letter: str
    letter_with_diacritics: str
    base_letter_codepoint: int
    base_letter_category: str
    base_letter_name: str
    diacritics: List[DiacriticInfo]
    diacritics_json: str
    
    # Boolean flags
    has_fatha: bool
    has_kasra: bool
    has_damma: bool
    has_sukun: bool
    has_shadda: bool
    has_tanwin_fath: bool
    has_tanwin_kasr: bool
    has_tanwin_damm: bool
    has_maddah: bool
    has_hamza_above: bool
    has_hamza_below: bool
    has_superscript_alef: bool
    has_subscript_alef: bool
    has_small_high_alef: bool
    has_small_high_meem: bool
    has_small_high_jeem: bool
    has_small_high_three_dots: bool
    has_small_high_seen: bool
    has_small_high_rounded_zero: bool
    has_small_high_upright_zero: bool
    has_small_high_dotless_head: bool
    has_small_low_meem: bool
    
    letter_type: str
    is_hamza_variant: bool
    source_db: str = "qpc-hafs-word-by-word.db"


# Unicode codepoint to diacritic type mapping
DIACRITIC_TYPES = {
    # Basic harakat
    0x064E: ('haraka', 'fatha'),
    0x0650: ('haraka', 'kasra'),
    0x064F: ('haraka', 'damma'),
    0x0652: ('sukun', 'sukun'),
    
    # Tanwin
    0x064B: ('tanwin', 'tanwin_fath'),
    0x064D: ('tanwin', 'tanwin_kasr'),
    0x064C: ('tanwin', 'tanwin_damm'),
    
    # Shadda
    0x0651: ('shadda', 'shadda'),
    
    # Maddah
    0x0653: ('maddah', 'maddah'),
    
    # Hamza
    0x0654: ('hamza', 'hamza_above'),
    0x0655: ('hamza', 'hamza_below'),
    
    # Special marks
    0x0670: ('special', 'superscript_alef'),  # Dagger alef
    0x0656: ('special', 'subscript_alef'),
    0x0657: ('special', 'inverted_damma'),
    0x0658: ('special', 'mark_noon'),
    0x0659: ('special', 'zwarakay'),
    0x065A: ('special', 'vowel_sign_v'),
    0x065B: ('special', 'vowel_sign_inverted_v'),
    0x065C: ('special', 'vowel_sign_dot_below'),
    0x065D: ('special', 'reversed_damma'),
    0x065E: ('special', 'fatha_with_ring'),
    0x065F: ('special', 'kasra_with_ring'),
    
    # Small high marks (Uthmani script)
    0x06D6: ('stop_mark', 'small_high_ligature_sad_lam_alef'),
    0x06D7: ('stop_mark', 'small_high_ligature_qaf_lam_alef'),
    0x06D8: ('stop_mark', 'small_high_meem_initial'),
    0x06D9: ('stop_mark', 'small_high_lam_alef'),
    0x06DA: ('stop_mark', 'small_high_jeem'),
    0x06DB: ('stop_mark', 'small_high_three_dots'),
    0x06DC: ('stop_mark', 'small_high_seen'),
    0x06DD: ('stop_mark', 'end_of_ayah'),
    0x06DE: ('stop_mark', 'start_of_rub_el_hizb'),
    0x06DF: ('stop_mark', 'small_high_rounded_zero'),
    0x06E0: ('stop_mark', 'small_high_upright_rectangular_zero'),
    0x06E1: ('stop_mark', 'small_high_dotless_head'),
    0x06E2: ('stop_mark', 'small_high_meem_isolated'),
    0x06E3: ('stop_mark', 'small_low_seen'),
    0x06E4: ('stop_mark', 'small_high_maddah'),
    0x06E5: ('stop_mark', 'small_waw'),
    0x06E6: ('stop_mark', 'small_yeh'),
    0x06E7: ('stop_mark', 'small_high_yeh'),
    0x06E8: ('stop_mark', 'small_high_noon'),
    0x06E9: ('stop_mark', 'place_of_sajdah'),
    0x06EA: ('stop_mark', 'empty_centre_low_stop'),
    0x06EB: ('stop_mark', 'empty_centre_high_stop'),
    0x06EC: ('stop_mark', 'rounded_high_stop_with_filled_centre'),
    0x06ED: ('stop_mark', 'small_low_meem'),
}

# Base letter types
LETTER_TYPES = {
    'consonant': [
        'ARABIC LETTER BEH', 'ARABIC LETTER TEH', 'ARABIC LETTER THEH',
        'ARABIC LETTER JEEM', 'ARABIC LETTER HAH', 'ARABIC LETTER KHAH',
        'ARABIC LETTER DAL', 'ARABIC LETTER THAL', 'ARABIC LETTER REH',
        'ARABIC LETTER ZAIN', 'ARABIC LETTER SEEN', 'ARABIC LETTER SHEEN',
        'ARABIC LETTER SAD', 'ARABIC LETTER DAD', 'ARABIC LETTER TAH',
        'ARABIC LETTER ZAH', 'ARABIC LETTER AIN', 'ARABIC LETTER GHAIN',
        'ARABIC LETTER FEH', 'ARABIC LETTER QAF', 'ARABIC LETTER KAF',
        'ARABIC LETTER LAM', 'ARABIC LETTER MEEM', 'ARABIC LETTER NOON',
        'ARABIC LETTER HEH', 'ARABIC LETTER WAW', 'ARABIC LETTER YEH',
        'ARABIC LETTER PEH', 'ARABIC LETTER TCHEH', 'ARABIC LETTER VEH',
        'ARABIC LETTER GAF',
    ],
    'vowel_carrier': [
        'ARABIC LETTER ALEF',
        'ARABIC LETTER ALEF WITH MADDA ABOVE',
        'ARABIC LETTER ALEF WITH HAMZA ABOVE',
        'ARABIC LETTER ALEF WITH HAMZA BELOW',
        'ARABIC LETTER ALEF WASLA',
        'ARABIC LETTER ALEF WITH WAVY HAMZA ABOVE',
        'ARABIC LETTER ALEF WITH WAVY HAMZA BELOW',
        'ARABIC LETTER HIGH HAMZA ALEF',
    ],
    'long_vowel': [
        'ARABIC LETTER WAW',
        'ARABIC LETTER YEH',
        'ARABIC LETTER ALEF MAKSURA',
        'ARABIC LETTER ALEF WITH MADDA ABOVE',
    ]
}


def get_letter_type(letter_name: str, base_letter: str) -> str:
    """Determine the letter type based on Unicode name"""
    for letter_type, names in LETTER_TYPES.items():
        for name in names:
            if name in letter_name:
                return letter_type
    return 'consonant'


def is_hamza_variant(letter_name: str) -> bool:
    """Check if the letter is a hamza variant"""
    hamza_indicators = ['HAMZA', 'WASLA', 'MADDA']
    return any(indicator in letter_name for indicator in hamza_indicators)


def classify_diacritic(char: str, codepoint: int) -> DiacriticInfo:
    """Classify a diacritic character and return its info"""
    name = unicodedata.name(char, 'UNKNOWN')
    category = unicodedata.category(char)
    
    if codepoint in DIACRITIC_TYPES:
        dtype, subtype = DIACRITIC_TYPES[codepoint]
    elif category == 'Mn':
        dtype = 'unknown_mark'
    else:
        dtype = 'other'
    
    return DiacriticInfo(
        char=char,
        codepoint=codepoint,
        name=name,
        category=category,
        type=dtype
    )


def segment_word_into_letters(word_text: str) -> List[Tuple[str, List[DiacriticInfo]]]:
    """
    Segment an Arabic word into base letters with their attached diacritics.
    
    Returns a list of tuples: (base_letter, list_of_diacritics)
    The order is RTL (display order) which is correct for Quranic text.
    """
    letters = []
    current_base: Optional[str] = None
    current_diacritics: List[DiacriticInfo] = []
    
    for char in word_text:
        codepoint = ord(char)
        category = unicodedata.category(char)
        
        if category == 'Lo':  # Letter, other - base Arabic letters
            # Save previous letter if exists
            if current_base is not None:
                letters.append((current_base, current_diacritics))
            
            # Start new letter
            current_base = char
            current_diacritics = []
            
        elif category == 'Mn' or category == 'Me' or category == 'Cf':  # Marks
            # This is a diacritic - attach to current base letter
            diacritic = classify_diacritic(char, codepoint)
            current_diacritics.append(diacritic)
            
        elif category == 'Nd':  # Decimal digit (ayat numbers)
            # Treat digits as standalone "letters"
            if current_base is not None:
                letters.append((current_base, current_diacritics))
            letters.append((char, []))
            current_base = None
            current_diacritics = []
            
        else:
            # Other characters - treat as base letters
            if current_base is not None:
                letters.append((current_base, current_diacritics))
            current_base = char
            current_diacritics = []
    
    # Don't forget the last letter
    if current_base is not None:
        letters.append((current_base, current_diacritics))
    
    return letters


def compute_boolean_flags(diacritics: List[DiacriticInfo]) -> Dict[str, bool]:
    """Compute boolean flags from list of diacritics"""
    flags = {
        'has_fatha': False,
        'has_kasra': False,
        'has_damma': False,
        'has_sukun': False,
        'has_shadda': False,
        'has_tanwin_fath': False,
        'has_tanwin_kasr': False,
        'has_tanwin_damm': False,
        'has_maddah': False,
        'has_hamza_above': False,
        'has_hamza_below': False,
        'has_superscript_alef': False,
        'has_subscript_alef': False,
        'has_small_high_alef': False,
        'has_small_high_meem': False,
        'has_small_high_jeem': False,
        'has_small_high_three_dots': False,
        'has_small_high_seen': False,
        'has_small_high_rounded_zero': False,
        'has_small_high_upright_zero': False,
        'has_small_high_dotless_head': False,
        'has_small_low_meem': False,
    }
    
    for d in diacritics:
        codepoint = d.codepoint
        if codepoint == 0x064E:
            flags['has_fatha'] = True
        elif codepoint == 0x0650:
            flags['has_kasra'] = True
        elif codepoint == 0x064F:
            flags['has_damma'] = True
        elif codepoint == 0x0652:
            flags['has_sukun'] = True
        elif codepoint == 0x0651:
            flags['has_shadda'] = True
        elif codepoint == 0x064B:
            flags['has_tanwin_fath'] = True
        elif codepoint == 0x064D:
            flags['has_tanwin_kasr'] = True
        elif codepoint == 0x064C:
            flags['has_tanwin_damm'] = True
        elif codepoint == 0x0653:
            flags['has_maddah'] = True
        elif codepoint == 0x0654:
            flags['has_hamza_above'] = True
        elif codepoint == 0x0655:
            flags['has_hamza_below'] = True
        elif codepoint == 0x0670:
            flags['has_superscript_alef'] = True
        elif codepoint == 0x0656:
            flags['has_subscript_alef'] = True
        elif codepoint in (0x06D6, 0x06D7, 0x06D8):
            flags['has_small_high_alef'] = True
        elif codepoint == 0x06E2:
            flags['has_small_high_meem'] = True
        elif codepoint == 0x06DA:
            flags['has_small_high_jeem'] = True
        elif codepoint == 0x06DB:
            flags['has_small_high_three_dots'] = True
        elif codepoint == 0x06DC:
            flags['has_small_high_seen'] = True
        elif codepoint == 0x06DF:
            flags['has_small_high_rounded_zero'] = True
        elif codepoint == 0x06E0:
            flags['has_small_high_upright_zero'] = True
        elif codepoint == 0x06E1:
            flags['has_small_high_dotless_head'] = True
        elif codepoint == 0x06ED:
            flags['has_small_low_meem'] = True
    
    return flags


def create_letter_breakdown(
    word_id: int,
    verse_key: str,
    word_position: int,
    word_text: str
) -> List[LetterBreakdown]:
    """Create letter breakdown entries for a single word"""
    
    segmented = segment_word_into_letters(word_text)
    breakdowns = []
    
    for letter_index, (base_letter, diacritics) in enumerate(segmented):
        # Get base letter info
        base_codepoint = ord(base_letter)
        base_category = unicodedata.category(base_letter)
        base_name = unicodedata.name(base_letter, 'UNKNOWN')
        
        # Build letter with diacritics
        letter_with_diacritics = base_letter + ''.join(d.char for d in diacritics)
        
        # Convert diacritics to JSON
        diacritics_data = [
            {
                'char': d.char,
                'codepoint': d.codepoint,
                'name': d.name,
                'type': d.type
            }
            for d in diacritics
        ]
        diacritics_json = json.dumps(diacritics_data, ensure_ascii=False)
        
        # Compute flags
        flags = compute_boolean_flags(diacritics)
        
        # Determine letter type
        letter_type = get_letter_type(base_name, base_letter)
        is_hamza = is_hamza_variant(base_name)
        
        breakdown = LetterBreakdown(
            word_id=word_id,
            verse_key=verse_key,
            word_position=word_position,
            letter_index=letter_index,
            letter_position=letter_index,  # Same as index in RTL
            base_letter=base_letter,
            letter_with_diacritics=letter_with_diacritics,
            base_letter_codepoint=base_codepoint,
            base_letter_category=base_category,
            base_letter_name=base_name,
            diacritics=diacritics,
            diacritics_json=diacritics_json,
            letter_type=letter_type,
            is_hamza_variant=is_hamza,
            **flags
        )
        
        breakdowns.append(breakdown)
    
    return breakdowns


def create_letter_breakdown_table(conn: sqlite3.Connection):
    """Create the letter_breakdown table with all indexes"""
    cursor = conn.cursor()
    
    # Drop existing table if it exists
    cursor.execute("DROP TABLE IF EXISTS letter_breakdown;")
    
    # Create table
    cursor.execute("""
        CREATE TABLE letter_breakdown (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word_id INTEGER NOT NULL,
            verse_key TEXT NOT NULL,
            word_position INTEGER NOT NULL,
            letter_index INTEGER NOT NULL,
            letter_position INTEGER NOT NULL,
            base_letter TEXT NOT NULL,
            letter_with_diacritics TEXT,
            base_letter_codepoint INTEGER,
            base_letter_category TEXT,
            base_letter_name TEXT,
            diacritics_json TEXT,
            has_fatha INTEGER DEFAULT 0,
            has_kasra INTEGER DEFAULT 0,
            has_damma INTEGER DEFAULT 0,
            has_sukun INTEGER DEFAULT 0,
            has_shadda INTEGER DEFAULT 0,
            has_tanwin_fath INTEGER DEFAULT 0,
            has_tanwin_kasr INTEGER DEFAULT 0,
            has_tanwin_damm INTEGER DEFAULT 0,
            has_maddah INTEGER DEFAULT 0,
            has_hamza_above INTEGER DEFAULT 0,
            has_hamza_below INTEGER DEFAULT 0,
            has_superscript_alef INTEGER DEFAULT 0,
            has_subscript_alef INTEGER DEFAULT 0,
            has_small_high_alef INTEGER DEFAULT 0,
            has_small_high_meem INTEGER DEFAULT 0,
            has_small_high_jeem INTEGER DEFAULT 0,
            has_small_high_three_dots INTEGER DEFAULT 0,
            has_small_high_seen INTEGER DEFAULT 0,
            has_small_high_rounded_zero INTEGER DEFAULT 0,
            has_small_high_upright_zero INTEGER DEFAULT 0,
            has_small_high_dotless_head INTEGER DEFAULT 0,
            has_small_low_meem INTEGER DEFAULT 0,
            letter_type TEXT,
            is_hamza_variant INTEGER DEFAULT 0,
            source_db TEXT,
            UNIQUE(word_id, letter_index)
        );
    """)
    
    # Create indexes
    indexes = [
        "CREATE INDEX idx_letter_breakdown_word ON letter_breakdown(word_id);",
        "CREATE INDEX idx_letter_breakdown_verse ON letter_breakdown(verse_key);",
        "CREATE INDEX idx_letter_breakdown_base_letter ON letter_breakdown(base_letter);",
        "CREATE INDEX idx_letter_breakdown_has_shadda ON letter_breakdown(has_shadda);",
        "CREATE INDEX idx_letter_breakdown_has_fatha ON letter_breakdown(has_fatha);",
        "CREATE INDEX idx_letter_breakdown_has_kasra ON letter_breakdown(has_kasra);",
        "CREATE INDEX idx_letter_breakdown_has_damma ON letter_breakdown(has_damma);",
        "CREATE INDEX idx_letter_breakdown_word_letter ON letter_breakdown(word_id, letter_index);",
    ]
    
    for idx_sql in indexes:
        cursor.execute(idx_sql)
    
    conn.commit()
    print("✓ Created letter_breakdown table with indexes")


def populate_letter_breakdown(conn: sqlite3.Connection):
    """Populate the letter_breakdown table from mushaf_pages data"""
    cursor = conn.cursor()
    
    # Get all words from mushaf_pages
    cursor.execute("""
        SELECT word_id, verse_key, arabic_text 
        FROM mushaf_pages 
        ORDER BY word_id;
    """)
    
    words = cursor.fetchall()
    total_words = len(words)
    print(f"Processing {total_words:,} words...")
    
    # Prepare insert statement
    insert_sql = """
        INSERT INTO letter_breakdown (
            word_id, verse_key, word_position, letter_index, letter_position,
            base_letter, letter_with_diacritics, base_letter_codepoint,
            base_letter_category, base_letter_name, diacritics_json,
            has_fatha, has_kasra, has_damma, has_sukun, has_shadda,
            has_tanwin_fath, has_tanwin_kasr, has_tanwin_damm,
            has_maddah, has_hamza_above, has_hamza_below,
            has_superscript_alef, has_subscript_alef,
            has_small_high_alef, has_small_high_meem, has_small_high_jeem,
            has_small_high_three_dots, has_small_high_seen,
            has_small_high_rounded_zero, has_small_high_upright_zero,
            has_small_high_dotless_head, has_small_low_meem,
            letter_type, is_hamza_variant, source_db
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    """
    
    total_letters = 0
    batch_size = 1000
    batch = []
    
    for i, (word_id, verse_key, arabic_text) in enumerate(words):
        # Parse word position from verse_key (this is simplified)
        word_position = i + 1  # Will be calculated properly per verse
        
        breakdowns = create_letter_breakdown(
            word_id=word_id,
            verse_key=verse_key,
            word_position=word_position,
            word_text=arabic_text
        )
        
        for bd in breakdowns:
            batch.append((
                bd.word_id, bd.verse_key, bd.word_position, bd.letter_index,
                bd.letter_position, bd.base_letter, bd.letter_with_diacritics,
                bd.base_letter_codepoint, bd.base_letter_category, bd.base_letter_name,
                bd.diacritics_json,
                int(bd.has_fatha), int(bd.has_kasra), int(bd.has_damma),
                int(bd.has_sukun), int(bd.has_shadda),
                int(bd.has_tanwin_fath), int(bd.has_tanwin_kasr), int(bd.has_tanwin_damm),
                int(bd.has_maddah), int(bd.has_hamza_above), int(bd.has_hamza_below),
                int(bd.has_superscript_alef), int(bd.has_subscript_alef),
                int(bd.has_small_high_alef), int(bd.has_small_high_meem),
                int(bd.has_small_high_jeem), int(bd.has_small_high_three_dots),
                int(bd.has_small_high_seen), int(bd.has_small_high_rounded_zero),
                int(bd.has_small_high_upright_zero), int(bd.has_small_high_dotless_head),
                int(bd.has_small_low_meem),
                bd.letter_type, int(bd.is_hamza_variant), bd.source_db
            ))
            total_letters += 1
        
        # Insert in batches
        if len(batch) >= batch_size:
            cursor.executemany(insert_sql, batch)
            conn.commit()
            batch = []
            if (i + 1) % 10000 == 0:
                print(f"  Processed {i + 1:,}/{total_words:,} words ({total_letters:,} letters)")
    
    # Insert remaining
    if batch:
        cursor.executemany(insert_sql, batch)
        conn.commit()
    
    print(f"✓ Inserted {total_letters:,} letter breakdowns")
    return total_letters


def update_word_positions(conn: sqlite3.Connection):
    """Update word_position to be per-verse rather than global"""
    cursor = conn.cursor()
    
    print("Updating word positions per verse...")
    
    # Get distinct verses
    cursor.execute("SELECT DISTINCT verse_key FROM letter_breakdown ORDER BY verse_key;")
    verses = [row[0] for row in cursor.fetchall()]
    
    for verse_key in verses:
        # Get unique word_ids for this verse in order
        cursor.execute("""
            SELECT DISTINCT word_id 
            FROM letter_breakdown 
            WHERE verse_key = ? 
            ORDER BY word_id;
        """, (verse_key,))
        
        word_ids = [row[0] for row in cursor.fetchall()]
        
        # Update positions
        for position, word_id in enumerate(word_ids, 1):
            cursor.execute("""
                UPDATE letter_breakdown 
                SET word_position = ? 
                WHERE word_id = ? AND verse_key = ?;
            """, (position, word_id, verse_key))
    
    conn.commit()
    print("✓ Updated word positions")


def verify_results(conn: sqlite3.Connection):
    """Verify the generated data"""
    cursor = conn.cursor()
    
    print("\n" + "=" * 60)
    print("Verification Results")
    print("=" * 60)
    
    # Count statistics
    cursor.execute("SELECT COUNT(*) FROM letter_breakdown;")
    total_letters = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(DISTINCT word_id) FROM letter_breakdown;")
    total_words = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(DISTINCT verse_key) FROM letter_breakdown;")
    total_verses = cursor.fetchone()[0]
    
    print(f"\nTotal Statistics:")
    print(f"  - Total letters: {total_letters:,}")
    print(f"  - Total words covered: {total_words:,}")
    print(f"  - Total verses: {total_verses}")
    
    # Sample breakdowns
    print(f"\nSample Breakdowns:")
    
    cursor.execute("""
        SELECT word_id, verse_key, base_letter, letter_with_diacritics, 
               diacritics_json, has_shadda, has_fatha
        FROM letter_breakdown 
        WHERE word_id = 1
        ORDER BY letter_index;
    """)
    
    print("\n  Word ID 1 (بِسۡمِ):")
    for row in cursor.fetchall():
        word_id, verse_key, base, with_diac, diac_json, shadda, fatha = row
        diac_info = json.loads(diac_json) if diac_json else []
        diac_chars = ''.join(d['char'] for d in diac_info)
        flags = []
        if shadda: flags.append('shadda')
        if fatha: flags.append('fatha')
        print(f"    [{base}] + [{diac_chars}] = {with_diac} ({', '.join(flags) if flags else 'no flags'})")
    
    # Diacritic statistics
    print(f"\nDiacritic Statistics:")
    
    diacritic_counts = [
        ('has_shadda', 'Shadda'),
        ('has_fatha', 'Fatha'),
        ('has_kasra', 'Kasra'),
        ('has_damma', 'Damma'),
        ('has_sukun', 'Sukun'),
        ('has_tanwin_fath', 'Tanwin Fath'),
        ('has_tanwin_kasr', 'Tanwin Kasr'),
        ('has_tanwin_damm', 'Tanwin Damm'),
        ('has_maddah', 'Maddah'),
        ('has_superscript_alef', 'Superscript Alef'),
        ('has_subscript_alef', 'Subscript Alef'),
    ]
    
    for column, name in diacritic_counts:
        cursor.execute(f"SELECT COUNT(*) FROM letter_breakdown WHERE {column} = 1;")
        count = cursor.fetchone()[0]
        percentage = (count / total_letters) * 100 if total_letters > 0 else 0
        print(f"  - {name}: {count:,} ({percentage:.2f}%)")
    
    # Letter frequency
    print(f"\nTop 10 Most Frequent Base Letters:")
    cursor.execute("""
        SELECT base_letter, COUNT(*) as count 
        FROM letter_breakdown 
        GROUP BY base_letter 
        ORDER BY count DESC 
        LIMIT 10;
    """)
    
    for base_letter, count in cursor.fetchall():
        percentage = (count / total_letters) * 100
        print(f"  - {base_letter}: {count:,} ({percentage:.2f}%)")


def main():
    """Main entry point"""
    print("=" * 60)
    print("Quran Letter Breakdown Generator")
    print("=" * 60)
    
    # Check if database exists
    if not OUTPUT_DB.exists():
        print(f"\n✗ Error: Database not found: {OUTPUT_DB}")
        print("Please run merge_quran_dbs.py first to create the database.")
        return 1
    
    try:
        # Connect to database
        conn = sqlite3.connect(OUTPUT_DB)
        print(f"✓ Connected to database: {OUTPUT_DB}")
        
        # Create table
        create_letter_breakdown_table(conn)
        
        # Populate data
        populate_letter_breakdown(conn)
        
        # Update word positions
        update_word_positions(conn)
        
        # Verify results
        verify_results(conn)
        
        # Close connection
        conn.close()
        
        print("\n" + "=" * 60)
        print("Letter Breakdown Generation Complete!")
        print("=" * 60)
        print(f"Database: {OUTPUT_DB}")
        print(f"Table: letter_breakdown")
        print("=" * 60)
        
        return 0
        
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
