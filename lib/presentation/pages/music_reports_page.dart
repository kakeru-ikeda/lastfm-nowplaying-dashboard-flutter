import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/music_report_card.dart';
import '../widgets/period_selector.dart';
import '../providers/music_providers.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';

class MusicReportsPage extends ConsumerWidget {
  const MusicReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(reportDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎵 Music Reports'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 日付リセットボタン (選択されている場合のみ表示)
          if (selectedDate != null)
            Consumer(
              builder: (context, ref, _) {
                final selectedPeriod = ref.watch(selectedPeriodProvider);
                final isRefreshing =
                    ref.watch(isRefreshingProvider(selectedPeriod));

                return IconButton(
                  icon: isRefreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.0))
                      : const Icon(Icons.calendar_today),
                  tooltip: '選択日をリセット',
                  onPressed: isRefreshing
                      ? null
                      : () async {
                          // リフレッシュ状態を更新
                          ref
                              .read(
                                  isRefreshingProvider(selectedPeriod).notifier)
                              .state = true;

                          // 日付をリセット
                          ref.read(reportDateProvider.notifier).state = null;

                          // プロバイダーを無効化
                          ref.invalidate(musicReportProvider(selectedPeriod));

                          // チャートデータのキャッシュIDを更新して強制的に再フェッチ
                          final currentCacheId =
                              ref.read(chartDataCacheIdProvider);
                          ref.read(chartDataCacheIdProvider.notifier).state =
                              currentCacheId + 1;

                          // レポートデータの取得のみ待つ（グラフデータはキャッシュIDによって制御済み）
                          try {
                            // レポートデータの取得を待つ
                            await ref.read(
                                musicReportProvider(selectedPeriod).future);

                            // キャッシュからグラフデータを同期的に取得（APIリクエストなし）
                            final cacheKey =
                                '$selectedPeriod-${ref.read(chartDataCacheIdProvider)}';
                            final cache = ref.read(chartDataCacheProvider);
                            if (cache.containsKey(cacheKey)) {
                              AppLogger.debug(
                                  'カレンダーリセット完了: レポートを更新し、グラフはキャッシュを使用');
                            } else {
                              AppLogger.debug(
                                  'カレンダーリセット完了: レポートを更新し、グラフは次回の表示で更新');
                            }
                          } catch (e) {
                            AppLogger.error('カレンダーリセットエラー: $e');
                            // エラーが発生した場合も処理を続行
                          } finally {
                            // 処理が完了したらリフレッシュ状態を元に戻す
                            ref
                                .read(isRefreshingProvider(selectedPeriod)
                                    .notifier)
                                .state = false;
                          }
                        },
                );
              },
            ),
          Consumer(
            builder: (context, ref, _) {
              final selectedPeriod = ref.watch(selectedPeriodProvider);
              final isRefreshing =
                  ref.watch(isRefreshingProvider(selectedPeriod));

              return IconButton(
                icon: isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.0))
                    : const Icon(Icons.refresh),
                onPressed: isRefreshing
                    ? null
                    : () async {
                        // リフレッシュ状態を更新
                        ref
                            .read(isRefreshingProvider(selectedPeriod).notifier)
                            .state = true;

                        // プロバイダーを無効化
                        ref.invalidate(musicReportProvider(selectedPeriod));

                        // チャートデータのキャッシュIDを更新して強制的に再フェッチ
                        final currentCacheId =
                            ref.read(chartDataCacheIdProvider);
                        ref.read(chartDataCacheIdProvider.notifier).state =
                            currentCacheId + 1;

                        // レポートデータの取得のみ待つ（グラフデータはキャッシュIDによって制御済み）
                        try {
                          // レポートデータの取得を待つ
                          await ref
                              .read(musicReportProvider(selectedPeriod).future);

                          // キャッシュからグラフデータを同期的に取得（APIリクエストなし）
                          final cacheKey =
                              '$selectedPeriod-${ref.read(chartDataCacheIdProvider)}';
                          final cache = ref.read(chartDataCacheProvider);
                          if (cache.containsKey(cacheKey)) {
                            AppLogger.debug('リフレッシュ完了: レポートを更新し、グラフはキャッシュを使用');
                          } else {
                            AppLogger.debug('リフレッシュ完了: レポートを更新し、グラフは次回の表示で更新');
                          }
                        } catch (e) {
                          AppLogger.error('リフレッシュエラー: $e');
                          // エラーが発生した場合も処理を続行
                        } finally {
                          // 処理が完了したらリフレッシュ状態を元に戻す
                          ref
                              .read(
                                  isRefreshingProvider(selectedPeriod).notifier)
                              .state = false;
                        }
                      },
              );
            },
          ),
          const SizedBox(width: AppConstants.defaultPadding),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            const PeriodSelector(),
            const SizedBox(height: AppConstants.defaultPadding),

            // Music Report
            const MusicReportCard(),
          ],
        ),
      ),
    );
  }
}
