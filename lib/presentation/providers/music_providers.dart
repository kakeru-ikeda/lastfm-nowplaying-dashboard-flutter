import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/now_playing_info.dart';
import '../../domain/entities/music_report.dart';
import '../../domain/entities/server_stats.dart';
import '../../domain/entities/recent_track_info.dart';
import '../../domain/entities/recent_tracks_params.dart';
import '../../domain/entities/user_stats.dart';
import '../../domain/entities/stats_response.dart';
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

// Recent Tracks Provider with parameters
final recentTracksProvider =
    FutureProvider.family<RecentTracksResponse, RecentTracksParams>((
  ref,
  params,
) async {
  final repository = ref.watch(musicRepositoryProvider);
  final result = await repository.getRecentTracks(
    limit: params.limit,
    page: params.page,
    from: params.from,
    to: params.to,
  );

  return result.fold((failure) {
    AppLogger.error('Failed to get recent tracks: ${failure.message}');
    throw Exception(failure.message);
  }, (recentTracks) => recentTracks);
});

// Simple recent tracks provider with default parameters
final defaultRecentTracksProvider = FutureProvider<RecentTracksResponse>((
  ref,
) async {
  final repository = ref.watch(musicRepositoryProvider);
  final result = await repository.getRecentTracks(limit: 10);

  return result.fold((failure) {
    AppLogger.error('Failed to get recent tracks: ${failure.message}');
    throw Exception(failure.message);
  }, (recentTracks) => recentTracks);
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

// User Stats Provider
final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  final result = await repository.getUserStats();

  return result.fold((failure) {
    AppLogger.error('Failed to get user stats: ${failure.message}');
    throw Exception(failure.message);
  }, (userStats) => userStats);
});

// 詳細統計プロバイダー
final weekDailyStatsProvider =
    FutureProvider.family<WeekDailyStatsResponse, String?>((ref, date) async {
  final repository = ref.watch(musicRepositoryProvider);
  final result = await repository.getWeekDailyStats(date: date);

  return result.fold((failure) {
    AppLogger.error('Failed to get week daily stats: ${failure.message}');
    throw Exception(failure.message);
  }, (stats) {
    AppLogger.debug(
        'Week daily stats loaded successfully: ${stats.stats.length} days data');
    return stats;
  });
});

final monthWeeklyStatsProvider =
    FutureProvider.family<MonthWeeklyStatsResponse, String?>((ref, date) async {
  final repository = ref.watch(musicRepositoryProvider);
  final result = await repository.getMonthWeeklyStats(date: date);

  return result.fold((failure) {
    AppLogger.error('Failed to get month weekly stats: ${failure.message}');
    throw Exception(failure.message);
  }, (stats) => stats);
});

final yearMonthlyStatsProvider =
    FutureProvider.family<YearMonthlyStatsResponse, String?>((ref, year) async {
  final repository = ref.watch(musicRepositoryProvider);
  final result = await repository.getYearMonthlyStats(year: year);

  return result.fold((failure) {
    AppLogger.error('Failed to get year monthly stats: ${failure.message}');
    throw Exception(failure.message);
  }, (stats) => stats);
});

// レポート日付プロバイダー
final reportDateProvider = StateProvider<String?>((ref) => null);

// レポートプロバイダー - 手動制御版（自動監視しない）
final musicReportProvider = FutureProvider.family<MusicReport, String>((
  ref,
  period,
) async {
  final repository = ref.watch(musicRepositoryProvider);
  // reportDateProviderを監視しないように変更
  final selectedDate = ref.read(reportDateProvider);

  AppLogger.debug('Fetching report for period: $period, date: $selectedDate');

  final result = await repository.getReport(period, date: selectedDate);

  return result.fold((failure) {
    AppLogger.error('Failed to get report: ${failure.message}');
    throw Exception(failure.message);
  }, (report) {
    AppLogger.debug('Report loaded successfully for period: $period');
    return report;
  });
});

// レポート状態管理用プロバイダー - 手動更新制御
final reportUpdateNotifierProvider = StateNotifierProvider<ReportUpdateNotifier, ReportUpdateState>((ref) {
  return ReportUpdateNotifier(ref);
});

class ReportUpdateState {
  final bool isLoading;
  final String? lastRequestedDate;
  final String? lastRequestedPeriod;
  
  const ReportUpdateState({
    this.isLoading = false,
    this.lastRequestedDate,
    this.lastRequestedPeriod,
  });
  
  ReportUpdateState copyWith({
    bool? isLoading,
    String? lastRequestedDate,
    String? lastRequestedPeriod,
  }) {
    return ReportUpdateState(
      isLoading: isLoading ?? this.isLoading,
      lastRequestedDate: lastRequestedDate ?? this.lastRequestedDate,
      lastRequestedPeriod: lastRequestedPeriod ?? this.lastRequestedPeriod,
    );
  }
}

class ReportUpdateNotifier extends StateNotifier<ReportUpdateState> {
  final Ref ref;
  
  ReportUpdateNotifier(this.ref) : super(const ReportUpdateState());
  
  Future<void> updateReport(String period, String? date) async {
    // 重複リクエストを防ぐ
    if (state.isLoading) {
      AppLogger.debug('既にロード中のためスキップ: period=$period, date=$date');
      return;
    }
    
    if (state.lastRequestedDate == date && state.lastRequestedPeriod == period) {
      AppLogger.debug('同じリクエストのためスキップ: period=$period, date=$date');
      return;
    }
    
    AppLogger.debug('レポート更新開始: period=$period, date=$date');
    
    // ローディング状態を開始
    state = state.copyWith(
      isLoading: true,
      lastRequestedDate: date,
      lastRequestedPeriod: period,
    );
    
    try {
      // 日付を更新
      ref.read(reportDateProvider.notifier).state = date;
      
      // 少し待ってからプロバイダーを無効化（UIの更新を確保）
      await Future.delayed(const Duration(milliseconds: 50));
      
      // レポートプロバイダーを無効化して再取得
      ref.invalidate(musicReportProvider(period));
      
      // APIリクエストが完了するまで待機（ローディング状態を維持）
      await Future.delayed(const Duration(milliseconds: 300));
      
      AppLogger.debug('レポート更新完了: period=$period, date=$date');
      
    } catch (e) {
      AppLogger.error('レポート更新エラー: $e');
    } finally {
      // ローディング状態を終了
      state = state.copyWith(isLoading: false);
    }
  }
}

// 統計チャート専用プロバイダー - レポートデータとは独立
final chartStatsProvider = FutureProvider.family<dynamic, String>((
  ref,
  period,
) async {
  final selectedDate = ref.watch(reportDateProvider);

  switch (period) {
    case 'daily':
      final stats =
          await ref.watch(weekDailyStatsProvider(selectedDate).future);
      return stats;
    case 'weekly':
      final stats =
          await ref.watch(monthWeeklyStatsProvider(selectedDate).future);
      return stats;
    case 'monthly':
      final year = selectedDate?.split('-').firstOrNull;
      final stats = await ref.watch(yearMonthlyStatsProvider(year).future);
      return stats;
    default:
      throw Exception('Unknown period: $period');
  }
});

// 独立したチャートデータプロバイダー - レポートプロバイダーとは分離
// 共通キャッシュとキャッシュID管理のためのプロバイダー
final chartDataCacheProvider = StateProvider<Map<String, dynamic>>((ref) => {});
final chartDataCacheIdProvider = StateProvider<int>((ref) => 0);

// 最終リクエスト時間を記録するプロバイダー - プロバイダー初期化中にアクセスされても安全な実装
class ChartRequestTimeNotifier extends StateNotifier<DateTime> {
  ChartRequestTimeNotifier()
      : super(DateTime.now().subtract(const Duration(minutes: 5)));

  void updateLastRequestTime() {
    state = DateTime.now();
  }

  bool shouldThrottle() {
    final timeSinceLastRequest =
        DateTime.now().difference(state).inMilliseconds;
    return timeSinceLastRequest < 500;
  }
}

final lastChartRequestTimeProvider =
    StateNotifierProvider<ChartRequestTimeNotifier, DateTime>((ref) {
  return ChartRequestTimeNotifier();
});

// 最適化されたグラフデータプロバイダー - キャッシュを利用して重複リクエストを完全に防止
final independentChartDataProvider = FutureProvider.family<dynamic, String>((
  ref,
  period,
) async {
  final repository = ref.watch(musicRepositoryProvider);
  // 強制的にキャッシュを使用するためにisRefreshingの監視はしない（キャッシュIDの変更で制御）
  final cache = ref.watch(chartDataCacheProvider);
  final cacheId = ref.watch(chartDataCacheIdProvider);
  // lastChartRequestTimeProvider はnotifierとして直接使用するためここではwatchしない

  // キャッシュキーを作成
  final cacheKey = '$period-$cacheId';

  final useCache = cache.containsKey(cacheKey);
  final timeNotifier = ref.read(lastChartRequestTimeProvider.notifier);

  // キャッシュが存在する場合は常に使用（キャッシュIDが変わったときのみ新規リクエスト）
  if (useCache) {
    AppLogger.debug(
        'Using cached chart data for period: $period (cache id: $cacheId)');
    return cache[cacheKey];
  }

  // 連続APIリクエスト防止のため、最近リクエストした場合は遅延
  if (timeNotifier.shouldThrottle()) {
    AppLogger.debug('Throttling chart API request');
    await Future.delayed(const Duration(milliseconds: 200));
  }

  // 最後のリクエスト時間は後でFutureのコールバックで更新する（初期化中の状態更新を避けるため）

  AppLogger.debug(
      'Fetching independent chart data for period: $period (cache id: $cacheId)');

  // 選択された日付を考慮せず、常に最新データを取得
  dynamic result;
  dynamic stats;

  switch (period) {
    case 'daily':
      // 現在の日付ではなく、常に最新の週間データを取得
      result = await repository.getWeekDailyStats(date: null);
      stats = result.fold(
        (failure) {
          AppLogger.error('Failed to get week daily stats: ${failure.message}');
          throw Exception(failure.message);
        },
        (data) {
          AppLogger.debug(
              'Successfully loaded ${data.stats.length} days of daily stats');
          return data;
        },
      );
      break;
    case 'weekly':
      // 現在の日付ではなく、常に最新の月間週別データを取得
      result = await repository.getMonthWeeklyStats(date: null);
      stats = result.fold(
        (failure) {
          AppLogger.error(
              'Failed to get month weekly stats: ${failure.message}');
          throw Exception(failure.message);
        },
        (data) {
          AppLogger.debug(
              'Successfully loaded ${data.stats.length} weeks of weekly stats');
          return data;
        },
      );
      break;
    case 'monthly':
      // 現在の年ではなく、常に最新の年間月別データを取得
      result = await repository.getYearMonthlyStats(year: null);
      stats = result.fold(
        (failure) {
          AppLogger.error(
              'Failed to get year monthly stats: ${failure.message}');
          throw Exception(failure.message);
        },
        (data) {
          AppLogger.debug(
              'Successfully loaded ${data.stats.length} months of monthly stats');
          return data;
        },
      );
      break;
    default:
      throw Exception('Unknown period: $period');
  }

  // 結果をキャッシュに保存
  if (stats != null) {
    final updatedCache = Map<String, dynamic>.from(cache);
    updatedCache[cacheKey] = stats;
    ref.read(chartDataCacheProvider.notifier).state = updatedCache;

    // プロバイダー初期化後に最後のリクエスト時間を更新（非同期コールバック内で）
    Future.microtask(() {
      ref.read(lastChartRequestTimeProvider.notifier).updateLastRequestTime();
    });
  }

  return stats;
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

// リフレッシュ状態の追跡用プロバイダー
final isRefreshingProvider =
    StateProvider.family<bool, String>((ref, period) => false);

// Auto-refreshing Recent Tracks Provider that listens to WebSocket updates
final autoRefreshRecentTracksProvider = StreamProvider<RecentTracksResponse>((
  ref,
) async* {
  // 初期データを取得
  final repository = ref.watch(musicRepositoryProvider);
  final initialResult = await repository.getRecentTracks(limit: 10);

  yield* initialResult.fold(
    (failure) => Stream.error(Exception(failure.message)),
    (recentTracks) async* {
      yield recentTracks;

      // WebSocketストリームを監視して、Now Playingが更新されたら再生履歴を再フェッチ
      await for (final nowPlayingState in ref.watch(
        nowPlayingWithStatusProvider.stream,
      )) {
        if (nowPlayingState.data != null) {
          AppLogger.info('WebSocket updated, refreshing recent tracks');
          final refreshResult = await repository.getRecentTracks(limit: 10);
          yield* refreshResult.fold(
            (failure) => Stream.error(Exception(failure.message)),
            (refreshedTracks) => Stream.value(refreshedTracks),
          );
        }
      }
    },
  );
});

// Auto-refreshing User Stats Provider that updates when Now Playing changes
final autoRefreshUserStatsProvider = StreamProvider<UserStats>((
  ref,
) async* {
  // 初期データを取得
  final repository = ref.watch(musicRepositoryProvider);
  final initialResult = await repository.getUserStats();

  yield* initialResult.fold(
    (failure) => Stream.error(Exception(failure.message)),
    (userStats) async* {
      yield userStats;

      // WebSocketストリームを監視して、Now Playingが更新されたらユーザー統計を再フェッチ
      await for (final nowPlayingState in ref.watch(
        nowPlayingWithStatusProvider.stream,
      )) {
        if (nowPlayingState.data != null) {
          AppLogger.info('WebSocket updated, refreshing user stats');
          final refreshResult = await repository.getUserStats();
          yield* refreshResult.fold(
            (failure) => Stream.error(Exception(failure.message)),
            (refreshedStats) => Stream.value(refreshedStats),
          );
        }
      }
    },
  );
});
