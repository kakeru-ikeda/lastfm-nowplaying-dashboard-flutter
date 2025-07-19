import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// アプリケーション全体で使用される統一されたローディングアニメーション
class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final String? text;
  final double? height;

  const AppLoadingIndicator({
    super.key,
    this.size = 30.0,
    this.color,
    this.text,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadingColor = color ?? theme.colorScheme.primary;

    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SpinKitWave(
          color: loadingColor,
          size: size,
        ),
        if (text != null) ...[
          const SizedBox(height: 16),
          Text(
            text!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    if (height != null) {
      return SizedBox(
        height: height,
        child: Center(child: content),
      );
    }

    return Center(child: content);
  }
}

/// ユーザー統計カード用のコンパクトローディング
class UserStatsLoadingIndicator extends StatelessWidget {
  const UserStatsLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLoadingIndicator(
      size: 24.0,
      text: 'Loading...',
      height: 120,
    );
  }
}

/// Now Playingカード用のローディング
class NowPlayingLoadingIndicator extends StatelessWidget {
  const NowPlayingLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLoadingIndicator(
      size: 30.0,
      text: 'Loading now playing...',
      height: 120,
    );
  }
}

/// サーバー統計カード用のローディング
class ServerStatsLoadingIndicator extends StatelessWidget {
  const ServerStatsLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLoadingIndicator(
      size: 30.0,
      text: 'Loading stats...',
    );
  }
}

/// レポートカード用のローディング
class ReportLoadingIndicator extends StatelessWidget {
  const ReportLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLoadingIndicator(
      size: 30.0,
      text: 'Loading report...',
      height: 200,
    );
  }
}

/// 詳細統計チャート用のローディング
class DetailedStatsLoadingIndicator extends StatelessWidget {
  const DetailedStatsLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLoadingIndicator(
      size: 30.0,
      text: 'Loading chart data...',
      height: 200,
    );
  }
}

/// RecentTracks用のローディング
class RecentTracksLoadingIndicator extends StatelessWidget {
  const RecentTracksLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLoadingIndicator(
      size: 24.0,
      text: 'Loading recent tracks...',
      height: 150,
    );
  }
}

/// RecentTracksページネーション用の小さなローディング
class RecentTracksPaginationLoadingIndicator extends StatelessWidget {
  const RecentTracksPaginationLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLoadingIndicator(
      size: 16.0,
      height: 20,
    );
  }
}

/// CachedNetworkImage用の小さなローディング
class ImageLoadingIndicator extends StatelessWidget {
  const ImageLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLoadingIndicator(
      size: 20.0,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
