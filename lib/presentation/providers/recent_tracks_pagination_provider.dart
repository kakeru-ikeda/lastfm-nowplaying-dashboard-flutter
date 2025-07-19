import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/recent_track_info.dart';
import '../../domain/repositories/music_repository.dart';
import '../../core/utils/helpers.dart';
import 'music_providers.dart';

/// ページネーション状態を表すクラス
class RecentTracksPaginationState {
  final List<RecentTrackInfo> tracks;
  final Pagination? pagination;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool isLoadingMore;
  final bool hasReachedEnd;

  const RecentTracksPaginationState({
    required this.tracks,
    this.pagination,
    required this.isLoading,
    required this.hasError,
    this.errorMessage,
    required this.isLoadingMore,
    required this.hasReachedEnd,
  });

  RecentTracksPaginationState copyWith({
    List<RecentTrackInfo>? tracks,
    Pagination? pagination,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    bool? isLoadingMore,
    bool? hasReachedEnd,
  }) {
    return RecentTracksPaginationState(
      tracks: tracks ?? this.tracks,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
    );
  }

  static const initial = RecentTracksPaginationState(
    tracks: [],
    isLoading: false,
    hasError: false,
    isLoadingMore: false,
    hasReachedEnd: false,
  );
}

/// RecentTracksのページネーション機能を管理するStateNotifier
class RecentTracksPaginationNotifier
    extends StateNotifier<RecentTracksPaginationState> {
  final MusicRepository _repository;
  final Ref _ref;
  static const int _defaultLimit = 10;

  RecentTracksPaginationNotifier(this._repository, this._ref)
      : super(RecentTracksPaginationState.initial) {
    // WebSocket更新を監視
    _listenToWebSocketUpdates();
  }

  /// WebSocket更新を監視してNow Playing変更時に自動リフレッシュ
  void _listenToWebSocketUpdates() {
    // NowPlayingストリームを監視
    _ref.listen(nowPlayingStreamProvider, (previous, next) {
      next.whenData((nowPlaying) {
        // データが既に読み込まれている場合のみリフレッシュ
        if (!state.isLoading && state.tracks.isNotEmpty) {
          AppLogger.info('WebSocket updated, refreshing recent tracks pagination');
          refresh();
        }
      });
    });
  }

  /// 初回データ取得
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      hasError: false,
      errorMessage: null,
    );

    try {
      final result = await _repository.getRecentTracks(
        limit: _defaultLimit,
        page: 1,
      );

      result.fold(
        (failure) {
          AppLogger.error('Failed to load initial recent tracks: ${failure.message}');
          state = state.copyWith(
            isLoading: false,
            hasError: true,
            errorMessage: failure.message,
          );
        },
        (response) {
          // 現在再生中のトラックを除外
          final filteredTracks = response.tracks
              .where((track) => !track.isPlaying)
              .toList();

          state = state.copyWith(
            tracks: filteredTracks,
            pagination: response.pagination,
            isLoading: false,
            hasError: false,
            hasReachedEnd: _checkIfReachedEnd(response.pagination),
          );
        },
      );
    } catch (e) {
      AppLogger.error('Unexpected error loading initial recent tracks', e);
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'データの取得に失敗しました',
      );
    }
  }

  /// 次のページを読み込み
  Future<void> loadNextPage() async {
    if (state.isLoadingMore || state.hasReachedEnd || state.pagination == null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.pagination!.page + 1;
      final result = await _repository.getRecentTracks(
        limit: _defaultLimit,
        page: nextPage,
      );

      result.fold(
        (failure) {
          AppLogger.error('Failed to load next page: ${failure.message}');
          state = state.copyWith(
            isLoadingMore: false,
            hasError: true,
            errorMessage: failure.message,
          );
        },
        (response) {
          // 現在再生中のトラックを除外
          final filteredNewTracks = response.tracks
              .where((track) => !track.isPlaying)
              .toList();

          // 新しいページのトラックで置き換え
          state = state.copyWith(
            tracks: filteredNewTracks,
            pagination: response.pagination,
            isLoadingMore: false,
            hasReachedEnd: _checkIfReachedEnd(response.pagination),
          );
        },
      );
    } catch (e) {
      AppLogger.error('Unexpected error loading next page', e);
      state = state.copyWith(
        isLoadingMore: false,
        hasError: true,
        errorMessage: 'データの取得に失敗しました',
      );
    }
  }

  /// 前のページを読み込み
  Future<void> loadPreviousPage() async {
    if (state.isLoadingMore || state.pagination == null || state.pagination!.page <= 1) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final previousPage = state.pagination!.page - 1;
      final result = await _repository.getRecentTracks(
        limit: _defaultLimit,
        page: previousPage,
      );

      result.fold(
        (failure) {
          AppLogger.error('Failed to load previous page: ${failure.message}');
          state = state.copyWith(
            isLoadingMore: false,
            hasError: true,
            errorMessage: failure.message,
          );
        },
        (response) {
          // 現在再生中のトラックを除外
          final filteredNewTracks = response.tracks
              .where((track) => !track.isPlaying)
              .toList();

          // 新しいページのトラックで置き換え
          state = state.copyWith(
            tracks: filteredNewTracks,
            pagination: response.pagination,
            isLoadingMore: false,
            hasReachedEnd: _checkIfReachedEnd(response.pagination),
          );
        },
      );
    } catch (e) {
      AppLogger.error('Unexpected error loading previous page', e);
      state = state.copyWith(
        isLoadingMore: false,
        hasError: true,
        errorMessage: 'データの取得に失敗しました',
      );
    }
  }

  /// 指定ページを読み込み
  Future<void> loadPage(int page) async {
    if (state.isLoadingMore || page < 1) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.getRecentTracks(
        limit: _defaultLimit,
        page: page,
      );

      result.fold(
        (failure) {
          AppLogger.error('Failed to load page $page: ${failure.message}');
          state = state.copyWith(
            isLoadingMore: false,
            hasError: true,
            errorMessage: failure.message,
          );
        },
        (response) {
          // 現在再生中のトラックを除外
          final filteredNewTracks = response.tracks
              .where((track) => !track.isPlaying)
              .toList();

          // 新しいページのトラックで置き換え
          state = state.copyWith(
            tracks: filteredNewTracks,
            pagination: response.pagination,
            isLoadingMore: false,
            hasReachedEnd: _checkIfReachedEnd(response.pagination),
          );
        },
      );
    } catch (e) {
      AppLogger.error('Unexpected error loading page $page', e);
      state = state.copyWith(
        isLoadingMore: false,
        hasError: true,
        errorMessage: 'データの取得に失敗しました',
      );
    }
  }

  /// データをリフレッシュ
  Future<void> refresh() async {
    state = RecentTracksPaginationState.initial;
    await loadInitial();
  }

  /// 終端チェック
  bool _checkIfReachedEnd(Pagination pagination) {
    final totalPages = (pagination.total / pagination.limit).ceil();
    return pagination.page >= totalPages;
  }
}

/// RecentTracksPaginationNotifierのProvider
final recentTracksPaginationProvider = StateNotifierProvider<
    RecentTracksPaginationNotifier, RecentTracksPaginationState>((ref) {
  final repository = ref.watch(musicRepositoryProvider);
  return RecentTracksPaginationNotifier(repository, ref);
});
