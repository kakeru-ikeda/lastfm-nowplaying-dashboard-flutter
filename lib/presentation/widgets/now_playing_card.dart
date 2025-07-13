import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/music_providers.dart';
import '../../core/utils/url_helper.dart';
import '../../core/utils/responsive_helper.dart';
import 'section_card.dart';
import 'app_loading_indicator.dart';

class NowPlayingCard extends ConsumerStatefulWidget {
  const NowPlayingCard({super.key});

  @override
  ConsumerState<NowPlayingCard> createState() => _NowPlayingCardState();
}

class _NowPlayingCardState extends ConsumerState<NowPlayingCard>
    with TickerProviderStateMixin {
  late AnimationController _liveAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _waveAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();

    // LIVEインジケーターのスケールアニメーション
    _liveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // パルス（点滅）アニメーション
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // 音波アニメーション
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _liveAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _waveAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // アニメーションを開始
    _startAnimations();
  }

  void _startAnimations() {
    _liveAnimationController.repeat(reverse: true);
    _pulseAnimationController.repeat(reverse: true);
    _waveAnimationController.repeat();
  }

  @override
  void dispose() {
    _liveAnimationController.dispose();
    _pulseAnimationController.dispose();
    _waveAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nowPlayingAsync = ref.watch(nowPlayingStreamProvider);
    final connectionState = ref.watch(webSocketConnectionStateProvider);

    return SectionCard(
      icon: Icons.music_note,
      title: 'Now Playing',
      trailing: _buildConnectionIndicator(connectionState),
      // モバイルでは高さを指定しない（内容に応じて動的に調整）
      height: ResponsiveHelper.isMobile(context)
          ? null
          : ResponsiveHelper.getNowPlayingCardHeight(context),
      child: nowPlayingAsync.when(
        data: (nowPlaying) => _buildNowPlayingContent(context, nowPlaying),
        loading: () => const NowPlayingLoadingIndicator(),
        error: (error, stack) => _buildErrorContent(error),
      ),
    );
  }

  Widget _buildNowPlayingContent(BuildContext context, nowPlaying) {
    if (!nowPlaying.isPlaying) {
      return _buildNotPlayingContent(context);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (nowPlaying.artist != null && nowPlaying.track != null) {
            final url = UrlHelper.generateLastfmTrackUrl(
              nowPlaying.artist!,
              nowPlaying.track!,
            );
            UrlHelper.openInNewTab(url);
          }
        },
        child: ResponsiveHelper.isMobile(context)
            ? _buildMobileLayout(context, nowPlaying)
            : _buildDesktopLayout(context, nowPlaying),
      ),
    );
  }

  /// モバイル用の縦向きレイアウト
  Widget _buildMobileLayout(BuildContext context, nowPlaying) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Album Art（大きく表示）
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[800],
              ),
              child: nowPlaying.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: nowPlaying.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: ImageLoadingIndicator(),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.music_note,
                          color: Theme.of(
                            context,
                          ).iconTheme.color?.withOpacity(0.6),
                          size: 80,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.music_note,
                      color: Theme.of(
                        context,
                      ).iconTheme.color?.withOpacity(0.6),
                      size: 80,
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Track Info（中央揃え）
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  nowPlaying.track ?? 'Unknown Track',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  nowPlaying.artist ?? 'Unknown Artist',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.color?.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (nowPlaying.album != null &&
                    nowPlaying.album!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    nowPlaying.album!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),

                // Playing Indicator with Animation
                Center(
                  child: _buildAnimatedLiveIndicator(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// デスクトップ/タブレット用の横向きレイアウト
  Widget _buildDesktopLayout(BuildContext context, nowPlaying) {
    return Row(
      children: [
        // Album Art
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[800],
          ),
          child: nowPlaying.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: nowPlaying.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: ImageLoadingIndicator(),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.music_note,
                      color: Theme.of(
                        context,
                      ).iconTheme.color?.withOpacity(0.6),
                      size: 60,
                    ),
                  ),
                )
              : Icon(
                  Icons.music_note,
                  color: Theme.of(
                    context,
                  ).iconTheme.color?.withOpacity(0.6),
                  size: 60,
                ),
        ),
        const SizedBox(width: 16),

        // Track Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nowPlaying.track ?? 'Unknown Track',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                nowPlaying.artist ?? 'Unknown Artist',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color?.withOpacity(0.7),
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (nowPlaying.album != null && nowPlaying.album!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  nowPlaying.album!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // Playing Indicator with Animation
        _buildAnimatedLiveIndicator(context),
      ],
    );
  }

  Widget _buildNotPlayingContent(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120, // アートワークと同じ高さに調整
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off,
              size: 48,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Nothing is playing',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color?.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(Object error) {
    return Container(
      width: double.infinity,
      height: 120, // アートワークと同じ高さに調整
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 32, color: Colors.red),
            const SizedBox(height: 8),
            const Text(
              'Connection Error',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'WebSocket接続に失敗',
              style: TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

  Widget _buildAnimatedLiveIndicator(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _liveAnimationController,
        _pulseAnimationController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.secondary.withOpacity(_opacityAnimation.value),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: _scaleAnimation.value * 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildWaveAnimation(context),
                const SizedBox(width: 6),
                _buildAnimatedText(context),
                const SizedBox(width: 6),
                _buildStreamIcon(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveAnimation(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.secondary.computeLuminance() > 0.5
            ? Colors.black
            : Colors.white;

    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 20,
          height: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (index) {
              final delay = index * 0.25;
              final animValue = (_waveAnimation.value + delay) % 1.0;
              final height = 4.0 + (sin(animValue * 2 * 3.14159) * 6 + 6);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 3,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedText(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimationController,
      builder: (context, child) {
        return Text(
          'LIVE',
          style: TextStyle(
            color: (Theme.of(context).colorScheme.secondary.computeLuminance() >
                        0.5
                    ? Colors.black
                    : Colors.white)
                .withOpacity(_opacityAnimation.value),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        );
      },
    );
  }

  Widget _buildStreamIcon(BuildContext context) {
    return AnimatedBuilder(
      animation: _liveAnimationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _liveAnimationController.value * 0.1,
          child: Icon(
            Icons.stream,
            color:
                Theme.of(context).colorScheme.secondary.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
            size: 14,
          ),
        );
      },
    );
  }
}
