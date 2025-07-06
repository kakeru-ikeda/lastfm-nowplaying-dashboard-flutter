import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/music_providers.dart';
import '../../core/constants/app_constants.dart';
import 'section_card.dart';
import 'clickable_track_item.dart';
import 'clickable_artist_item.dart';

class MusicReportCard extends ConsumerWidget {
  const MusicReportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final reportAsync = ref.watch(musicReportProvider(selectedPeriod));

    return SectionCard(
      icon: Icons.bar_chart,
      title: 'Music Report',
      child: reportAsync.when(
        data: (report) => _buildReportContent(context, report),
        loading: () => _buildLoadingContent(),
        error: (error, stack) => _buildErrorContent(error),
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, report) {
    return Column(
      children: [
        // Listening Trends Chart
        _buildListeningChart(context, report.listeningTrends),
        const SizedBox(height: AppConstants.defaultPadding * 2),

        // Top Content Sections
        Row(
          children: [
            Expanded(child: _buildTopTracksSection(context, report.topTracks)),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: _buildTopArtistsSection(context, report.topArtists),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildListeningChart(BuildContext context, List<dynamic> trends) {
    if (trends.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: AppConstants.chartHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listening Activity',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine:
                      (value) => FlLine(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < trends.length) {
                          final trend = trends[index];
                          final date = DateTime.parse(trend.date);
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${date.month}/${date.day}',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                    left: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                  ),
                ),
                minX: 0,
                maxX: trends.length.toDouble() - 1,
                minY: 0,
                maxY:
                    trends
                        .map<double>((t) => t.scrobbles.toDouble())
                        .reduce((a, b) => a > b ? a : b) *
                    1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots:
                        trends.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            entry.value.scrobbles.toDouble(),
                          );
                        }).toList(),
                    isCurved: true,
                    color: Theme.of(context).colorScheme.secondary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTracksSection(BuildContext context, List<dynamic> topTracks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Tracks',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...topTracks.take(5).map((track) => _buildTrackItem(context, track)),
      ],
    );
  }

  Widget _buildTopArtistsSection(
    BuildContext context,
    List<dynamic> topArtists,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Artists',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...topArtists
            .take(5)
            .map((artist) => _buildArtistItem(context, artist)),
      ],
    );
  }

  Widget _buildTrackItem(BuildContext context, dynamic track) {
    final imageUrl = track.image.isNotEmpty ? track.image.last.text : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClickableTrackItem(
        artist: track.artist.name,
        track: track.name,
        imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
        trailing: Text(
          '${track.playcount}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        padding: const EdgeInsets.all(0),
      ),
    );
  }

  Widget _buildArtistItem(BuildContext context, dynamic artist) {
    final imageUrl = artist.image.isNotEmpty ? artist.image.last.text : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClickableArtistItem(
        artist: artist.name,
        imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
        trailing: Text(
          '${artist.playcount}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        padding: const EdgeInsets.all(0),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return SizedBox(
      height: 200,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading report...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(Object error) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading report', style: TextStyle(color: Colors.red)),
            Text(
              error.toString(),
              style: TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
