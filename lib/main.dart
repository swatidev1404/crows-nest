import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/block_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPrefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const CrowsNestApp(),
    ),
  );
}

class CrowsNestApp extends StatelessWidget {
  const CrowsNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crow\'s Nest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0369A1), // Deep Ocean Blue
          secondary: Color(0xFFD97706), // Warm Amber
          surface: Color(0xFFFFFFFF), // White cards
          onSurface: Color(0xFF0F172A), // Deep Navy text
        ),
        textTheme: GoogleFonts.nunitoTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: const Color(0xFF0F172A),
          displayColor: const Color(0xFF0F172A),
        ),
        scaffoldBackgroundColor: const Color(0xFFFDFBF7), // Warm parchment
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFDFBF7),
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
