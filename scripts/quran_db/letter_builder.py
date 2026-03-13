#!/usr/bin/env python3
"""Letter breakdown table builder.

Segments each word into individual Arabic letters with diacritics.
This is a separate step that can be run after the core tables are built.
"""

import json
import unicodedata
import sqlite3
from typing import List, Tuple, Optional
from dataclasses import dataclass

from .config import TABLE_WORDS, TABLE_LETTER_BREAKDOWN, DIACRITIC_TYPES


@dataclass
class DiacriticInfo:
    """Information about a single diacritic mark."""
    char: str
    codepoint: int
    name: str
    category: str
    type: str


@dataclass
class LetterBreakdown:
    """Represents a single letter with its diacritics."""
    word_id: int
    verse_key: str
    word_position: int
    letter_index: int
    base_letter: str
    letter_with_diacritics: str
    diacritics: List[DiacriticInfo]
    
    # Computed flags
    flags: dict


class LetterBreakdownBuilder:
    """Builds the letter_breakdown table."""
    
    def __init__(self, conn: sqlite3.Connection):
        self.conn = conn
        self.cursor = conn.cursor()
        self.stats = {
            "words_processed": 0,
            "letters_inserted": 0,
        }
    
    def build(self) -> dict:
        """Build the letter_breakdown table."""
        print("\n" + "=" * 60)
        print("Building Letter Breakdown Table")
        print("=" * 60)
        
        self._create_table()
        self._populate_table()
        self._update_word_positions()
        
        return self.stats
    
    def _create_table(self) -> None:
        """Create letter_breakdown table with all columns."""
        print("\n[1/3] Creating table...")
        
        # Drop existing
        self.cursor.execute(f"DROP TABLE IF EXISTS {TABLE_LETTER_BREAKDOWN};")
        
        # Create with all flag columns
        flags_sql = ",\n            ".join([
                f"{flag} INTEGER DEFAULT 0"
                for flag in [
                    "has_fatha", "has_kasra", "has_damma", "has_sukun", "has_shadda",
                    "has_tanwin_fath", "has_tanwin_kasr", "has_tanwin_damm",
                    "has_maddah", "has_hamza_above", "has_hamza_below",
                    "has_superscript_alef", "has_subscript_alef",
                    "has_small_high_alef", "has_small_high_meem", "has_small_high_jeem",
                    "has_small_high_three_dots", "has_small_high_seen",
                    "has_small_high_rounded_zero", "has_small_high_upright_zero",
                    "has_small_high_dotless_head", "has_small_low_meem",
                ]
            ])
        
        self.cursor.execute(f"""
            CREATE TABLE {TABLE_LETTER_BREAKDOWN} (
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
                {flags_sql},
                letter_type TEXT,
                is_hamza_variant INTEGER DEFAULT 0,
                source_db TEXT,
                UNIQUE(word_id, letter_index)
            );
        """)
        
        # Create indexes
        indexes = [
            f"CREATE INDEX idx_{TABLE_LETTER_BREAKDOWN}_word ON {TABLE_LETTER_BREAKDOWN}(word_id);",
            f"CREATE INDEX idx_{TABLE_LETTER_BREAKDOWN}_verse ON {TABLE_LETTER_BREAKDOWN}(verse_key);",
            f"CREATE INDEX idx_{TABLE_LETTER_BREAKDOWN}_base ON {TABLE_LETTER_BREAKDOWN}(base_letter);",
            f"CREATE INDEX idx_{TABLE_LETTER_BREAKDOWN}_shadda ON {TABLE_LETTER_BREAKDOWN}(has_shadda);",
        ]
        for idx_sql in indexes:
            self.cursor.execute(idx_sql)
        
        print("    [OK] Table created with indexes")
    
    def _populate_table(self) -> None:
        """Populate table by segmenting all words."""
        print("\n[2/3] Segmenting words into letters...")
        
        # Get all words
        self.cursor.execute(f"""
            SELECT id, verse_key, text 
            FROM {TABLE_WORDS} 
            ORDER BY id;
        """)
        words = self.cursor.fetchall()
        
        total_words = len(words)
        print(f"    Processing {total_words:,} words...")
        
        # Prepare insert
        insert_sql = self._get_insert_sql()
        
        batch = []
        batch_size = 1000
        total_letters = 0
        
        for i, (word_id, verse_key, text) in enumerate(words):
            letters = self._segment_word(word_id, verse_key, text)
            
            for letter in letters:
                batch.append(self._letter_to_tuple(letter))
                total_letters += 1
            
            if len(batch) >= batch_size:
                self.cursor.executemany(insert_sql, batch)
                self.conn.commit()
                batch = []
                
                if (i + 1) % 10000 == 0:
                    print(f"      Progress: {i + 1:,}/{total_words:,} words")
        
        # Insert remaining
        if batch:
            self.cursor.executemany(insert_sql, batch)
            self.conn.commit()
        
        self.stats["words_processed"] = total_words
        self.stats["letters_inserted"] = total_letters
        print(f"    [OK] Inserted {total_letters:,} letters")
    
    def _segment_word(self, word_id: int, verse_key: str, text: str) -> List[LetterBreakdown]:
        """Segment a word into individual letters."""
        letters = []
        current_base: Optional[str] = None
        current_diacritics: List[DiacriticInfo] = []
        letter_index = 0
        
        for char in text:
            codepoint = ord(char)
            category = unicodedata.category(char)
            
            if category == 'Lo':  # Base Arabic letter
                # Save previous letter
                if current_base is not None:
                    letters.append(self._create_letter(
                        word_id, verse_key, letter_index, 
                        current_base, current_diacritics
                    ))
                    letter_index += 1
                
                # Start new letter
                current_base = char
                current_diacritics = []
                
            elif category in ('Mn', 'Me', 'Cf'):  # Diacritic marks
                diacritic = self._classify_diacritic(char, codepoint)
                current_diacritics.append(diacritic)
                
            elif category == 'Nd':  # Decimal digit
                if current_base is not None:
                    letters.append(self._create_letter(
                        word_id, verse_key, letter_index,
                        current_base, current_diacritics
                    ))
                    letter_index += 1
                letters.append(self._create_letter(
                    word_id, verse_key, letter_index, char, []
                ))
                letter_index += 1
                current_base = None
                current_diacritics = []
                
            else:  # Other characters
                if current_base is not None:
                    letters.append(self._create_letter(
                        word_id, verse_key, letter_index,
                        current_base, current_diacritics
                    ))
                    letter_index += 1
                current_base = char
                current_diacritics = []
        
        # Don't forget last letter
        if current_base is not None:
            letters.append(self._create_letter(
                word_id, verse_key, letter_index,
                current_base, current_diacritics
            ))
        
        return letters
    
    def _create_letter(self, word_id: int, verse_key: str, letter_index: int,
                       base: str, diacritics: List[DiacriticInfo]) -> LetterBreakdown:
        """Create a LetterBreakdown object."""
        # Build letter with diacritics
        letter_with_diac = base + ''.join(d.char for d in diacritics)
        
        # Compute flags
        flags = self._compute_flags(diacritics)
        
        # Get base letter info
        base_name = unicodedata.name(base, 'UNKNOWN')
        letter_type = self._get_letter_type(base_name)
        is_hamza = 'HAMZA' in base_name or 'WASLA' in base_name or 'MADDA' in base_name
        
        # Add to flags
        flags['letter_type'] = letter_type
        flags['is_hamza_variant'] = 1 if is_hamza else 0
        
        return LetterBreakdown(
            word_id=word_id,
            verse_key=verse_key,
            word_position=0,  # Updated later
            letter_index=letter_index,
            base_letter=base,
            letter_with_diacritics=letter_with_diac,
            diacritics=diacritics,
            flags=flags
        )
    
    def _classify_diacritic(self, char: str, codepoint: int) -> DiacriticInfo:
        """Classify a diacritic character."""
        name = unicodedata.name(char, 'UNKNOWN')
        category = unicodedata.category(char)
        
        if codepoint in DIACRITIC_TYPES:
            dtype, _ = DIACRITIC_TYPES[codepoint]
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
    
    def _compute_flags(self, diacritics: List[DiacriticInfo]) -> dict:
        """Compute boolean flags from diacritics."""
        flags = {flag: 0 for flag in [
            "has_fatha", "has_kasra", "has_damma", "has_sukun", "has_shadda",
            "has_tanwin_fath", "has_tanwin_kasr", "has_tanwin_damm",
            "has_maddah", "has_hamza_above", "has_hamza_below",
            "has_superscript_alef", "has_subscript_alef",
            "has_small_high_alef", "has_small_high_meem", "has_small_high_jeem",
            "has_small_high_three_dots", "has_small_high_seen",
            "has_small_high_rounded_zero", "has_small_high_upright_zero",
            "has_small_high_dotless_head", "has_small_low_meem",
        ]}
        
        for d in diacritics:
            cp = d.codepoint
            if cp == 0x064E: flags["has_fatha"] = 1
            elif cp == 0x0650: flags["has_kasra"] = 1
            elif cp == 0x064F: flags["has_damma"] = 1
            elif cp == 0x0652: flags["has_sukun"] = 1
            elif cp == 0x0651: flags["has_shadda"] = 1
            elif cp == 0x064B: flags["has_tanwin_fath"] = 1
            elif cp == 0x064D: flags["has_tanwin_kasr"] = 1
            elif cp == 0x064C: flags["has_tanwin_damm"] = 1
            elif cp == 0x0653: flags["has_maddah"] = 1
            elif cp == 0x0654: flags["has_hamza_above"] = 1
            elif cp == 0x0655: flags["has_hamza_below"] = 1
            elif cp == 0x0670: flags["has_superscript_alef"] = 1
            elif cp == 0x0656: flags["has_subscript_alef"] = 1
            elif cp in (0x06D6, 0x06D7, 0x06D8): flags["has_small_high_alef"] = 1
            elif cp == 0x06E2: flags["has_small_high_meem"] = 1
            elif cp == 0x06DA: flags["has_small_high_jeem"] = 1
            elif cp == 0x06DB: flags["has_small_high_three_dots"] = 1
            elif cp == 0x06DC: flags["has_small_high_seen"] = 1
            elif cp == 0x06DF: flags["has_small_high_rounded_zero"] = 1
            elif cp == 0x06E0: flags["has_small_high_upright_zero"] = 1
            elif cp == 0x06E1: flags["has_small_high_dotless_head"] = 1
            elif cp == 0x06ED: flags["has_small_low_meem"] = 1
        
        return flags
    
    def _get_letter_type(self, name: str) -> str:
        """Determine letter type from Unicode name."""
        vowel_carriers = ['ARABIC LETTER ALEF', 'ARABIC LETTER ALEF WITH']
        if any(vc in name for vc in vowel_carriers):
            return 'vowel_carrier'
        if 'WAW' in name or 'YEH' in name or 'ALEF MAKSURA' in name:
            return 'long_vowel'
        return 'consonant'
    
    def _get_insert_sql(self) -> str:
        """Generate INSERT SQL statement."""
        columns = [
            "word_id", "verse_key", "word_position", "letter_index", "letter_position",
            "base_letter", "letter_with_diacritics", "base_letter_codepoint",
            "base_letter_category", "base_letter_name", "diacritics_json",
            "has_fatha", "has_kasra", "has_damma", "has_sukun", "has_shadda",
            "has_tanwin_fath", "has_tanwin_kasr", "has_tanwin_damm",
            "has_maddah", "has_hamza_above", "has_hamza_below",
            "has_superscript_alef", "has_subscript_alef",
            "has_small_high_alef", "has_small_high_meem", "has_small_high_jeem",
            "has_small_high_three_dots", "has_small_high_seen",
            "has_small_high_rounded_zero", "has_small_high_upright_zero",
            "has_small_high_dotless_head", "has_small_low_meem",
            "letter_type", "is_hamza_variant", "source_db"
        ]
        placeholders = ", ".join(["?"] * len(columns))
        return f"INSERT INTO {TABLE_LETTER_BREAKDOWN} ({', '.join(columns)}) VALUES ({placeholders});"
    
    def _letter_to_tuple(self, letter: LetterBreakdown) -> tuple:
        """Convert LetterBreakdown to tuple for insertion."""
        diacritics_json = json.dumps([
            {"char": d.char, "codepoint": d.codepoint, "name": d.name, "type": d.type}
            for d in letter.diacritics
        ], ensure_ascii=False)
        
        base_cp = ord(letter.base_letter)
        base_cat = unicodedata.category(letter.base_letter)
        base_name = unicodedata.name(letter.base_letter, 'UNKNOWN')
        
        return (
            letter.word_id,
            letter.verse_key,
            letter.word_position,
            letter.letter_index,
            letter.letter_index,  # letter_position same as index
            letter.base_letter,
            letter.letter_with_diacritics,
            base_cp,
            base_cat,
            base_name,
            diacritics_json,
            # Flags
            letter.flags.get("has_fatha", 0),
            letter.flags.get("has_kasra", 0),
            letter.flags.get("has_damma", 0),
            letter.flags.get("has_sukun", 0),
            letter.flags.get("has_shadda", 0),
            letter.flags.get("has_tanwin_fath", 0),
            letter.flags.get("has_tanwin_kasr", 0),
            letter.flags.get("has_tanwin_damm", 0),
            letter.flags.get("has_maddah", 0),
            letter.flags.get("has_hamza_above", 0),
            letter.flags.get("has_hamza_below", 0),
            letter.flags.get("has_superscript_alef", 0),
            letter.flags.get("has_subscript_alef", 0),
            letter.flags.get("has_small_high_alef", 0),
            letter.flags.get("has_small_high_meem", 0),
            letter.flags.get("has_small_high_jeem", 0),
            letter.flags.get("has_small_high_three_dots", 0),
            letter.flags.get("has_small_high_seen", 0),
            letter.flags.get("has_small_high_rounded_zero", 0),
            letter.flags.get("has_small_high_upright_zero", 0),
            letter.flags.get("has_small_high_dotless_head", 0),
            letter.flags.get("has_small_low_meem", 0),
            letter.flags.get("letter_type", "consonant"),
            letter.flags.get("is_hamza_variant", 0),
            "qpc-hafs-word-by-word.db"
        )
    
    def _update_word_positions(self) -> None:
        """Update word_position to be per-verse rather than global."""
        print("\n[3/3] Updating word positions per verse...")
        
        # Get distinct verses
        self.cursor.execute(f"SELECT DISTINCT verse_key FROM {TABLE_LETTER_BREAKDOWN} ORDER BY verse_key;")
        verses = [row[0] for row in self.cursor.fetchall()]
        
        for verse_key in verses:
            # Get unique word_ids for this verse
            self.cursor.execute(f"""
                SELECT DISTINCT word_id 
                FROM {TABLE_LETTER_BREAKDOWN} 
                WHERE verse_key = ? 
                ORDER BY word_id;
            """, (verse_key,))
            
            word_ids = [row[0] for row in self.cursor.fetchall()]
            
            # Update positions
            for position, word_id in enumerate(word_ids, 1):
                self.cursor.execute(f"""
                    UPDATE {TABLE_LETTER_BREAKDOWN} 
                    SET word_position = ? 
                    WHERE word_id = ? AND verse_key = ?;
                """, (position, word_id, verse_key))
        
        self.conn.commit()
        print("    [OK] Word positions updated")
