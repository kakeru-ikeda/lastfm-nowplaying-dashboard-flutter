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

  // Animations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
