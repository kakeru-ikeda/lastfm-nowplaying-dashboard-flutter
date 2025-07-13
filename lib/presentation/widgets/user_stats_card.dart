import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/user_stats.dart';
import '../../core/utils/url_helper.dart';
import '../../core/utils/responsive_helper.dart';
import '../providers/music_providers.dart';
import 'section_card.dart';
import 'app_loading_indicator.dart';

class UserStatsCard extends ConsumerWidget {
  const UserStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(autoRefreshUserStatsProvider);

    return SectionCard(
      child: userStatsAsync.when(
        data: (userStats) => _UserStatsContent(userStats: userStats),
        loading: () => const UserStatsLoadingIndicator(),
        error: (error, stack) => _ErrorContent(error: error.toString()),
      ),
    );
  }
}

class _UserStatsContent extends StatelessWidget {
  final UserStats userStats;

  const _UserStatsContent({required this.userStats});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // プロフィール情報（コンパクト版）
        _CompactProfileSection(profile: userStats.profile, isMobile: isMobile),
        SizedBox(height: isMobile ? 8 : 12),

        // 統計情報グリッド（モバイルでは縦並び）
        _StatsGrid(userStats: userStats, isMobile: isMobile),
      ],
    );
  }
}

class _CompactProfileSection extends StatelessWidget {
  final UserProfile profile;
  final bool isMobile;

  const _CompactProfileSection({required this.profile, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imageSize = isMobile ? 32.0 : 40.0;
    final iconSize = isMobile ? 16.0 : 20.0;
    final spacing = isMobile ? 8.0 : 10.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => UrlHelper.openInNewTab(profile.url),
        child: Row(
          children: [
            // プロフィール画像（小・枠なし・クリック可能）
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceVariant,
              ),
              child: ClipOval(
                child: profile.profileImage != null
                    ? CachedNetworkImage(
                        imageUrl: profile.profileImage!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Icon(
                          Icons.person,
                          size: iconSize,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.person,
                          size: iconSize,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: iconSize,
                        color: colorScheme.onSurfaceVariant,
                      ),
              ),
            ),
            SizedBox(width: spacing),

            // プロフィール詳細（圧縮版）
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ユーザー名（下線なし）
                  Text(
                    profile.username,
                    style: GoogleFonts.outfit(
                      fontSize: isMobile ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 統計情報（シンプル）
                  Text(
                    '${_formatPlayCount(profile.totalPlayCount)} plays',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: isMobile ? 10 : 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPlayCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _StatsGrid extends StatelessWidget {
  final UserStats userStats;
  final bool isMobile;

  const _StatsGrid({required this.userStats, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final spacing = isMobile ? 6.0 : 8.0;

    return Column(
      children: [
        // トップアーティスト
        if (userStats.topArtist != null)
          _StatItem(
            icon: Icons.person,
            title: 'Top Artist',
            subtitle: userStats.topArtist!.name,
            value: '${_formatPlayCount(userStats.topArtist!.playCount)} plays',
            color: colorScheme.primary,
            url: userStats.topArtist!.url,
            isMobile: isMobile,
          ),

        if (userStats.topArtist != null && userStats.topTrack != null)
          SizedBox(height: spacing),

        // トップトラック
        if (userStats.topTrack != null)
          _StatItem(
            icon: Icons.music_note,
            title: 'Top Track',
            subtitle:
                '${userStats.topTrack!.name} - ${userStats.topTrack!.artist}',
            value: '${_formatPlayCount(userStats.topTrack!.playCount)} plays',
            color: colorScheme.secondary,
            url: userStats.topTrack!.url,
            isMobile: isMobile,
          ),
      ],
    );
  }

  String _formatPlayCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final Color color;
  final String? url;
  final bool isMobile;

  const _StatItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    this.url,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final padding = isMobile ? 6.0 : 8.0;
    final iconSize = isMobile ? 12.0 : 14.0;
    final containerPadding = isMobile ? 4.0 : 6.0;

    return MouseRegion(
      cursor: url != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: url != null ? () => UrlHelper.openInNewTab(url!) : null,
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: color.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              // アイコン
              Container(
                padding: EdgeInsets.all(containerPadding),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: color,
                ),
              ),
              SizedBox(width: padding),

              // テキスト情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 11 : null,
                      ),
                    ),
                    SizedBox(height: isMobile ? 1 : 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: url != null ? color : colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: isMobile ? 10 : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 値
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 10 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  final String error;

  const _ErrorContent({required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'An error occurred',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
