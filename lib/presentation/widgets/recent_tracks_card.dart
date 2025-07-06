import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/recent_track_info.dart';
import '../../core/constants/app_constants.dart';
import 'section_card.dart';

class RecentTracksCard extends ConsumerWidget {
  final List<RecentTrackInfo> tracks;
  final VoidCallback? onRefresh;

  const RecentTracksCard({Key? key, required this.tracks, this.onRefresh})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 現在再生中のトラックを履歴から除外
    final filteredTracks = tracks.where((track) => !track.isPlaying).toList();

    return SectionCard(
      icon: Icons.history,
      iconColor: const Color(AppConstants.primaryColorValue),
      title: 'Recent Tracks',
      trailing: onRefresh != null
          ? IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRefresh,
              tooltip: 'Refresh recent tracks',
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (filteredTracks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.defaultPadding),
                child: Text(
                  '再生履歴がありません',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filteredTracks.length,
                separatorBuilder:
                    (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final track = filteredTracks[index];
                  return _RecentTrackTile(track: track);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentTrackTile extends StatelessWidget {
  final RecentTrackInfo track;

  const _RecentTrackTile({Key? key, required this.track}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: _buildAlbumArt(),
      title: Text(
        track.track.isNotEmpty ? track.track : 'Unknown Track',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            track.artist.isNotEmpty ? track.artist : 'Unknown Artist',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (track.album.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              track.album,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (track.playedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              _formatPlayedAt(track.playedAt!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[400],
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
      // 現在再生中のトラックは既にフィルタリングされているため、trailing iconは不要
    );
  }

  Widget _buildAlbumArt() {
    if (track.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          track.imageUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultArt(),
        ),
      );
    }
    return _buildDefaultArt();
  }

  Widget _buildDefaultArt() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.music_note, color: Colors.grey, size: 24),
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
