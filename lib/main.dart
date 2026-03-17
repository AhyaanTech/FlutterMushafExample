import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'presentation/pages/mushaf_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Force RTL for Arabic
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MushafApp());
}

class MushafApp extends StatelessWidget {
  const MushafApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mushaf POC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'UthmanicHafs',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      home: const MushafPage(),
    );
  }
}
