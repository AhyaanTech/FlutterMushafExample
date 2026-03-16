/// Mushaf App - Interactive Offline Quran Reader
///
/// This is the entry point for the Interactive Mushaf application.
/// The app displays a 15-line Mushaf layout where every word is tappable
/// for memorization marking.
///
/// Features:
/// - Offline-first: Complete Quran database bundled with the app
/// - Interactive words: Tap to mark/unmark words (black ↔ red)
/// - Page navigation: Swipe or jump to any page (1-604)
/// - RTL support: Full Arabic right-to-left text direction
///
/// Architecture:
/// - main.dart: App entry point with database initialization
/// - models/: Data models (QuranWord, QuranLine, QuranPage)
/// - services/: Database helper for SQLite operations
/// - screens/: Main Mushaf screen with PageView
/// - widgets/: Reusable UI components

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'screens/mushaf_screen.dart';
import 'services/database_helper.dart';

/// Application entry point
///
/// Ensures Flutter bindings are initialized before running the app.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite_common_ffi for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(const MushafApp());
}

class MushafApp extends StatefulWidget {
  const MushafApp({super.key});

  @override
  State<MushafApp> createState() => _MushafAppState();
}

class _MushafAppState extends State<MushafApp> {
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    // Initialize database on app startup
    _initializationFuture = _initializeApp();
  }

  /// Initialize the app by setting up the database
  Future<void> _initializeApp() async {
    try {
      // Initialize database helper (copies from assets on first launch)
      final dbHelper = DatabaseHelper();
      await dbHelper.database;

      // Optional: Log database info
      final totalPages = await dbHelper.getTotalPages();
      print('Database initialized successfully. Total pages: $totalPages');
    } catch (e, stackTrace) {
      print('Failed to initialize database: $e');
      print('Stack trace: $stackTrace');
      // Re-throw to show error UI
      throw Exception('Database initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        // Show loading screen while initializing
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'جاري تحميل المصحف...',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Scheherazade',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Loading Mushaf...',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Show error screen if initialization failed
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'فشل في تحميل المصحف',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load Mushaf',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _initializationFuture = _initializeApp();
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة / Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Database initialized successfully, show main app
        return MaterialApp(
          title: 'Mushaf',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
          locale: const Locale('ar', 'SA'),
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            useMaterial3: true,
            fontFamily: 'Scheherazade',
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontFamily: 'Amiri'),
              bodyLarge: TextStyle(fontFamily: 'Amiri'),
              titleLarge: TextStyle(fontFamily: 'Amiri'),
            ),
          ),
          home: const MushafScreen(),
        );
      },
    );
  }
}
