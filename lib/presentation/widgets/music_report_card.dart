import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/music_providers.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive_helper.dart';
import 'section_card.dart';
import 'clickable_track_item.dart';
import 'clickable_artist_item.dart';
import 'app_loading_indicator.dart';
import 'detailed_stats_chart.dart';
import 'period_stats_charts.dart';

class MusicReportCard extends ConsumerWidget {
  const MusicReportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final reportAsync = ref.watch(musicReportProvider(selectedPeriod));
    final selectedDate = ref.watch(reportDateProvider);

    // 遅延更新プロバイダーを監視して、必要に応じてレポートを更新
    ref.listen<AsyncValue<void>>(
      delayedReportUpdateProvider(selectedPeriod),
      (previous, next) {
        next.whenOrNull(
          data: (_) {
            // 遅延更新が完了したらレポートを再取得
            ref.invalidate(musicReportProvider(selectedPeriod));
          },
        );
      },
    );

    // 選択された日付があれば表示
    Widget? dateChip;
    if (selectedDate != null) {
      // 選択された期間に応じたフォーマット
      String dateLabel;
      switch (selectedPeriod) {
        case 'daily':
          // 日次レポートの場合は年月日形式
          final date = DateTime.parse(selectedDate);
          dateLabel = '${date.year}/${date.month}/${date.day}';
          break;
        case 'weekly':
          // 週次レポートの場合は期間表示
          dateLabel = selectedDate; // すでに適切な形式
          break;
        case 'monthly':
          // 月次レポートの場合は年月形式
          final parts = selectedDate.split('-');
          dateLabel = '${parts[0]}/${parts[1]}';
          break;
        default:
          dateLabel = selectedDate;
      }

      dateChip = Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Wrap(
          alignment: WrapAlignment.start,
          children: [
            Chip(
              label: Text(dateLabel),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                ref.read(reportDateProvider.notifier).state = null;
                ref.invalidate(musicReportProvider(selectedPeriod));
              },
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              deleteIconColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      );
    }

    return SectionCard(
      icon: Icons.bar_chart,
      title: 'Music Report',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 選択された日付の表示
          if (dateChip != null) dateChip,

          // 独立したチャートセクション
          _IndependentStatsChartSection(period: selectedPeriod),
          const SizedBox(height: AppConstants.defaultPadding * 2),

          // 新しい期間別統計チャート
          const PeriodStatsChartSection(),
          const SizedBox(height: AppConstants.defaultPadding * 2),

          // レポートコンテンツ
          Consumer(
            builder: (context, ref, child) {
              final isRefreshing =
                  ref.watch(isRefreshingProvider(selectedPeriod));

              // リフレッシュ中の場合は明示的にローディングインジケータを表示
              if (isRefreshing) {
                return const ReportLoadingIndicator();
              }

              return reportAsync.when(
                data: (report) => _TopContentSection(report: report),
                loading: () => const ReportLoadingIndicator(),
                error: (error, stack) => _buildErrorContent(error),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(dynamic error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'レポートの取得に失敗しました',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// 独立した統計チャートセクション - reportDateProviderを監視しない
class _IndependentStatsChartSection extends ConsumerWidget {
  final String period;

  const _IndependentStatsChartSection({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // キャッシュIDを監視（リフレッシュ時に更新される）
    final cacheId = ref.watch(chartDataCacheIdProvider);

    // キャッシュIDに基づいてキーを割り当て、データが更新されたときだけ再構築されるようにする
    return DetailedStatsChart(
      key: ValueKey('independent_chart_${period}_${cacheId}'),
      period: period,
    );
  }
}

// トップコンテンツセクション - レポートデータに基づく
class _TopContentSection extends StatelessWidget {
  final dynamic report;

  const _TopContentSection({required this.report});

  @override
  Widget build(BuildContext context) {
    // レスポンシブ対応: モバイル・タブレットでは縦並び、デスクトップでは横並び
    if (ResponsiveHelper.isMobile(context) ||
        ResponsiveHelper.isTablet(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopTracksSection(context, report.topTracks),
          const SizedBox(height: AppConstants.defaultPadding * 2),
          _buildTopArtistsSection(context, report.topArtists),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildTopTracksSection(context, report.topTracks)),
          const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: _buildTopArtistsSection(context, report.topArtists),
          ),
        ],
      );
    }
  }

  Widget _buildTopTracksSection(BuildContext context, List<dynamic> tracks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Tracks',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tracks.length > 5 ? 5 : tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return ClickableTrackItem(
              track: track.name,
              artist: track.artist.name,
              trailing: Text(
                '#${index + 1} (${track.playcount} plays)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopArtistsSection(BuildContext context, List<dynamic> artists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Artists',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: artists.length > 5 ? 5 : artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return ClickableArtistItem(
              artist: artist.name,
              trailing: Text(
                '#${index + 1} (${artist.playcount} plays)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          },
        ),
      ],
    );
  }
}
