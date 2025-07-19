import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../providers/recent_tracks_pagination_provider.dart';
import 'section_card.dart';
import 'clickable_track_item.dart';
import 'app_loading_indicator.dart';

/// ページネーション機能付きの再生履歴カード
class RecentTracksCard extends ConsumerStatefulWidget {
  const RecentTracksCard({super.key});

  @override
  ConsumerState<RecentTracksCard> createState() =>
      _PaginatedRecentTracksCardState();
}

class _PaginatedRecentTracksCardState extends ConsumerState<RecentTracksCard> {
  @override
  void initState() {
    super.initState();
    // 初回データ読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recentTracksPaginationProvider.notifier).loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recentTracksPaginationProvider);

    if (state.isLoading && state.tracks.isEmpty) {
      return SectionCard(
        icon: Icons.history,
        title: 'Recent Tracks',
        child: const RecentTracksLoadingIndicator(),
      );
    }

    if (state.hasError && state.tracks.isEmpty) {
      return SectionCard(
        icon: Icons.history,
        title: 'Recent Tracks',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage ?? 'データの取得に失敗しました',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(recentTracksPaginationProvider.notifier)
                        .loadInitial();
                  },
                  child: const Text('再試行'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SectionCard(
      icon: Icons.history,
      title: 'Recent Tracks',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.pagination != null)
            Text(
              'Page ${state.pagination!.page} of ${(state.pagination!.total / state.pagination!.limit).ceil()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.refresh,
                color: Theme.of(context).colorScheme.secondary),
            onPressed: () {
              ref.read(recentTracksPaginationProvider.notifier).refresh();
            },
            tooltip: 'Refresh recent tracks',
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.tracks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.defaultPadding),
                child: Text(
                  '再生履歴がありません',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.tracks.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final track = state.tracks[index];
                return ClickableTrackItem(
                  artist: track.artist,
                  track: track.track,
                  album: track.album.isNotEmpty ? track.album : null,
                  imageUrl: track.imageUrl.isNotEmpty ? track.imageUrl : null,
                  trailing: track.playedAt != null
                      ? Text(
                          _formatPlayedAt(track.playedAt!),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                        )
                      : null,
                );
              },
            ),
            // ページネーションコントロール
            if (state.pagination != null) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              _buildPaginationControls(state),
            ],
          ],
        ],
      ),
    );
  }

  /// ページネーションコントロールを構築
  Widget _buildPaginationControls(RecentTracksPaginationState state) {
    final pagination = state.pagination!;
    final currentPage = pagination.page;
    final totalPages = (pagination.total / pagination.limit).ceil();
    final hasPrevious = currentPage > 1;
    final hasNext = currentPage < totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 前のページボタン
          IconButton(
            onPressed: hasPrevious && !state.isLoadingMore
                ? () {
                    ref
                        .read(recentTracksPaginationProvider.notifier)
                        .loadPreviousPage();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: '前のページ',
          ),

          // ページ情報とページジャンプ
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.isLoadingMore)
                const RecentTracksPaginationLoadingIndicator()
              else
                Row(
                  children: [
                    // 最初のページ
                    if (currentPage > 2) ...[
                      _buildPageButton(1, currentPage),
                      if (currentPage > 3)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('...'),
                        ),
                    ],

                    // 前のページ
                    if (hasPrevious)
                      _buildPageButton(currentPage - 1, currentPage),

                    // 現在のページ
                    _buildPageButton(currentPage, currentPage, isActive: true),

                    // 次のページ
                    if (hasNext) _buildPageButton(currentPage + 1, currentPage),

                    // 最後のページ
                    if (currentPage < totalPages - 1) ...[
                      if (currentPage < totalPages - 2)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('...'),
                        ),
                      _buildPageButton(totalPages, currentPage),
                    ],
                  ],
                ),
            ],
          ),

          // 次のページボタン
          IconButton(
            onPressed: hasNext && !state.isLoadingMore
                ? () {
                    ref
                        .read(recentTracksPaginationProvider.notifier)
                        .loadNextPage();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: '次のページ',
          ),
        ],
      ),
    );
  }

  /// ページボタンを構築
  Widget _buildPageButton(int page, int currentPage, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: isActive
            ? null
            : () {
                ref
                    .read(recentTracksPaginationProvider.notifier)
                    .loadPage(page);
              },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            page.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isActive
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ),
      ),
    );
  }

  String _formatPlayedAt(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'たった今';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
