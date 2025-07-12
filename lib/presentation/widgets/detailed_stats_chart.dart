import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/stats_response.dart';
import '../providers/music_providers.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import 'app_loading_indicator.dart';

class DetailedStatsChart extends ConsumerWidget {
  final String period;

  const DetailedStatsChart({
    super.key,
    required this.period,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 独立したチャートデータプロバイダーを使用
    final chartDataAsync = ref.watch(independentChartDataProvider(period));

    return chartDataAsync.when(
      data: (chartData) {
        switch (period) {
          case 'daily':
            return _StableWeekDailyChart(
              key: ValueKey('stable_weekly_chart_${chartData.hashCode}'),
              stats: chartData as WeekDailyStatsResponse,
            );
          case 'weekly':
            return _StableMonthWeeklyChart(
              key: ValueKey('stable_monthly_chart_${chartData.hashCode}'),
              stats: chartData as MonthWeeklyStatsResponse,
            );
          case 'monthly':
            return _StableYearMonthlyChart(
              key: ValueKey('stable_yearly_chart_${chartData.hashCode}'),
              stats: chartData as YearMonthlyStatsResponse,
            );
          default:
            return const Center(child: Text('未対応の期間です'));
        }
      },
      loading: () => const DetailedStatsLoadingIndicator(),
      error: (error, _) {
        AppLogger.error('Error loading chart data: $error');
        return Center(child: Text('Chart Error: ${error.toString()}'));
      },
    );
  }
}

// 安定したウィークリーチャート - 再描画を防ぐ
class _StableWeekDailyChart extends ConsumerStatefulWidget {
  final WeekDailyStatsResponse stats;

  const _StableWeekDailyChart({
    super.key,
    required this.stats,
  });

  @override
  ConsumerState<_StableWeekDailyChart> createState() =>
      _StableWeekDailyChartState();
}

class _StableWeekDailyChartState extends ConsumerState<_StableWeekDailyChart> {
  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;

    // デバッグ情報の出力
    AppLogger.debug(
        'Week daily chart data: ${stats.stats.length} days, meta: ${stats.meta.period}');

    if (stats.stats.isEmpty) {
      return const Center(child: Text('データがありません'));
    }

    // データ数が7日間ではない場合のログ
    if (stats.stats.length != 7) {
      AppLogger.warning(
          'Expected 7 days of data but got ${stats.stats.length} days');
    }

    return SizedBox(
      height: AppConstants.chartHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listening Activity (週間日別統計)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '過去7日間の再生状況 - タップでその日を基準とした日次レポートを表示',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.1),
                      strokeWidth: 1),
                  getDrawingVerticalLine: (value) => FlLine(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.05),
                      strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        // データポイントがある場合のみラベルを表示
                        if (index >= 0 && index < stats.stats.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              stats.stats[index].label,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() == value) {
                          return Text(
                            '${value.toInt()}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 36,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.2)),
                    bottom: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.2)),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: stats.stats.asMap().entries.map((entry) {
                      final dayIndex = entry.key.toDouble();
                      final scrobbles = entry.value.scrobbles.toDouble();
                      return FlSpot(dayIndex, scrobbles);
                    }).toList(),
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 6,
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 2,
                        strokeColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (spots) => spots.map((spot) {
                      final index = spot.x.toInt();
                      if (index >= 0 && index < stats.stats.length) {
                        final item = stats.stats[index];
                        return LineTooltipItem(
                          '${item.label}\n${item.scrobbles} scrobbles',
                          TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                      return null;
                    }).toList(),
                  ),
                  touchCallback: (event, touchResponse) {
                    if (event is FlTapUpEvent &&
                        touchResponse?.lineBarSpots != null &&
                        touchResponse!.lineBarSpots!.isNotEmpty) {
                      final spotIndex =
                          touchResponse.lineBarSpots!.first.spotIndex;
                      if (spotIndex >= 0 && spotIndex < stats.stats.length) {
                        final date = stats.stats[spotIndex].date;
                        AppLogger.debug(
                            'Tapped on day at index $spotIndex with date: $date');

                        // 日付を設定するが、即座にレポートを更新しない
                        ref.read(reportDateProvider.notifier).state = date;

                        // 遅延更新プロバイダーを使用してレポートを更新
                        ref.read(delayedReportUpdateProvider('daily'));
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 安定したマンスリーウィークリーチャート
class _StableMonthWeeklyChart extends ConsumerStatefulWidget {
  final MonthWeeklyStatsResponse stats;

  const _StableMonthWeeklyChart({
    super.key,
    required this.stats,
  });

  @override
  ConsumerState<_StableMonthWeeklyChart> createState() =>
      _StableMonthWeeklyChartState();
}

class _StableMonthWeeklyChartState
    extends ConsumerState<_StableMonthWeeklyChart> {
  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;

    if (stats.stats.isEmpty) {
      return const Center(child: Text('データがありません'));
    }

    return SizedBox(
      height: AppConstants.chartHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listening Activity (月間週別統計)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'タップでその週を基準とした週次レポートを表示',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.1),
                      strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        // データポイントがある場合のみラベルを表示
                        if (index >= 0 && index < stats.stats.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              stats.stats[index].label,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() == value) {
                          return Text(
                            '${value.toInt()}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 36,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.2)),
                    bottom: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.2)),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: stats.stats.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(),
                          entry.value.scrobbles.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 6,
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 2,
                        strokeColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (spots) => spots.map((spot) {
                      final index = spot.x.toInt();
                      if (index >= 0 && index < stats.stats.length) {
                        final item = stats.stats[index];
                        return LineTooltipItem(
                          '${item.label}\n${item.scrobbles} scrobbles',
                          TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                      return null;
                    }).toList(),
                  ),
                  touchCallback: (event, touchResponse) {
                    if (event is FlTapUpEvent &&
                        touchResponse?.lineBarSpots != null &&
                        touchResponse!.lineBarSpots!.isNotEmpty) {
                      final spotIndex =
                          touchResponse.lineBarSpots!.first.spotIndex;
                      if (spotIndex >= 0 && spotIndex < stats.stats.length) {
                        final startDate = stats.stats[spotIndex].startDate;
                        ref.read(reportDateProvider.notifier).state = startDate;
                        ref.read(delayedReportUpdateProvider('weekly'));
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 安定したイヤリーマンスリーチャート
class _StableYearMonthlyChart extends ConsumerStatefulWidget {
  final YearMonthlyStatsResponse stats;

  const _StableYearMonthlyChart({
    super.key,
    required this.stats,
  });

  @override
  ConsumerState<_StableYearMonthlyChart> createState() =>
      _StableYearMonthlyChartState();
}

class _StableYearMonthlyChartState
    extends ConsumerState<_StableYearMonthlyChart> {
  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;

    if (stats.stats.isEmpty) {
      return const Center(child: Text('データがありません'));
    }

    return SizedBox(
      height: AppConstants.chartHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listening Activity (年間月別統計)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'タップでその月を基準とした月次レポートを表示',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.1),
                      strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        // データポイントがある場合のみラベルを表示
                        if (index >= 0 && index < stats.stats.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              stats.stats[index].label,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() == value) {
                          return Text(
                            '${value.toInt()}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 36,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.2)),
                    bottom: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.2)),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: stats.stats.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(),
                          entry.value.scrobbles.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 6,
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 2,
                        strokeColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (spots) => spots.map((spot) {
                      final index = spot.x.toInt();
                      if (index >= 0 && index < stats.stats.length) {
                        final item = stats.stats[index];
                        return LineTooltipItem(
                          '${item.label}\n${item.scrobbles} scrobbles',
                          TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                      return null;
                    }).toList(),
                  ),
                  touchCallback: (event, touchResponse) {
                    if (event is FlTapUpEvent &&
                        touchResponse?.lineBarSpots != null &&
                        touchResponse!.lineBarSpots!.isNotEmpty) {
                      final spotIndex =
                          touchResponse.lineBarSpots!.first.spotIndex;
                      if (spotIndex >= 0 && spotIndex < stats.stats.length) {
                        final item = stats.stats[spotIndex];
                        final date =
                            '${item.year}-${item.month.toString().padLeft(2, '0')}-01';
                        ref.read(reportDateProvider.notifier).state = date;
                        ref.read(delayedReportUpdateProvider('monthly'));
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
