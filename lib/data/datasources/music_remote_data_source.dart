import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/now_playing_info.dart';
import '../../domain/entities/music_report.dart';
import '../../domain/entities/server_stats.dart';
import '../../domain/entities/recent_track_info.dart';
import '../../domain/entities/user_stats.dart';
import '../../domain/entities/stats_response.dart';
import '../../core/utils/helpers.dart';

abstract class MusicRemoteDataSource {
  Future<NowPlayingInfo> getNowPlaying();
  Future<MusicReport> getReport(String period, {String? date});
  Future<ServerStats> getServerStats();
  Future<UserStats> getUserStats();
  Future<HealthCheckResponse> getHealthCheck();
  Future<RecentTracksResponse> getRecentTracks({
    int? limit,
    int? page,
    DateTime? from,
    DateTime? to,
  });
  Future<WeekDailyStatsResponse> getWeekDailyStats(
      {String? date, DateTime? from, DateTime? to});
  Future<MonthWeeklyStatsResponse> getMonthWeeklyStats(
      {String? date, DateTime? from, DateTime? to});
  Future<YearMonthlyStatsResponse> getYearMonthlyStats(
      {String? year, DateTime? from, DateTime? to});
  Stream<NowPlayingInfo> getNowPlayingStream();
  void closeWebSocket();
}

class MusicRemoteDataSourceImpl implements MusicRemoteDataSource {
  final http.Client httpClient;
  WebSocketChannel? _webSocketChannel;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;

  MusicRemoteDataSourceImpl({required this.httpClient});

  @override
  Future<NowPlayingInfo> getNowPlaying() async {
    try {
      final response = await httpClient.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.nowPlayingEndpoint}'),
        headers: {'Content-Type': 'application/json'},
      );

      AppLogger.debug('Now Playing API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        AppLogger.debug('Now Playing API Response Body: $responseBody');

        if (responseBody.isEmpty) {
          throw ServerException(
            'Empty response body',
            statusCode: response.statusCode,
          );
        }

        final jsonData = JsonHelper.safeDecode(responseBody);
        if (jsonData == null) {
          throw ServerException(
            'Invalid JSON response',
            statusCode: response.statusCode,
          );
        }

        if (jsonData['success'] == true) {
          return NowPlayingInfo.fromJson(
            jsonData['data'] as Map<String, dynamic>,
          );
        } else {
          throw ServerException(
            jsonData['error'] ?? 'Unknown server error',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw NetworkException(
          'Failed to fetch now playing info',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('getNowPlaying error', e);
      if (e is AppException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  @override
  Future<MusicReport> getReport(String period, {String? date}) async {
    try {
      // 日付フォーマットを正規化
      String? processedDate = date;
      if (date != null) {
        if (date.contains(' - ')) {
          // 週の範囲の場合は開始日のみを使用
          processedDate = date.split(' - ')[0];
          AppLogger.debug('週の範囲形式を変換: $date -> $processedDate');
        } else if (period == 'monthly' && date.length == 7) {
          // 月次レポートでYYYY-MM形式の場合は月の開始日に変換
          processedDate = '$date-01';
          AppLogger.debug('月次レポート用に日付を変換: $date -> $processedDate');
        } else if (period == 'yearly' && date.length == 4) {
          // 年次レポートでYYYY形式の場合は年の開始日に変換
          processedDate = '$date-01-01';
          AppLogger.debug('年次レポート用に日付を変換: $date -> $processedDate');
        }
      }

      final uri = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.reportsEndpoint}/$period${processedDate != null ? '?date=$processedDate' : ''}',
      );

      AppLogger.debug('Report API リクエスト: ${uri.toString()}');
      AppLogger.debug('Report API パラメータ: period=$period, date=$processedDate');

      final response = await httpClient.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      AppLogger.debug('Report API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        AppLogger.debug('API Response Body: $responseBody');

        if (responseBody.isEmpty) {
          throw ServerException(
            'Empty response body',
            statusCode: response.statusCode,
          );
        }

        final jsonData = JsonHelper.safeDecode(responseBody);
        if (jsonData == null) {
          throw ServerException(
            'Invalid JSON response',
            statusCode: response.statusCode,
          );
        }

        if (jsonData['success'] == true) {
          return MusicReport.fromJson(jsonData['data'] as Map<String, dynamic>);
        } else {
          throw ServerException(
            jsonData['error'] ?? 'Unknown server error',
            statusCode: response.statusCode,
            errorCode: jsonData['code'],
          );
        }
      } else {
        final responseBody = response.body;
        AppLogger.error('Report API エラーレスポンス: ${response.statusCode}');
        AppLogger.error('Report API エラーボディ: $responseBody');

        throw NetworkException(
          'Failed to fetch report',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('getReport error', e);
      if (e is AppException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  @override
  Future<ServerStats> getServerStats() async {
    try {
      final response = await httpClient.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.statsEndpoint}'),
        headers: {'Content-Type': 'application/json'},
      );

      AppLogger.debug('Stats API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        AppLogger.debug('Stats API Response Body: $responseBody');

        if (responseBody.isEmpty) {
          throw ServerException(
            'Empty response body',
            statusCode: response.statusCode,
          );
        }

        final jsonData = JsonHelper.safeDecode(responseBody);
        if (jsonData == null) {
          throw ServerException(
            'Invalid JSON response',
            statusCode: response.statusCode,
          );
        }

        if (jsonData['success'] == true) {
          return ServerStats.fromJson(jsonData['data'] as Map<String, dynamic>);
        } else {
          throw ServerException(
            jsonData['error'] ?? 'Unknown server error',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw NetworkException(
          'Failed to fetch server stats',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('getServerStats error', e);
      if (e is AppException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  @override
  Future<UserStats> getUserStats() async {
    try {
      final response = await httpClient.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.userStatsEndpoint}'),
        headers: {'Content-Type': 'application/json'},
      );

      AppLogger.debug('User Stats API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        AppLogger.debug('User Stats API Response Body: $responseBody');

        if (responseBody.isEmpty) {
          throw ServerException(
            'Empty response body',
            statusCode: response.statusCode,
          );
        }

        final jsonData = JsonHelper.safeDecode(responseBody);
        if (jsonData == null) {
          throw ServerException(
            'Invalid JSON response',
            statusCode: response.statusCode,
          );
        }

        if (jsonData['success'] == true) {
          // APIレスポンスの詳細なログ出力
          AppLogger.debug('User Stats Data Structure: ${jsonData['data']}');
          AppLogger.debug('Profile Data: ${jsonData['data']['profile']}');

          return UserStats.fromJson(jsonData['data'] as Map<String, dynamic>);
        } else {
          throw ServerException(
            jsonData['error'] ?? 'Unknown server error',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw NetworkException(
          'Failed to fetch user stats',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('getUserStats error', e);
      if (e is AppException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  @override
  Future<HealthCheckResponse> getHealthCheck() async {
    try {
      final response = await httpClient.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.healthEndpoint}'),
        headers: {'Content-Type': 'application/json'},
      );

      AppLogger.debug('Health Check API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        AppLogger.debug('Health Check API Response Body: $responseBody');

        if (responseBody.isEmpty) {
          throw ServerException(
            'Empty response body',
            statusCode: response.statusCode,
          );
        }

        final jsonData = JsonHelper.safeDecode(responseBody);
        if (jsonData == null) {
          throw ServerException(
            'Invalid JSON response',
            statusCode: response.statusCode,
          );
        }

        return HealthCheckResponse.fromJson(jsonData);
      } else {
        throw NetworkException(
          'Health check failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('getHealthCheck error', e);
      if (e is AppException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  @override
  Future<RecentTracksResponse> getRecentTracks({
    int? limit,
    int? page,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.recentTracksEndpoint}',
      ).replace(
        queryParameters: {
          'limit': limit?.toString(),
          'page': page?.toString(),
          if (from != null) 'from': from.toIso8601String(),
          if (to != null) 'to': to.toIso8601String(),
        },
      );

      final response = await httpClient.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      AppLogger.debug('Recent Tracks API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        AppLogger.debug('Recent Tracks API Response Body: $responseBody');

        if (responseBody.isEmpty) {
          throw ServerException(
            'Empty response body',
            statusCode: response.statusCode,
          );
        }

        final jsonData = JsonHelper.safeDecode(responseBody);
        if (jsonData == null) {
          throw ServerException(
            'Invalid JSON response',
            statusCode: response.statusCode,
          );
        }

        if (jsonData['success'] == true) {
          return RecentTracksResponse.fromJson(
            jsonData['data'] as Map<String, dynamic>,
          );
        } else {
          throw ServerException(
            jsonData['error'] ?? 'Unknown server error',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw NetworkException(
          'Failed to fetch recent tracks',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('getRecentTracks error', e);
      if (e is AppException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  @override
  Future<WeekDailyStatsResponse> getWeekDailyStats(
      {String? date, DateTime? from, DateTime? to}) async {
    try {
      // パラメータの構築
      Map<String, String> queryParams = {};

      // 期間指定モード
      if (from != null && to != null) {
        queryParams['from'] = from.toIso8601String().split('T')[0];
        queryParams['to'] = to.toIso8601String().split('T')[0];
      }
      // 単一日付モード（下位互換性）
      else if (date != null) {
        queryParams['date'] = date;
      }

      final uri = Uri.parse(
              '${AppConstants.baseUrl}${AppConstants.weekDailyStatsEndpoint}')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await httpClient.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      AppLogger.debug('Week Daily Stats API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        AppLogger.debug('API Response Body: $responseBody');

        if (responseBody.isEmpty) {
          throw ServerException(
            'Empty response body',
            statusCode: response.statusCode,
          );
        }

        final jsonData = JsonHelper.safeDecode(responseBody);
        if (jsonData == null) {
          throw ServerException(
            'Invalid JSON response',
            statusCode: response.statusCode,
          );
        }

        if (jsonData['success'] == true && jsonData['data'] != null) {
          return WeekDailyStatsResponse.fromJson(
              jsonData['data'] as Map<String, dynamic>);
        } else {
          throw ServerException(
            jsonData['error'] ?? 'Unknown server error',
            statusCode: response.statusCode,
            errorCode: jsonData['code'],
          );
        }
      } else {
        throw NetworkException(
          'Failed to fetch week daily stats',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('getWeekDailyStats error', e);
      if (e is AppException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  @override
  Future<MonthWeeklyStatsResponse> getMonthWeeklyStats(
      {String? date, DateTime? from, DateTime? to}) async {
    try {
      // パラメータの構築
      Map<String, String> queryParams = {};

      // 期間指定モード
      if (from != null && to != null) {
        queryParams['from'] = from.toIso8601String().split('T')[0];
        queryParams['to'] = to.toIso8601String().split('T')[0];
      }
      // 単一日付モード（下位互換性）
      else if (date != null) {
        // 月の範囲形式（YYYY-MM-DD - YYYY-MM-DD）を単一日付に変換
        String processedDate = date;
        if (date.contains(' - ')) {
          // 月の範囲の場合は開始日のみを使用
          processedDate = date.split(' - ')[0];
          AppLogger.debug('月の範囲形式を変換: $date -> $processedDate');
        }
        queryParams['date'] = processedDate;
      }

      final uri = Uri.parse(
              '${AppConstants.baseUrl}${AppConstants.monthWeeklyStatsEndpoint}')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await httpClient.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      AppLogger.debug(
          'Month Weekly Stats API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        AppLogger.debug('API Response Body: $responseBody');

        if (responseBody.isEmpty) {
          throw ServerException(
            'Empty response body',
            statusCode: response.statusCode,
          );
        }

        final jsonData = JsonHelper.safeDecode(responseBody);
        if (jsonData == null) {
          throw ServerException(
            'Invalid JSON response',
            statusCode: response.statusCode,
          );
        }

        if (jsonData['success'] == true && jsonData['data'] != null) {
          return MonthWeeklyStatsResponse.fromJson(
              jsonData['data'] as Map<String, dynamic>);
        } else {
          throw ServerException(
            jsonData['error'] ?? 'Unknown server error',
            statusCode: response.statusCode,
            errorCode: jsonData['code'],
          );
        }
      } else {
        throw NetworkException(
          'Failed to fetch month weekly stats',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('getMonthWeeklyStats error', e);
      if (e is AppException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  @override
  Future<YearMonthlyStatsResponse> getYearMonthlyStats(
      {String? year, DateTime? from, DateTime? to}) async {
    try {
      // パラメータの構築
      Map<String, String> queryParams = {};

      // 期間指定モード
      if (from != null && to != null) {
        queryParams['from'] = from.toIso8601String().split('T')[0];
        queryParams['to'] = to.toIso8601String().split('T')[0];
      }
      // 年指定モード（下位互換性）
      else if (year != null) {
        // 年の範囲形式（YYYY-MM-DD - YYYY-MM-DD）を単一日付に変換
        String processedYear = year;
        if (year.contains(' - ')) {
          // 年の範囲の場合は開始日のみを使用
          processedYear = year.split(' - ')[0];
          AppLogger.debug('年の範囲形式を変換: $year -> $processedYear');
        }
        queryParams['year'] = processedYear;
      }

      final uri = Uri.parse(
              '${AppConstants.baseUrl}${AppConstants.yearMonthlyStatsEndpoint}')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await httpClient.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      AppLogger.debug(
          'Year Monthly Stats API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        AppLogger.debug('API Response Body: $responseBody');

        if (responseBody.isEmpty) {
          throw ServerException(
            'Empty response body',
            statusCode: response.statusCode,
          );
        }

        final jsonData = JsonHelper.safeDecode(responseBody);
        if (jsonData == null) {
          throw ServerException(
            'Invalid JSON response',
            statusCode: response.statusCode,
          );
        }

        if (jsonData['success'] == true && jsonData['data'] != null) {
          return YearMonthlyStatsResponse.fromJson(
              jsonData['data'] as Map<String, dynamic>);
        } else {
          throw ServerException(
            jsonData['error'] ?? 'Unknown server error',
            statusCode: response.statusCode,
            errorCode: jsonData['code'],
          );
        }
      } else {
        throw NetworkException(
          'Failed to fetch year monthly stats',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      AppLogger.error('getYearMonthlyStats error', e);
      if (e is AppException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  @override
  Stream<NowPlayingInfo> getNowPlayingStream() {
    return _createWebSocketStream();
  }

  Stream<NowPlayingInfo> _createWebSocketStream() async* {
    while (_reconnectAttempts < maxReconnectAttempts) {
      try {
        _webSocketChannel = WebSocketChannel.connect(
          Uri.parse(AppConstants.wsUrl),
        );

        AppLogger.info(
          'WebSocket connected: ${AppConstants.wsUrl} (attempt ${_reconnectAttempts + 1})',
        );
        _reconnectAttempts = 0; // 接続成功時にリセット

        await for (final data in _webSocketChannel!.stream) {
          if (data != null && data.toString().isNotEmpty) {
            try {
              final jsonData = JsonHelper.safeDecode(data.toString());
              if (jsonData == null) {
                AppLogger.warning('Invalid JSON in WebSocket message');
                continue;
              }

              // now-playingメッセージのみを処理し、他は無視
              if (jsonData['type'] == 'now-playing') {
                yield NowPlayingInfo.fromJson(
                  jsonData['data'] as Map<String, dynamic>,
                );
              } else {
                // connection-statusやその他のメッセージタイプは無視
                AppLogger.debug(
                  'Ignoring WebSocket message type: ${jsonData['type']}',
                );
              }
            } catch (e) {
              AppLogger.error('WebSocket message parse error', e);
              // パースエラーは継続
            }
          }
        }
      } catch (e) {
        AppLogger.error(
          'WebSocket connection error (attempt ${_reconnectAttempts + 1})',
          e,
        );
        closeWebSocket();

        _reconnectAttempts++;
        if (_reconnectAttempts < maxReconnectAttempts) {
          AppLogger.info(
            'Reconnecting in ${_reconnectAttempts * 2} seconds...',
          );
          await Future.delayed(Duration(seconds: _reconnectAttempts * 2));
        } else {
          AppLogger.error('Max reconnection attempts reached');
          throw WebSocketException(
            'Failed to connect to WebSocket after $maxReconnectAttempts attempts',
          );
        }
      }
    }
  }

  @override
  void closeWebSocket() {
    _webSocketChannel?.sink.close();
    _webSocketChannel = null;
    _reconnectAttempts = 0; // 手動切断時にリセット
    AppLogger.info('WebSocket connection closed');
  }
}
