import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/now_playing_info.dart';
import '../../domain/entities/music_report.dart';
import '../../domain/entities/server_stats.dart';
import '../../domain/entities/recent_track_info.dart';
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

final serverStatsProvider = FutureProvider<ServerStats>((ref) async {
  final repository = ref.watch(musicRepositoryProvider);
  final result = await repository.getServerStats();

  return result.fold((failure) {
    AppLogger.error('Failed to get server stats: ${failure.message}');
    throw Exception(failure.message);
  }, (stats) => stats);
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

// レポート日付プロバイダー - 初期値として今日の日付を設定
final reportDateProvider = StateProvider<String?>((ref) {
  final today = DateTime.now();
  return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
});

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
final reportUpdateNotifierProvider =
    StateNotifierProvider<ReportUpdateNotifier, ReportUpdateState>((ref) {
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

    if (state.lastRequestedDate == date &&
        state.lastRequestedPeriod == period) {
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

      // APIリクエストの完了を待つ
      await ref.read(musicReportProvider(period).future);

      AppLogger.debug('レポート更新完了: period=$period, date=$date');
    } catch (e) {
      AppLogger.error('レポート更新エラー: $e');
    } finally {
      // ローディング状態を終了
      state = state.copyWith(isLoading: false);
    }
  }
}

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
