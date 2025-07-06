import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/now_playing_info.dart';
import '../../domain/entities/music_report.dart';
import '../../domain/entities/server_stats.dart';
import '../../domain/entities/recent_track_info.dart';
import '../../core/utils/helpers.dart';

abstract class MusicRemoteDataSource {
  Future<NowPlayingInfo> getNowPlaying();
  Future<MusicReport> getReport(String period);
  Future<ServerStats> getServerStats();
  Future<HealthCheckResponse> getHealthCheck();
  Future<RecentTracksResponse> getRecentTracks({
    int? limit,
    int? page,
    DateTime? from,
    DateTime? to,
  });
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
  Future<MusicReport> getReport(String period) async {
    try {
      final response = await httpClient.get(
        Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.reportsEndpoint}/$period',
        ),
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
          );
        }
      } else {
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
