class AppConstants {
  // API Configuration - 環境変数対応
  static const String _defaultHost = 'localhost';
  static const String _defaultPort = '8443';
  static const String _defaultProtocol = 'https';

  static String get apiHost =>
      const String.fromEnvironment('API_HOST', defaultValue: _defaultHost);
  static String get apiPort =>
      const String.fromEnvironment('API_PORT', defaultValue: _defaultPort);
  static String get apiProtocol => const String.fromEnvironment('API_PROTOCOL',
      defaultValue: _defaultProtocol);

  static String get baseUrl => '$apiProtocol://$apiHost:$apiPort';
  static String get wsUrl {
    final wsProtocol = apiProtocol == 'https' ? 'wss' : 'ws';
    return '$wsProtocol://$apiHost:$apiPort';
  }

  // API Endpoints
  static const String healthEndpoint = '/health';
  static const String nowPlayingEndpoint = '/api/now-playing';
  static const String statsEndpoint = '/api/stats';
  static const String userStatsEndpoint = '/api/user-stats';
  static const String reportsEndpoint = '/api/reports';
  static const String recentTracksEndpoint = '/api/recent-tracks';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double chartHeight = 300.0;

  // Animations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
