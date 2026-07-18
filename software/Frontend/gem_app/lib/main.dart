import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/home_dashboard.dart';
import 'screens/detection_input_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/result_details_screen.dart';
import 'screens/cut_recommendation_screen.dart';
import 'screens/cut_analysis_result_screen.dart';
import 'screens/cut_processing_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const GemApp());
}

class GemApp extends StatelessWidget {
  const GemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GemLens AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF102216), // background-dark
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF11D452), // primary
          secondary: Color(0xFFD4AF37), // gold accent
          surface: Color(0xFF1A3825), // surface-dark
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeDashboard(),
        '/detection_input': (context) => const DetectionInputScreen(),
        '/processing': (context) => const ProcessingScreen(),
        '/result_details': (context) => const ResultDetailsScreen(),
        '/cut_recommendation': (context) => const CutRecommendationScreen(),
        '/cut_processing': (context) => const CutProcessingScreen(),
        '/cut_analysis_result': (context) => const CutAnalysisResultScreen(),
        '/history': (context) => const HistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
