import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'presentation/pages/dashboard_page.dart';
import 'core/constants/app_constants.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Last.fm Now Playing Dashboard',
      theme: ThemeData(
        primarySwatch:
            MaterialColor(AppConstants.primaryColorValue, <int, Color>{
              50: const Color(AppConstants.primaryColorValue).withOpacity(0.1),
              100: const Color(AppConstants.primaryColorValue).withOpacity(0.2),
              200: const Color(AppConstants.primaryColorValue).withOpacity(0.3),
              300: const Color(AppConstants.primaryColorValue).withOpacity(0.4),
              400: const Color(AppConstants.primaryColorValue).withOpacity(0.5),
              500: const Color(AppConstants.primaryColorValue),
              600: const Color(AppConstants.primaryColorValue).withOpacity(0.7),
              700: const Color(AppConstants.primaryColorValue).withOpacity(0.8),
              800: const Color(AppConstants.primaryColorValue).withOpacity(0.9),
              900: const Color(AppConstants.primaryColorValue),
            }),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(AppConstants.primaryColorValue),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(AppConstants.secondaryColorValue),
        cardTheme: CardTheme(
          color: const Color(AppConstants.secondaryColorValue).withOpacity(0.8),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          ),
        ),
      ),
      builder:
          (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: [
              const Breakpoint(start: 0, end: 450, name: MOBILE),
              const Breakpoint(start: 451, end: 800, name: TABLET),
              const Breakpoint(start: 801, end: 1920, name: DESKTOP),
              const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
            ],
          ),
      home: const DashboardPage(),
    );
  }
}
