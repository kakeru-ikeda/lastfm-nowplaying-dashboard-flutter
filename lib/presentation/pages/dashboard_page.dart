import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/now_playing_card.dart';
import '../widgets/server_stats_card.dart';
import '../widgets/recent_tracks_card.dart';
import '../widgets/simple_card.dart';
import '../providers/music_providers.dart';
import '../../core/constants/app_constants.dart';
import 'music_reports_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎵 Last.fm Now Playing Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Music Reports',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MusicReportsPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // WebSocketストリームは自動的に更新されるが、
              // 他のプロバイダーはリフレッシュする
              ref.invalidate(autoRefreshRecentTracksProvider);
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: const NowPlayingCard()),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(flex: 1, child: const ServerStatsCard()),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Recent Tracks Card
            const RecentTracksSection(),
          ],
        ),
      ),
    );
  }
}

class RecentTracksSection extends ConsumerWidget {
  const RecentTracksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentTracksAsync = ref.watch(autoRefreshRecentTracksProvider);

    return recentTracksAsync.when(
      data:
          (recentTracks) => RecentTracksCard(
            tracks: recentTracks.tracks,
            onRefresh: () => ref.invalidate(autoRefreshRecentTracksProvider),
          ),
      loading:
          () => SimpleCard(
            height: 200,
            child: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, stackTrace) => SimpleCard(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    '再生履歴の読み込みに失敗しました\n$error',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        () => ref.invalidate(autoRefreshRecentTracksProvider),
                    child: const Text('再試行'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
