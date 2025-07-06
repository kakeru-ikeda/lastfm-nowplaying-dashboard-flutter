class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:3001';
  static const String wsUrl = 'ws://localhost:3001';

  // API Endpoints
  static const String healthEndpoint = '/health';
  static const String nowPlayingEndpoint = '/api/now-playing';
  static const String statsEndpoint = '/api/stats';
  static const String reportsEndpoint = '/api/reports';
  static const String recentTracksEndpoint = '/api/recent-tracks';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double chartHeight = 300.0;

  // Colors
  static const int primaryColorValue = 0xFF1DB954; // Spotify Green
  static const int secondaryColorValue = 0xFF191414; // Dark
  static const int accentColorValue = 0xFFFF5722; // Orange

  // Animations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration refreshInterval = Duration(seconds: 5);

  // Responsive Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;
}
