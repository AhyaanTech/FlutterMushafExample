#!/usr/bin/env python3
"""Database connection and utility functions."""

import sqlite3
import shutil
from pathlib import Path
from typing import Optional
from contextlib import contextmanager

from .config import DB_DIR, OUTPUT_DB, DB_TAJWEED


def ensure_directories() -> None:
    """Create output directories if they don't exist."""
    DB_DIR.mkdir(parents=True, exist_ok=True)


def validate_source_db(path: Path, name: str) -> None:
    """Validate that a source database exists."""
    if not path.exists():
        raise FileNotFoundError(f"{name} database not found: {path}")


@contextmanager
def connect(db_path: Path, readonly: bool = False):
    """Context manager for database connections."""
    uri = f"file:{db_path}" if readonly else str(db_path)
    conn = sqlite3.connect(uri, uri=readonly)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()


@contextmanager
def connect_output():
    """Connect to output database."""
    ensure_directories()
    conn = sqlite3.connect(OUTPUT_DB)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()


def init_output_db() -> None:
    """Initialize fresh output database."""
    ensure_directories()
    if OUTPUT_DB.exists():
        OUTPUT_DB.unlink()
        print(f"[OK] Removed existing database")


def attach_source_databases(conn: sqlite3.Connection) -> None:
    """Attach source databases to connection."""
    from .config import DB_WORDS, DB_LAYOUT, DB_TAJWEED
    cursor = conn.cursor()
    cursor.execute(f"ATTACH DATABASE ? AS words_db", (str(DB_WORDS),))
    cursor.execute(f"ATTACH DATABASE ? AS layout_db", (str(DB_LAYOUT),))
    # Tajweed database is optional
    if DB_TAJWEED.exists():
        cursor.execute(f"ATTACH DATABASE ? AS tajweed_db", (str(DB_TAJWEED),))


def get_table_count(conn: sqlite3.Connection, table: str) -> int:
    """Get row count for a table."""
    cursor = conn.cursor()
    cursor.execute(f"SELECT COUNT(*) FROM {table}")
    return cursor.fetchone()[0]


def get_schema_info(conn: sqlite3.Connection) -> dict:
    """Get schema information for all tables."""
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
    tables = {}
    for (name,) in cursor.fetchall():
        if name.startswith("sqlite"):
            continue
        cursor.execute(f"PRAGMA table_info({name})")
        tables[name] = [row[1] for row in cursor.fetchall()]
    return tables
