import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/recent_track_info.dart';
import '../../core/constants/app_constants.dart';
import 'section_card.dart';
import 'clickable_track_item.dart';

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
                  return ClickableTrackItem(
                    artist: track.artist,
                    track: track.track,
                    album: track.album.isNotEmpty ? track.album : null,
                    imageUrl: track.imageUrl.isNotEmpty ? track.imageUrl : null,
                    trailing: track.playedAt != null
                        ? Text(
                            _formatPlayedAt(track.playedAt!),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
        ],
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
