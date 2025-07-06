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

// 接続状態とデータを含む統合モデル
class NowPlayingState {
  final NowPlayingInfo? data;
  final String connectionStatus;
  final String? error;

  const NowPlayingState({
    this.data,
    required this.connectionStatus,
    this.error,
  });

  NowPlayingState copyWith({
    NowPlayingInfo? data,
    String? connectionStatus,
    String? error,
  }) {
    return NowPlayingState(
      data: data ?? this.data,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      error: error ?? this.error,
    );
  }
}

// 統合されたNow Playing Stream Provider
final nowPlayingWithStatusProvider = StreamProvider<NowPlayingState>((
  ref,
) async* {
  final repository = ref.watch(musicRepositoryProvider);

  ref.onDispose(() {
    AppLogger.info('Disposing WebSocket connection');
    repository.closeWebSocket();
  });

  // 初期状態
  yield const NowPlayingState(connectionStatus: 'connecting');

  try {
    await for (final nowPlaying in repository.getNowPlayingStream()) {
      yield NowPlayingState(data: nowPlaying, connectionStatus: 'connected');
    }
  } catch (error) {
    AppLogger.error('WebSocket stream error: $error');
    yield NowPlayingState(connectionStatus: 'error', error: error.toString());
  }
});

// 後方互換性のためのプロバイダー
final nowPlayingStreamProvider = StreamProvider<NowPlayingInfo>((ref) {
  return ref
      .watch(nowPlayingWithStatusProvider.stream)
      .where((state) => state.data != null)
      .map((state) => state.data!);
});

// WebSocket Connection State Provider（後方互換性のため）
final webSocketConnectionStateProvider = Provider<String>((ref) {
  final state = ref.watch(nowPlayingWithStatusProvider);
  return state.when(
    data: (data) => data.connectionStatus,
    loading: () => 'connecting',
    error: (error, stack) => 'error',
  );
});

// Auto-refresh Provider
final autoRefreshProvider = Provider<bool>((ref) => true);

// Selected Period Provider
final selectedPeriodProvider = StateProvider<String>((ref) => 'daily');
