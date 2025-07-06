import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/now_playing_info.dart';
import '../../domain/entities/music_report.dart';
import '../../domain/entities/server_stats.dart';
import '../../domain/repositories/music_repository.dart';
import '../../data/datasources/music_remote_data_source.dart';
import '../../data/repositories/music_repository_impl.dart';
import '../../core/utils/helpers.dart';

// Dependencies
final httpClientProvider = Provider<http.Client>((ref) => http.Client());

final musicRemoteDataSourceProvider = Provider<MusicRemoteDataSource>((ref) {
  return MusicRemoteDataSourceImpl(httpClient: ref.watch(httpClientProvider));
});

final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  return MusicRepositoryImpl(
    remoteDataSource: ref.watch(musicRemoteDataSourceProvider),
  );
});

// State Providers
final nowPlayingProvider = FutureProvider<NowPlayingInfo>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  final result = await repository.getNowPlaying();

  return result.fold((failure) {
    AppLogger.error('Failed to get now playing: ${failure.message}');
    throw Exception(failure.message);
  }, (nowPlaying) => nowPlaying);
});

final musicReportProvider = FutureProvider.family<MusicReport, String>((
  ref,
  period,
) async {
  final repository = ref.watch(musicRepositoryProvider);
  final result = await repository.getReport(period);

  return result.fold((failure) {
    AppLogger.error('Failed to get report: ${failure.message}');
    throw Exception(failure.message);
  }, (report) => report);
});

final serverStatsProvider = FutureProvider<ServerStats>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  final result = await repository.getServerStats();

  return result.fold((failure) {
    AppLogger.error('Failed to get server stats: ${failure.message}');
    throw Exception(failure.message);
  }, (stats) => stats);
});

final healthCheckProvider = FutureProvider<HealthCheckResponse>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  final result = await repository.getHealthCheck();

  return result.fold((failure) {
    AppLogger.error('Failed to get health check: ${failure.message}');
    throw Exception(failure.message);
  }, (health) => health);
});

// WebSocket Stream Provider
final nowPlayingStreamProvider = StreamProvider<NowPlayingInfo>((ref) {
  final repository = ref.watch(musicRepositoryProvider);

  ref.onDispose(() {
    AppLogger.info('Disposing WebSocket connection');
    repository.closeWebSocket();
  });

  return repository.getNowPlayingStream();
});

// Auto-refresh Provider
final autoRefreshProvider = Provider<bool>((ref) => true);

// Selected Period Provider
final selectedPeriodProvider = StateProvider<String>((ref) => 'daily');
