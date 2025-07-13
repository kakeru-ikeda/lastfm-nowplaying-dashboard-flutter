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

  // Detailed Stats Endpoints
  static const String weekDailyStatsEndpoint = '/api/stats/week-daily';
  static const String monthWeeklyStatsEndpoint = '/api/stats/month-weekly';
  static const String yearMonthlyStatsEndpoint = '/api/stats/year-monthly';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double chartHeight = 300.0;

  // Responsive Design Constants
  static const double mobileBreakpoint = 450.0;
  static const double tabletBreakpoint = 800.0;
  static const double desktopBreakpoint = 1200.0;
  static const double largeDesktopBreakpoint = 1920.0;

  // Responsive Padding Multipliers
  static const double mobilePaddingScale = 0.5;
  static const double tabletPaddingScale = 1.0;
  static const double desktopPaddingScale = 1.25;
  static const double largeDesktopPaddingScale = 1.5;

  // Responsive Card Heights
  static const double mobileCardHeight = 160.0;
  static const double tabletCardHeight = 180.0;
  static const double desktopCardHeight = 200.0;
  static const double largeDesktopCardHeight = 210.0;

  // Animations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
