import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/now_playing_card.dart';
import '../widgets/recent_tracks_card.dart';
import '../widgets/user_stats_card.dart';
import '../providers/music_providers.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/responsive_helper.dart';
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
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: ResponsiveHelper.responsiveLayout(
          context: context,
          mobile: _buildMobileLayout(context, ref),
          tablet: _buildTabletLayout(context, ref),
          desktop: _buildDesktopLayout(context, ref),
        ),
      ),
    );
  }

  /// モバイルレイアウト - スタック配置でプロフィールカードをRecent tracksの上に
  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Now Playing Card（全幅）- モバイルでは動的な高さに調整
        const NowPlayingCard(),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

        // User Stats Card（Recent tracksの上に配置）
        const UserStatsCard(),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

        // Recent Tracks Card with Pagination
        const RecentTracksCard(),
      ],
    );
  }

  /// タブレットレイアウト - アダプティブグリッド
  Widget _buildTabletLayout(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row - Now Playing + User Stats
        SizedBox(
          height: ResponsiveHelper.getNowPlayingCardHeight(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: const NowPlayingCard()),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context)),
              Expanded(flex: 2, child: const UserStatsCard()),
            ],
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

        // Recent Tracks Card with Pagination
        const RecentTracksCard(),
      ],
    );
  }

  /// デスクトップレイアウト - フル横向きレイアウト
  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        SizedBox(
          height: ResponsiveHelper.getNowPlayingCardHeight(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: const NowPlayingCard()),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context)),
              Expanded(flex: 1, child: const UserStatsCard()),
            ],
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context)),

        // Recent Tracks Card with Pagination
        const RecentTracksCard(),
      ],
    );
  }
}
