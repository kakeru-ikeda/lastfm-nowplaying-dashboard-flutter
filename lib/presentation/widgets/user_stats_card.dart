import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/user_stats.dart';
import '../../core/utils/url_helper.dart';
import '../providers/music_providers.dart';
import 'section_card.dart';

class UserStatsCard extends ConsumerWidget {
  const UserStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(autoRefreshUserStatsProvider);

    return SectionCard(
      child: userStatsAsync.when(
        data: (userStats) => _UserStatsContent(userStats: userStats),
        loading: () => const _LoadingContent(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // プロフィール情報（コンパクト版）
        _CompactProfileSection(profile: userStats.profile),
        const SizedBox(height: 12),

        // 統計情報グリッド
        _StatsGrid(userStats: userStats),
      ],
    );
  }
}

class _CompactProfileSection extends StatelessWidget {
  final UserProfile profile;

  const _CompactProfileSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => UrlHelper.openInNewTab(profile.url),
        child: Row(
          children: [
            // プロフィール画像（小・枠なし・クリック可能）
            Container(
              width: 40,
              height: 40,
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
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.person,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
              ),
            ),
            const SizedBox(width: 10),

            // プロフィール詳細（圧縮版）
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ユーザー名（下線なし）
                  Text(
                    profile.username,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
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
                      fontSize: 11,
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

  const _StatsGrid({required this.userStats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          ),

        if (userStats.topArtist != null && userStats.topTrack != null)
          const SizedBox(height: 8),

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

  const _StatItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    this.url,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      cursor: url != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: url != null ? () => UrlHelper.openInNewTab(url!) : null,
        child: Container(
          padding: const EdgeInsets.all(8),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),

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
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: url != null ? color : colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 12),
            Text(
              'Loading...',
              style: TextStyle(fontSize: 12),
            ),
          ],
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
