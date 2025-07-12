import '../entities/now_playing_info.dart';
import '../entities/music_report.dart';
import '../entities/server_stats.dart';
import '../entities/recent_track_info.dart';
import '../entities/stats_response.dart';
import '../entities/user_stats.dart';
import '../../core/errors/failure.dart';

abstract class MusicRepository {
  // Now Playing
  Future<Either<Failure, NowPlayingInfo>> getNowPlaying();

  // Reports
  Future<Either<Failure, MusicReport>> getReport(String period, {String? date});

  // Recent Tracks
  Future<Either<Failure, RecentTracksResponse>> getRecentTracks({
    int? limit,
    int? page,
    DateTime? from,
    DateTime? to,
  });

  // Server Stats
  Future<Either<Failure, ServerStats>> getServerStats();

  // User Stats
  Future<Either<Failure, UserStats>> getUserStats();

  // Detailed Stats
  Future<Either<Failure, WeekDailyStatsResponse>> getWeekDailyStats(
      {String? date});
  Future<Either<Failure, MonthWeeklyStatsResponse>> getMonthWeeklyStats(
      {String? date});
  Future<Either<Failure, YearMonthlyStatsResponse>> getYearMonthlyStats(
      {String? year});

  // Health Check
  Future<Either<Failure, HealthCheckResponse>> getHealthCheck();

  // WebSocket
  Stream<NowPlayingInfo> getNowPlayingStream();
  void closeWebSocket();
}

// Result type for error handling
abstract class Either<L, R> {
  const Either();

  bool get isLeft;
  bool get isRight;

  L get left;
  R get right;

  T fold<T>(T Function(L) ifLeft, T Function(R) ifRight);
}

class Left<L, R> extends Either<L, R> {
  final L _value;

  const Left(this._value);

  @override
  bool get isLeft => true;

  @override
  bool get isRight => false;

  @override
  L get left => _value;

  @override
  R get right => throw Exception('Called right on a Left');

  @override
  T fold<T>(T Function(L) ifLeft, T Function(R) ifRight) => ifLeft(_value);
}

class Right<L, R> extends Either<L, R> {
  final R _value;

  const Right(this._value);

  @override
  bool get isLeft => false;

  @override
  bool get isRight => true;

  @override
  L get left => throw Exception('Called left on a Right');

  @override
  R get right => _value;

  @override
  T fold<T>(T Function(L) ifLeft, T Function(R) ifRight) => ifRight(_value);
}
