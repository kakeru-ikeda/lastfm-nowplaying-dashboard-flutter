import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/utils/period_calculator.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../providers/period_providers.dart';
import '../providers/music_providers.dart';
import 'period_navigation_bar.dart';
import 'app_loading_indicator.dart';

/// 期間別統計チャートセクション
class PeriodStatsChartSection extends ConsumerWidget {
  const PeriodStatsChartSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    // 選択された期間に応じてチャートを表示
    switch (selectedPeriod) {
      case 'daily':
        return _PeriodStatsCard(
          periodType: PeriodType.weekly,
          child: _WeeklyStatsChart(),
        );
      case 'weekly':
        return _PeriodStatsCard(
          periodType: PeriodType.monthly,
          child: _MonthlyStatsChart(),
        );
      case 'monthly':
        return _PeriodStatsCard(
          periodType: PeriodType.yearly,
          child: _YearlyStatsChart(),
        );
      default:
        return _PeriodStatsCard(
          periodType: PeriodType.weekly,
          child: _WeeklyStatsChart(),
        );
    }
  }
}

/// 期間統計カード
class _PeriodStatsCard extends ConsumerWidget {
  final PeriodType periodType;
  final Widget child;

  const _PeriodStatsCard({
    required this.periodType,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ナビゲーション
            PeriodNavigationBar(periodType: periodType),
            const SizedBox(height: AppConstants.defaultPadding),

            // チャート
            child,
          ],
        ),
      ),
    );
  }
}

/// 週間統計チャート
class _WeeklyStatsChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(weeklyPeriodProvider);
    final statsAsync = ref.watch(periodWeekDailyStatsProvider(period));

    return SizedBox(
      height: AppConstants.chartHeight,
      child: statsAsync.when(
        data: (stats) {
          if (stats.stats.isEmpty) {
            return const Center(child: Text('データがありません'));
          }

          return LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 1,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
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
                        .withOpacity(0.2),
                  ),
                  bottom: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.2),
                  ),
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
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
                        '${item.scrobbles} scrobbles',
                        TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return null;
                  }).toList(),
                ),
              ),
            ),
          );
        },
        loading: () => const AppLoadingIndicator(),
        error: (error, stack) {
          AppLogger.error('Weekly stats chart error: $error');
          return Center(
            child: Text('エラーが発生しました: ${error.toString()}'),
          );
        },
      ),
    );
  }
}

/// 月間統計チャート
class _MonthlyStatsChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(monthlyPeriodProvider);
    final statsAsync = ref.watch(periodMonthWeeklyStatsProvider(period));

    return SizedBox(
      height: AppConstants.chartHeight,
      child: statsAsync.when(
        data: (stats) {
          if (stats.stats.isEmpty) {
            return const Center(child: Text('データがありません'));
          }

          return BarChart(
            BarChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < stats.stats.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '第${stats.stats[index].weekNumber}週',
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
                        .withOpacity(0.2),
                  ),
                  bottom: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.2),
                  ),
                ),
              ),
              barGroups: stats.stats.asMap().entries.map((entry) {
                final index = entry.key;
                final scrobbles = entry.value.scrobbles.toDouble();
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: scrobbles,
                      color: Theme.of(context).colorScheme.secondary,
                      width: 20,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (groupIndex >= 0 && groupIndex < stats.stats.length) {
                      final item = stats.stats[groupIndex];
                      return BarTooltipItem(
                        '${item.scrobbles} scrobbles',
                        TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
          );
        },
        loading: () => const AppLoadingIndicator(),
        error: (error, stack) {
          AppLogger.error('Monthly stats chart error: $error');
          return Center(
            child: Text('エラーが発生しました: ${error.toString()}'),
          );
        },
      ),
    );
  }
}

/// 年間統計チャート
class _YearlyStatsChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(yearlyPeriodProvider);
    final statsAsync = ref.watch(periodYearMonthlyStatsProvider(period));

    return SizedBox(
      height: AppConstants.chartHeight,
      child: statsAsync.when(
        data: (stats) {
          if (stats.stats.isEmpty) {
            return const Center(child: Text('データがありません'));
          }

          return LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 1,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < stats.stats.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${stats.stats[index].month}月',
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
                        .withOpacity(0.2),
                  ),
                  bottom: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.2),
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: stats.stats.asMap().entries.map((entry) {
                    final monthIndex = entry.key.toDouble();
                    final scrobbles = entry.value.scrobbles.toDouble();
                    return FlSpot(monthIndex, scrobbles);
                  }).toList(),
                  isCurved: true,
                  color: Theme.of(context).colorScheme.tertiary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 6,
                      color: Theme.of(context).colorScheme.tertiary,
                      strokeWidth: 2,
                      strokeColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color:
                        Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
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
                        '${item.scrobbles} scrobbles',
                        TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return null;
                  }).toList(),
                ),
              ),
            ),
          );
        },
        loading: () => const AppLoadingIndicator(),
        error: (error, stack) {
          AppLogger.error('Yearly stats chart error: $error');
          return Center(
            child: Text('エラーが発生しました: ${error.toString()}'),
          );
        },
      ),
    );
  }
}
