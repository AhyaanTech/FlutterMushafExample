#!/usr/bin/env python3
"""Data integrity validators for the Quran database.

Ensures data correctness by verifying:
1. Letter concatenation matches word text
2. Word concatenation matches ayah text (when available)
3. Foreign key integrity
4. Count consistency across tables
"""

import sqlite3
import unicodedata
from typing import List, Tuple, Optional
from dataclasses import dataclass
from collections import defaultdict

from .config import (
    TABLE_WORDS, TABLE_AYAHS, TABLE_SURAHS,
    TABLE_MUSHAF_PAGES, TABLE_LETTER_BREAKDOWN,
    TOTAL_SURAHS
)


@dataclass
class ValidationResult:
    """Result of a validation test."""
    name: str
    passed: bool
    message: str
    details: Optional[str] = None


class DatabaseValidator:
    """Validates Quran database integrity."""
    
    def __init__(self, conn: sqlite3.Connection):
        self.conn = conn
        self.cursor = conn.cursor()
        self.results: List[ValidationResult] = []
    
    def validate_all(self) -> List[ValidationResult]:
        """Run all validation tests."""
        print("\n" + "=" * 60)
        print("Running Data Integrity Tests")
        print("=" * 60)
        
        # Basic counts
        self._validate_word_count()
        self._validate_ayah_count()
        self._validate_surah_count()
        
        # Cross-table consistency
        self._validate_ayah_word_ranges()
        self._validate_mushaf_page_references()
        
        # Text integrity
        self._validate_letter_to_word_concatenation()
        
        # Check for orphaned records
        self._validate_foreign_key_integrity()
        
        return self.results
    
    def print_summary(self) -> bool:
        """Print validation summary. Returns True if all passed."""
        print("\n" + "=" * 60)
        print("Validation Summary")
        print("=" * 60)
        
        passed = sum(1 for r in self.results if r.passed)
        failed = len(self.results) - passed
        
        for result in self.results:
            status = "[PASS]" if result.passed else "[FAIL]"
            print(f"\n{status} {result.name}")
            print(f"       {result.message}")
            if result.details:
                print(f"       {result.details}")
        
        print("\n" + "-" * 60)
        print(f"Results: {passed} passed, {failed} failed")
        print("=" * 60)
        
        return failed == 0
    
    def _validate_word_count(self) -> None:
        """Check word count is reasonable."""
        count = self.cursor.execute(f"SELECT COUNT(*) FROM {TABLE_WORDS}").fetchone()[0]
        
        # Expected: ~83,668 words in Quran
        expected_min = 80000
        expected_max = 90000
        
        passed = expected_min <= count <= expected_max
        self.results.append(ValidationResult(
            name="Word Count",
            passed=passed,
            message=f"Found {count:,} words" + 
                    (f" (expected {expected_min:,}-{expected_max:,})" if not passed else ""),
            details=None if passed else f"Count outside expected range"
        ))
    
    def _validate_ayah_count(self) -> None:
        """Check ayah count is exactly 6236."""
        count = self.cursor.execute(f"SELECT COUNT(*) FROM {TABLE_AYAHS}").fetchone()[0]
        expected = 6236
        
        passed = count == expected
        self.results.append(ValidationResult(
            name="Ayah Count",
            passed=passed,
            message=f"Found {count:,} ayahs (expected {expected:,})",
            details=None if passed else f"Mismatch: got {count}, expected {expected}"
        ))
    
    def _validate_surah_count(self) -> None:
        """Check surah count is exactly 114."""
        count = self.cursor.execute(f"SELECT COUNT(*) FROM {TABLE_SURAHS}").fetchone()[0]
        expected = TOTAL_SURAHS
        
        passed = count == expected
        self.results.append(ValidationResult(
            name="Surah Count",
            passed=passed,
            message=f"Found {count} surahs (expected {expected})",
            details=None if passed else f"Mismatch: got {count}, expected {expected}"
        ))
    
    def _validate_ayah_word_ranges(self) -> None:
        """Verify ayah word ranges are consistent."""
        issues = []
        
        # Check that first_word_id < last_word_id for all ayahs
        inconsistent = self.cursor.execute(f"""
            SELECT verse_key, first_word_id, last_word_id
            FROM {TABLE_AYAHS}
            WHERE first_word_id > last_word_id
            LIMIT 5;
        """).fetchall()
        
        if inconsistent:
            issues.append(f"{len(inconsistent)} ayahs with inverted word ranges")
        
        # Check word counts match actual word count
        mismatches = self.cursor.execute(f"""
            SELECT a.verse_key, a.word_count, COUNT(w.id) as actual
            FROM {TABLE_AYAHS} a
            LEFT JOIN {TABLE_WORDS} w ON w.verse_key = a.verse_key
            GROUP BY a.verse_key
            HAVING a.word_count != COUNT(w.id)
            LIMIT 5;
        """).fetchall()
        
        if mismatches:
            issues.append(f"{len(mismatches)} ayahs with mismatched word counts")
        
        passed = len(issues) == 0
        self.results.append(ValidationResult(
            name="Ayah Word Ranges",
            passed=passed,
            message="Word ranges consistent" if passed else f"Found {len(issues)} issues",
            details="; ".join(issues) if issues else None
        ))
    
    def _validate_mushaf_page_references(self) -> None:
        """Verify all mushaf_pages reference valid words."""
        orphaned = self.cursor.execute(f"""
            SELECT COUNT(*) 
            FROM {TABLE_MUSHAF_PAGES} mp
            LEFT JOIN {TABLE_WORDS} w ON w.id = mp.word_id
            WHERE w.id IS NULL;
        """).fetchone()[0]
        
        passed = orphaned == 0
        self.results.append(ValidationResult(
            name="Mushaf Page References",
            passed=passed,
            message=f"All {TABLE_MUSHAF_PAGES} entries reference valid words" if passed else f"{orphaned} orphaned entries",
            details=None if passed else f"Found {orphaned} entries without matching words"
        ))
    
    def _validate_letter_to_word_concatenation(self) -> None:
        """CRITICAL: Verify concatenating letters forms the original word."""
        print("\n[TEST] Letter-to-Word Concatenation (this may take a moment)...")
        
        # Check if letter_breakdown table exists
        table_exists = self.cursor.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name=?
        """, (TABLE_LETTER_BREAKDOWN,)).fetchone()
        
        if not table_exists:
            self.results.append(ValidationResult(
                name="Letter Concatenation",
                passed=False,
                message="letter_breakdown table not found",
                details="Run letter breakdown generator first"
            ))
            return
        
        # Sample some words to verify
        # We check: base_letters + diacritics should match word.text
        sample_size = 1000
        
        mismatches = []
        samples = self.cursor.execute(f"""
            SELECT 
                w.id,
                w.text as word_text,
                GROUP_CONCAT(lb.letter_with_diacritics, '') as letters_concat
            FROM {TABLE_WORDS} w
            JOIN {TABLE_LETTER_BREAKDOWN} lb ON lb.word_id = w.id
            WHERE w.id IN (SELECT id FROM {TABLE_WORDS} ORDER BY RANDOM() LIMIT ?)
            GROUP BY w.id
            HAVING letters_concat != word_text
            LIMIT 10;
        """, (sample_size,)).fetchall()
        
        if samples:
            for row in samples:
                mismatches.append(f"word_id={row[0]}: '{row[1]}' != '{row[2]}'")
        
        passed = len(mismatches) == 0
        self.results.append(ValidationResult(
            name="Letter Concatenation",
            passed=passed,
            message=f"Sampled {sample_size} words: letters form words correctly" if passed else f"Found {len(mismatches)} mismatches in sample",
            details="; ".join(mismatches[:3]) if mismatches else None
        ))
    
    def _validate_foreign_key_integrity(self) -> None:
        """Check for orphaned records across tables."""
        issues = []
        
        # Check mushaf_pages -> words
        orphaned_mp = self.cursor.execute(f"""
            SELECT COUNT(*) FROM {TABLE_MUSHAF_PAGES} mp
            WHERE NOT EXISTS (SELECT 1 FROM {TABLE_WORDS} w WHERE w.id = mp.word_id);
        """).fetchone()[0]
        
        if orphaned_mp:
            issues.append(f"{orphaned_mp} orphaned mushaf_pages")
        
        # Check letter_breakdown -> words (if exists)
        table_exists = self.cursor.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name=?
        """, (TABLE_LETTER_BREAKDOWN,)).fetchone()
        
        if table_exists:
            orphaned_lb = self.cursor.execute(f"""
                SELECT COUNT(*) FROM {TABLE_LETTER_BREAKDOWN} lb
                WHERE NOT EXISTS (SELECT 1 FROM {TABLE_WORDS} w WHERE w.id = lb.word_id);
            """).fetchone()[0]
            
            if orphaned_lb:
                issues.append(f"{orphaned_lb} orphaned letter_breakdown entries")
        
        passed = len(issues) == 0
        self.results.append(ValidationResult(
            name="Foreign Key Integrity",
            passed=passed,
            message="All foreign keys valid" if passed else f"Found {len(issues)} issues",
            details="; ".join(issues) if issues else None
        ))
    
    def validate_complete_ayah_reconstruction(self, sample_size: int = 10) -> ValidationResult:
        """Validate that words concatenate to form complete ayah text.
        
        NOTE: This requires ayahs.text to be populated first.
        """
        # Check if ayahs have text
        has_text = self.cursor.execute(f"""
            SELECT COUNT(*) FROM {TABLE_AYAHS} WHERE text IS NOT NULL AND text != ''
        """).fetchone()[0]
        
        if has_text == 0:
            return ValidationResult(
                name="Ayah Reconstruction",
                passed=True,  # Not a failure, just not tested
                message="Ayah text not populated (skipping test)",
                details="Populate ayahs.text to enable this validation"
            )
        
        mismatches = []
        
        # Sample some ayahs
        samples = self.cursor.execute(f"""
            SELECT 
                a.verse_key,
                a.text as ayah_text,
                GROUP_CONCAT(w.text, ' ') as words_concat
            FROM {TABLE_AYAHS} a
            JOIN {TABLE_WORDS} w ON w.verse_key = a.verse_key
            WHERE a.text IS NOT NULL
            GROUP BY a.verse_key
            ORDER BY RANDOM()
            LIMIT ?;
        """, (sample_size,)).fetchall()
        
        for row in samples:
            verse_key, ayah_text, words_concat = row
            # Normalize both for comparison (remove extra spaces)
            ayah_clean = " ".join(ayah_text.split())
            words_clean = " ".join(words_concat.split()) if words_concat else ""
            
            if ayah_clean != words_clean:
                mismatches.append(f"{verse_key}: word concat doesn't match ayah text")
        
        passed = len(mismatches) == 0
        return ValidationResult(
            name="Ayah Reconstruction",
            passed=passed,
            message=f"Sampled {len(samples)} ayahs" if passed else f"Found {len(mismatches)} mismatches",
            details="; ".join(mismatches[:3]) if mismatches else None
        )
