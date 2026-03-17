import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/quran_letter.dart';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._init();
  
  DatabaseHelper._init();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }
  
  Future<Database> _initDB() async {
    // Initialize FFI for desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    final dbPath = await _getDatabasePath();
    
    // Check if database exists
    if (!await File(dbPath).exists()) {
      // Copy from assets
      await _copyDatabaseFromAssets(dbPath);
    }
    
    return await openDatabase(dbPath);
  }
  
  Future<String> _getDatabasePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return join(directory.path, 'quran_offline.db');
  }
  
  Future<void> _copyDatabaseFromAssets(String dbPath) async {
    final data = await rootBundle.load('assets/db/quran_offline.db');
    final bytes = data.buffer.asUint8List();
    await File(dbPath).writeAsBytes(bytes);
  }
  
  // Get raw page data from mushaf_pages and words tables
  Future<List<Map<String, dynamic>>> getPageData(int pageNumber) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        mp.page_number,
        mp.line_number,
        mp.word_id,
        mp.verse_key,
        mp.line_type,
        mp.is_centered,
        w.text as arabic_text
      FROM mushaf_pages mp
      LEFT JOIN words w ON mp.word_id = w.id
      WHERE mp.page_number = ?
      ORDER BY mp.line_number ASC, mp.word_id ASC
    ''', [pageNumber]);
  }
  
  // Get letters for a specific word
  Future<List<QuranLetter>> getWordLetters(int wordId) async {
    final db = await database;
    final results = await db.query(
      'letter_breakdown',
      where: 'word_id = ?',
      whereArgs: [wordId],
      orderBy: 'letter_index ASC',
    );
    return results.map((map) => QuranLetter.fromMap(map)).toList();
  }
  
  Future<int> getTotalPages() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(page_number) as max_page FROM mushaf_pages'
    );
    return result.first['max_page'] as int? ?? 604;
  }
}
