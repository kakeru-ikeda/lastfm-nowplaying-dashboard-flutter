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
    final selectedDate = ref.watch(reportDateProvider);

    return SizedBox(
      height: AppConstants.chartHeight,
      child: statsAsync.when(
        data: (stats) {
          if (stats.stats.isEmpty) {
            return const Center(child: Text('データがありません'));
          }

          // 選択された日付のインデックスを取得
          int? selectedIndex;
          if (selectedDate != null) {
            selectedIndex =
                stats.stats.indexWhere((item) => item.date == selectedDate);
            if (selectedIndex == -1) selectedIndex = null;
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
                    getDotPainter: (spot, percent, barData, index) {
                      final isSelected = selectedIndex == index;
                      return FlDotCirclePainter(
                        radius: isSelected ? 8 : 6,
                        color: isSelected
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.primary,
                        strokeWidth: 2,
                        strokeColor: Theme.of(context).colorScheme.surface,
                      );
                    },
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
                touchCallback:
                    (FlTouchEvent event, LineTouchResponse? response) {
                  if (event is FlTapUpEvent && response != null) {
                    final spot = response.lineBarSpots?.first;
                    if (spot != null) {
                      final index = spot.x.toInt();
                      if (index >= 0 && index < stats.stats.length) {
                        final selectedStat = stats.stats[index];
                        final selectedDate = selectedStat.date;

                        AppLogger.debug(
                            '週間チャート: タッチイベント発生 - Date: $selectedDate');

                        // 新しい状態管理を使用してレポートを更新
                        ref
                            .read(reportUpdateNotifierProvider.notifier)
                            .updateReport('daily', selectedDate);
                      }
                    }
                  }
                },
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
    final selectedDate = ref.watch(reportDateProvider);

    return SizedBox(
      height: AppConstants.chartHeight,
      child: statsAsync.when(
        data: (stats) {
          if (stats.stats.isEmpty) {
            return const Center(child: Text('データがありません'));
          }

          // 選択された週のインデックスを取得
          int? selectedIndex;
          if (selectedDate != null && selectedDate.contains(' - ')) {
            selectedIndex = stats.stats.indexWhere((item) =>
                '${item.startDate} - ${item.endDate}' == selectedDate);
            if (selectedIndex == -1) selectedIndex = null;
          } else if (selectedDate != null && !selectedDate.contains(' - ')) {
            // 日付形式（YYYY-MM-DD）の場合、その日付を含む週を検索
            final targetDate = DateTime.tryParse(selectedDate);
            if (targetDate != null) {
              final currentWeekIndex = stats.stats.indexWhere((item) {
                final startDate = DateTime.tryParse(item.startDate);
                final endDate = DateTime.tryParse(item.endDate);
                if (startDate != null && endDate != null) {
                  return targetDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
                         targetDate.isBefore(endDate.add(const Duration(days: 1)));
                }
                return false;
              });
              
              if (currentWeekIndex != -1) {
                selectedIndex = currentWeekIndex;
                final selectedStat = stats.stats[currentWeekIndex];
                final weekDateRange = '${selectedStat.startDate} - ${selectedStat.endDate}';
                // 適切な週の範囲に更新
                Future.microtask(() {
                  ref.read(reportDateProvider.notifier).state = weekDateRange;
                });
              }
            }
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
                final isSelected = selectedIndex == index;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: scrobbles,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary,
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
                touchCallback:
                    (FlTouchEvent event, BarTouchResponse? response) {
                  if (event is FlTapUpEvent && response != null) {
                    final spot = response.spot;
                    if (spot != null) {
                      final groupIndex = spot.touchedBarGroupIndex;
                      if (groupIndex >= 0 && groupIndex < stats.stats.length) {
                        final selectedStat = stats.stats[groupIndex];
                        // 週の範囲を日付として使用（レポート用）
                        final selectedDate =
                            '${selectedStat.startDate} - ${selectedStat.endDate}';

                        AppLogger.debug(
                            '月間チャート: タッチイベント発生 - Week ${selectedStat.weekNumber}, Date: $selectedDate');

                        // 新しい状態管理を使用してレポートを更新
                        ref
                            .read(reportUpdateNotifierProvider.notifier)
                            .updateReport('weekly', selectedDate);
                      }
                    }
                  }
                },
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
    final selectedDate = ref.watch(reportDateProvider);

    return SizedBox(
      height: AppConstants.chartHeight,
      child: statsAsync.when(
        data: (stats) {
          if (stats.stats.isEmpty) {
            return const Center(child: Text('データがありません'));
          }

          // 選択された月のインデックスを取得
          int? selectedIndex;
          if (selectedDate != null && selectedDate.contains('-')) {
            final parts = selectedDate.split('-');
            if (parts.length == 2) {
              // YYYY-MM形式
              final year = int.tryParse(parts[0]);
              final month = int.tryParse(parts[1]);
              if (year != null && month != null) {
                selectedIndex = stats.stats.indexWhere(
                    (item) => item.year == year && item.month == month);
                if (selectedIndex == -1) selectedIndex = null;
              }
            } else if (parts.length == 3) {
              // YYYY-MM-DD形式の場合、その日付を含む月を検索
              final year = int.tryParse(parts[0]);
              final month = int.tryParse(parts[1]);
              if (year != null && month != null) {
                selectedIndex = stats.stats.indexWhere(
                    (item) => item.year == year && item.month == month);
                if (selectedIndex != -1) {
                  // 適切な月形式に更新
                  final monthDateString = '${year}-${month.toString().padLeft(2, '0')}';
                  Future.microtask(() {
                    ref.read(reportDateProvider.notifier).state = monthDateString;
                  });
                }
              }
            }
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
                    getDotPainter: (spot, percent, barData, index) {
                      final isSelected = selectedIndex == index;
                      return FlDotCirclePainter(
                        radius: isSelected ? 8 : 6,
                        color: isSelected
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.tertiary,
                        strokeWidth: 2,
                        strokeColor: Theme.of(context).colorScheme.surface,
                      );
                    },
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
                touchCallback:
                    (FlTouchEvent event, LineTouchResponse? response) {
                  if (event is FlTapUpEvent && response != null) {
                    final spot = response.lineBarSpots?.first;
                    if (spot != null) {
                      final index = spot.x.toInt();
                      if (index >= 0 && index < stats.stats.length) {
                        final selectedStat = stats.stats[index];
                        // 年月の形式で日付を設定（レポート用）
                        final selectedDate =
                            '${selectedStat.year}-${selectedStat.month.toString().padLeft(2, '0')}';

                        AppLogger.debug(
                            '年間チャート: タッチイベント発生 - ${selectedStat.year}年${selectedStat.month}月, Date: $selectedDate');

                        // 新しい状態管理を使用してレポートを更新
                        ref
                            .read(reportUpdateNotifierProvider.notifier)
                            .updateReport('monthly', selectedDate);
                      }
                    }
                  }
                },
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
