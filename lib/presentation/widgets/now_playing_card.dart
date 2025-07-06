import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/music_providers.dart';
import '../../core/constants/app_constants.dart';

class NowPlayingCard extends ConsumerWidget {
  const NowPlayingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlayingAsync = ref.watch(nowPlayingStreamProvider);
    final connectionState = ref.watch(webSocketConnectionStateProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.music_note,
                  color: Color(AppConstants.primaryColorValue),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Now Playing',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildConnectionIndicator(connectionState),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            nowPlayingAsync.when(
              data:
                  (nowPlaying) => _buildNowPlayingContent(context, nowPlaying),
              loading: () => _buildLoadingContent(),
              error: (error, stack) => _buildErrorContent(error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNowPlayingContent(BuildContext context, nowPlaying) {
    if (!nowPlaying.isPlaying) {
      return _buildNotPlayingContent(context);
    }

    return Row(
      children: [
        // Album Art
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[800],
          ),
          child:
              nowPlaying.imageUrl != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: nowPlaying.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                      errorWidget:
                          (context, url, error) => const Icon(
                            Icons.music_note,
                            color: Colors.white54,
                            size: 40,
                          ),
                    ),
                  )
                  : const Icon(
                    Icons.music_note,
                    color: Colors.white54,
                    size: 40,
                  ),
        ),
        const SizedBox(width: AppConstants.defaultPadding),

        // Track Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nowPlaying.track ?? 'Unknown Track',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                nowPlaying.artist ?? 'Unknown Artist',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (nowPlaying.album != null && nowPlaying.album!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  nowPlaying.album!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // Playing Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(AppConstants.primaryColorValue),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPlayingAnimation(),
              const SizedBox(width: 4),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.stream, color: Colors.white, size: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotPlayingContent(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
      child: Column(
        children: [
          Icon(Icons.music_off, size: 48, color: Colors.white38),
          const SizedBox(height: 8),
          Text(
            'Nothing is playing',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading now playing...'),
        ],
      ),
    );
  }

  Widget _buildErrorContent(Object error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          const Text(
            'Connection Error',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'WebSocketの接続に失敗しました。\nサーバーが起動しているか確認してください。',
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Error: ${error.toString()}',
            style: TextStyle(color: Colors.red.withOpacity(0.7), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayingAnimation() {
    return SizedBox(
      width: 16,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 600 + (index * 100)),
            tween: Tween(begin: 4.0, end: 16.0),
            builder: (context, value, child) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 50)),
                width: 3,
                height: value,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            },
            onEnd: () {
              // アニメーションを繰り返すためのトリガー
            },
          );
        }),
      ),
    );
  }

  Widget _buildConnectionIndicator(String connectionState) {
    Color indicatorColor;
    IconData indicatorIcon;
    String tooltip;

    switch (connectionState) {
      case 'connected':
        indicatorColor = Colors.green;
        indicatorIcon = Icons.wifi;
        tooltip = 'WebSocket接続中';
        break;
      case 'connecting':
        indicatorColor = Colors.orange;
        indicatorIcon = Icons.wifi_tethering;
        tooltip = '接続中...';
        break;
      case 'error':
        indicatorColor = Colors.red;
        indicatorIcon = Icons.wifi_off;
        tooltip = '接続エラー';
        break;
      default:
        indicatorColor = Colors.grey;
        indicatorIcon = Icons.wifi_off;
        tooltip = '未接続';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: indicatorColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: indicatorColor, width: 1),
        ),
        child: Icon(indicatorIcon, size: 16, color: indicatorColor),
      ),
    );
  }
}
