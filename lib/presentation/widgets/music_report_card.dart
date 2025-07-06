import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/music_providers.dart';
import '../../core/constants/app_constants.dart';
import 'section_card.dart';

class MusicReportCard extends ConsumerWidget {
  const MusicReportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final reportAsync = ref.watch(musicReportProvider(selectedPeriod));

    return SectionCard(
      icon: Icons.bar_chart,
      iconColor: const Color(AppConstants.primaryColorValue),
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
                      (value) => FlLine(color: Colors.white12, strokeWidth: 1),
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
                              style: const TextStyle(
                                color: Colors.white70,
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
                            style: const TextStyle(
                              color: Colors.white70,
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
                  border: const Border(
                    bottom: BorderSide(color: Colors.white24),
                    left: BorderSide(color: Colors.white24),
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
                    color: const Color(AppConstants.primaryColorValue),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(
                        AppConstants.primaryColorValue,
                      ).withOpacity(0.2),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[800],
            ),
            child:
                imageUrl != null && imageUrl.isNotEmpty
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const Icon(
                              Icons.music_note,
                              color: Colors.white54,
                              size: 20,
                            ),
                        errorWidget:
                            (context, url, error) => const Icon(
                              Icons.music_note,
                              color: Colors.white54,
                              size: 20,
                            ),
                      ),
                    )
                    : const Icon(
                      Icons.music_note,
                      color: Colors.white54,
                      size: 20,
                    ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  track.artist.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${track.playcount}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(AppConstants.primaryColorValue),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistItem(BuildContext context, dynamic artist) {
    final imageUrl = artist.image.isNotEmpty ? artist.image.last.text : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey[800],
            ),
            child:
                imageUrl != null && imageUrl.isNotEmpty
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const Icon(
                              Icons.person,
                              color: Colors.white54,
                              size: 20,
                            ),
                        errorWidget:
                            (context, url, error) => const Icon(
                              Icons.person,
                              color: Colors.white54,
                              size: 20,
                            ),
                      ),
                    )
                    : const Icon(Icons.person, color: Colors.white54, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              artist.name,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${artist.playcount}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(AppConstants.primaryColorValue),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
