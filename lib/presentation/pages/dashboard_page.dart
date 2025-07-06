import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/now_playing_card.dart';
import '../widgets/recent_tracks_card.dart';
import '../widgets/user_stats_card.dart';
import '../widgets/simple_card.dart';
import '../widgets/app_loading_indicator.dart';
import '../providers/music_providers.dart';
import '../../core/constants/app_constants.dart';
import 'music_reports_page.dart';
import 'settings_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/lastfm_logo.png',
            width: 32,
            height: 32,
          ),
        ),
        title: const Text('Last.fm Now Playing Dashboard'),
        titleSpacing: 2.0, // アイコンとタイトル間のスペースを調整
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
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
              ref.invalidate(autoRefreshUserStatsProvider);
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
            SizedBox(
              height: 210, // +10px でNowPlayingとUser Statsカードの高さを調整
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: const NowPlayingCard()),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(flex: 1, child: const UserStatsCard()),
                ],
              ),
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
            child: const AppLoadingIndicator(
              height: 200,
              text: 'Loading recent tracks...',
            ),
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
