import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/now_playing_info.dart';
import '../../domain/entities/music_report.dart';
import '../../domain/entities/server_stats.dart';
import '../../core/utils/helpers.dart';

abstract class MusicRemoteDataSource {
  Future<NowPlayingInfo> getNowPlaying();
  Future<MusicReport> getReport(String period);
  Future<ServerStats> getServerStats();
  Future<HealthCheckResponse> getHealthCheck();
  Stream<NowPlayingInfo> getNowPlayingStream();
  void closeWebSocket();
}

class MusicRemoteDataSourceImpl implements MusicRemoteDataSource {
  final http.Client httpClient;
  WebSocketChannel? _webSocketChannel;

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
  Stream<NowPlayingInfo> getNowPlayingStream() {
    try {
      _webSocketChannel = WebSocketChannel.connect(
        Uri.parse(AppConstants.wsUrl),
      );

      AppLogger.info('WebSocket connected: ${AppConstants.wsUrl}');

      return _webSocketChannel!.stream.map((data) {
        try {
          if (data == null || data.toString().isEmpty) {
            throw WebSocketException('Empty WebSocket message');
          }

          final jsonData = JsonHelper.safeDecode(data.toString());
          if (jsonData == null) {
            throw WebSocketException('Invalid JSON in WebSocket message');
          }

          if (jsonData['type'] == 'now-playing') {
            return NowPlayingInfo.fromJson(
              jsonData['data'] as Map<String, dynamic>,
            );
          }
          throw WebSocketException('Invalid message type: ${jsonData['type']}');
        } catch (e) {
          AppLogger.error('WebSocket message parse error', e);
          throw WebSocketException('Failed to parse WebSocket message: $e');
        }
      }).cast<NowPlayingInfo>();
    } catch (e) {
      AppLogger.error('WebSocket connection error', e);
      throw WebSocketException('Failed to connect to WebSocket: $e');
    }
  }

  @override
  void closeWebSocket() {
    _webSocketChannel?.sink.close();
    _webSocketChannel = null;
    AppLogger.info('WebSocket connection closed');
  }
}
