import '../../domain/entities/now_playing_info.dart';
import '../../domain/entities/music_report.dart';
import '../../domain/entities/server_stats.dart';
import '../../domain/entities/recent_track_info.dart';
import '../../domain/repositories/music_repository.dart';
import '../../core/errors/failure.dart';
import '../../core/errors/exceptions.dart';
import '../datasources/music_remote_data_source.dart';
import '../../core/utils/helpers.dart';

class MusicRepositoryImpl implements MusicRepository {
  final MusicRemoteDataSource remoteDataSource;

  const MusicRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, NowPlayingInfo>> getNowPlaying() async {
    try {
      final result = await remoteDataSource.getNowPlaying();
      return Right(result);
    } on NetworkException catch (e) {
      AppLogger.error('Network error in getNowPlaying', e);
      return Left(
        Failure.network(message: e.message, statusCode: e.statusCode),
      );
    } on ServerException catch (e) {
      AppLogger.error('Server error in getNowPlaying', e);
      return Left(Failure.server(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('Unknown error in getNowPlaying', e);
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MusicReport>> getReport(String period) async {
    try {
      final result = await remoteDataSource.getReport(period);
      return Right(result);
    } on NetworkException catch (e) {
      AppLogger.error('Network error in getReport', e);
      return Left(
        Failure.network(message: e.message, statusCode: e.statusCode),
      );
    } on ServerException catch (e) {
      AppLogger.error('Server error in getReport', e);
      return Left(Failure.server(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('Unknown error in getReport', e);
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServerStats>> getServerStats() async {
    try {
      final result = await remoteDataSource.getServerStats();
      return Right(result);
    } on NetworkException catch (e) {
      AppLogger.error('Network error in getServerStats', e);
      return Left(
        Failure.network(message: e.message, statusCode: e.statusCode),
      );
    } on ServerException catch (e) {
      AppLogger.error('Server error in getServerStats', e);
      return Left(Failure.server(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('Unknown error in getServerStats', e);
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, HealthCheckResponse>> getHealthCheck() async {
    try {
      final result = await remoteDataSource.getHealthCheck();
      return Right(result);
    } on NetworkException catch (e) {
      AppLogger.error('Network error in getHealthCheck', e);
      return Left(
        Failure.network(message: e.message, statusCode: e.statusCode),
      );
    } on ServerException catch (e) {
      AppLogger.error('Server error in getHealthCheck', e);
      return Left(Failure.server(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('Unknown error in getHealthCheck', e);
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Stream<NowPlayingInfo> getNowPlayingStream() {
    try {
      return remoteDataSource.getNowPlayingStream();
    } catch (e) {
      AppLogger.error('Error in getNowPlayingStream', e);
      throw WebSocketException('Failed to get now playing stream: $e');
    }
  }

  @override
  void closeWebSocket() {
    remoteDataSource.closeWebSocket();
  }

  @override
  Future<Either<Failure, RecentTracksResponse>> getRecentTracks({
    int? limit,
    int? page,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final result = await remoteDataSource.getRecentTracks(
        limit: limit,
        page: page,
        from: from,
        to: to,
      );
      return Right(result);
    } on NetworkException catch (e) {
      AppLogger.error('Network error in getRecentTracks', e);
      return Left(
        Failure.network(message: e.message, statusCode: e.statusCode),
      );
    } on ServerException catch (e) {
      AppLogger.error('Server error in getRecentTracks', e);
      return Left(Failure.server(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      AppLogger.error('Unknown error in getRecentTracks', e);
      return Left(Failure.unknown(message: e.toString()));
    }
  }
}
