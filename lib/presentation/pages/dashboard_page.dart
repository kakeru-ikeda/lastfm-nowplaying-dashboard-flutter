import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/now_playing_card.dart';
import '../widgets/music_report_card.dart';
import '../widgets/server_stats_card.dart';
import '../widgets/period_selector.dart';
import '../providers/music_providers.dart';
import '../../core/constants/app_constants.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎵 Last.fm Now Playing Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // WebSocketストリームは自動的に更新されるが、
              // 他のプロバイダーはリフレッシュする
              ref.invalidate(musicReportProvider(selectedPeriod));
              ref.invalidate(serverStatsProvider);
              // nowPlayingStreamProviderは自動更新なのでinvalidateは不要
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
            // Header Row
            Row(
              children: [
                Expanded(flex: 2, child: const NowPlayingCard()),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(flex: 1, child: const ServerStatsCard()),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding * 2),

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
