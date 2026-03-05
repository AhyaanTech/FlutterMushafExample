import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/quran_models.dart';

/// Database helper class for managing SQLite database operations
/// Uses singleton pattern for single database instance across the app
class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  // Factory constructor returns the same instance
  factory DatabaseHelper() => _instance;

  // Private constructor prevents external instantiation
  DatabaseHelper._privateConstructor();

  static const String _databaseName = 'quran_offline.db';
  static const String _assetPath = 'assets/db/quran_offline.db';
  static const int _databaseVersion = 1;

  /// Get the database instance, initializing it if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  /// Copies database from assets to app documents directory on first launch
  Future<Database> _initDatabase() async {
    try {
      // Get the application documents directory
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, _databaseName);

      // Check if database already exists
      final dbFile = File(dbPath);
      final bool exists = await dbFile.exists();

      if (!exists) {
        // Copy database from assets to device storage
        await _copyDatabaseFromAssets(dbPath);
      }

      // Open the database
      return await openDatabase(
        dbPath,
        version: _databaseVersion,
        onCreate: _onCreate,
        onOpen: (db) {
          print('Database opened successfully at: $dbPath');
        },
      );
    } catch (e, stackTrace) {
      print('Error initializing database: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Copy database file from assets to the specified path
  Future<void> _copyDatabaseFromAssets(String targetPath) async {
    try {
      print('Copying database from assets to: $targetPath');

      // Load database from assets as ByteData
      final ByteData data = await rootBundle.load(_assetPath);
      final List<int> bytes = data.buffer.asUint8List();

      // Create the target directory if it doesn't exist
      final targetDir = Directory(dirname(targetPath));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // Write the bytes to the file
      await File(targetPath).writeAsBytes(bytes);

      print('Database copied successfully (${bytes.length} bytes)');
    } catch (e, stackTrace) {
      print('Error copying database from assets: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to copy database from assets: $e');
    }
  }

  /// Called when the database is created for the first time
  Future<void> _onCreate(Database db, int version) async {
    // Database is pre-populated from assets, so no schema creation needed
    print('Database onCreate called (version: $version)');
  }

  /// Get all page data for a specific Mushaf page
  /// Returns raw database rows ordered by line_number and word_id
  Future<List<Map<String, dynamic>>> getPageData(int pageNumber) async {
    try {
      final db = await database;
      final results = await db.query(
        'mushaf_pages',
        where: 'page_number = ?',
        whereArgs: [pageNumber],
        orderBy: 'line_number ASC, word_id ASC',
      );
      return results;
    } catch (e) {
      print('Error fetching page $pageNumber: $e');
      rethrow;
    }
  }

  /// Get a complete QuranPage object with all lines and words
  Future<QuranPage?> getQuranPage(int pageNumber) async {
    try {
      final rows = await getPageData(pageNumber);
      if (rows.isEmpty) {
        print('No data found for page $pageNumber');
        return null;
      }
      return QuranPage.fromDbRows(pageNumber, rows);
    } catch (e) {
      print('Error getting QuranPage $pageNumber: $e');
      return null;
    }
  }

  /// Get distinct surah names on a specific page
  Future<List<String>> getSurahsOnPage(int pageNumber) async {
    try {
      final db = await database;
      final results = await db.rawQuery('''
        SELECT DISTINCT surah_name 
        FROM mushaf_pages 
        WHERE page_number = ? AND line_type = 'surah_name'
        ORDER BY line_number ASC
      ''', [pageNumber]);
      return results.map((row) => row['surah_name'] as String).toList();
    } catch (e) {
      print('Error fetching surahs on page $pageNumber: $e');
      return [];
    }
  }

  /// Get the total number of pages in the database
  Future<int> getTotalPages() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT MAX(page_number) as max_page FROM mushaf_pages',
      );
      return result.first['max_page'] as int? ?? 0;
    } catch (e) {
      print('Error getting total pages: $e');
      return 0;
    }
  }

  /// Check if a page exists in the database
  Future<bool> pageExists(int pageNumber) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM mushaf_pages WHERE page_number = ?',
        [pageNumber],
      );
      return (result.first['count'] as int? ?? 0) > 0;
    } catch (e) {
      print('Error checking if page $pageNumber exists: $e');
      return false;
    }
  }

  /// Close the database connection
  /// Call this when the app is being terminated or when database is no longer needed
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('Database connection closed');
    }
  }

  // Legacy methods - kept for compatibility
  Future<List<Map<String, dynamic>>> getSurahs() async {
    throw UnimplementedError('getSurahs not yet implemented');
  }

  Future<List<Map<String, dynamic>>> getAyahsByPage(int page) async {
    throw UnimplementedError('getAyahsByPage not yet implemented');
  }

  Future<List<Map<String, dynamic>>> getWordsByAyah(int ayahId) async {
    throw UnimplementedError('getWordsByAyah not yet implemented');
  }
}
