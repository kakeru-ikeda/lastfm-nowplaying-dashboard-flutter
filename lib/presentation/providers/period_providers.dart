import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/period_calculator.dart';
import '../../domain/entities/stats_response.dart';
import '../../core/utils/helpers.dart';
import 'music_providers.dart';

/// 期間状態管理プロバイダー
final weeklyPeriodProvider = StateProvider<PeriodRange>((ref) {
  return PeriodCalculator.getCurrentWeek();
});

final monthlyPeriodProvider = StateProvider<PeriodRange>((ref) {
  return PeriodCalculator.getCurrentMonth();
});

final yearlyPeriodProvider = StateProvider<PeriodRange>((ref) {
  return PeriodCalculator.getCurrentYear();
});

/// 期間指定統計データ取得プロバイダー
final periodWeekDailyStatsProvider =
    FutureProvider.family<WeekDailyStatsResponse, PeriodRange>(
        (ref, period) async {
  final repository = ref.watch(musicRepositoryProvider);
  final result = await repository.getWeekDailyStats(
    from: period.from,
    to: period.to,
  );

  return result.fold(
    (failure) {
      AppLogger.error(
          'Failed to get week daily stats for period: ${failure.message}');
      throw Exception(failure.message);
    },
    (stats) {
      AppLogger.debug('Week daily stats loaded for period: ${period.label}');
      return stats;
    },
  );
});

final periodMonthWeeklyStatsProvider =
    FutureProvider.family<MonthWeeklyStatsResponse, PeriodRange>(
        (ref, period) async {
  final repository = ref.watch(musicRepositoryProvider);
  final result = await repository.getMonthWeeklyStats(
    from: period.from,
    to: period.to,
  );

  return result.fold(
    (failure) {
      AppLogger.error(
          'Failed to get month weekly stats for period: ${failure.message}');
      throw Exception(failure.message);
    },
    (stats) {
      AppLogger.debug('Month weekly stats loaded for period: ${period.label}');
      return stats;
    },
  );
});

final periodYearMonthlyStatsProvider =
    FutureProvider.family<YearMonthlyStatsResponse, PeriodRange>(
        (ref, period) async {
  final repository = ref.watch(musicRepositoryProvider);
  final result = await repository.getYearMonthlyStats(
    from: period.from,
    to: period.to,
  );

  return result.fold(
    (failure) {
      AppLogger.error(
          'Failed to get year monthly stats for period: ${failure.message}');
      throw Exception(failure.message);
    },
    (stats) {
      AppLogger.debug('Year monthly stats loaded for period: ${period.label}');
      return stats;
    },
  );
});

/// 期間ナビゲーション用のヘルパー関数
class PeriodNavigationHelper {
  /// 前の期間に移動
  static void moveToPrevious(WidgetRef ref, PeriodType type) {
    switch (type) {
      case PeriodType.weekly:
        final currentPeriod = ref.read(weeklyPeriodProvider);
        final previousPeriod = PeriodCalculator.getPreviousWeek(currentPeriod);
        ref.read(weeklyPeriodProvider.notifier).state = previousPeriod;
        break;
      case PeriodType.monthly:
        final currentPeriod = ref.read(monthlyPeriodProvider);
        final previousPeriod = PeriodCalculator.getPreviousMonth(currentPeriod);
        ref.read(monthlyPeriodProvider.notifier).state = previousPeriod;
        break;
      case PeriodType.yearly:
        final currentPeriod = ref.read(yearlyPeriodProvider);
        final previousPeriod = PeriodCalculator.getPreviousYear(currentPeriod);
        ref.read(yearlyPeriodProvider.notifier).state = previousPeriod;
        break;
    }
  }

  /// 次の期間に移動
  static void moveToNext(WidgetRef ref, PeriodType type) {
    switch (type) {
      case PeriodType.weekly:
        final currentPeriod = ref.read(weeklyPeriodProvider);
        final nextPeriod = PeriodCalculator.getNextWeek(currentPeriod);
        // 未来の期間には移動しない
        if (!PeriodCalculator.isInFuture(nextPeriod)) {
          ref.read(weeklyPeriodProvider.notifier).state = nextPeriod;
        }
        break;
      case PeriodType.monthly:
        final currentPeriod = ref.read(monthlyPeriodProvider);
        final nextPeriod = PeriodCalculator.getNextMonth(currentPeriod);
        // 未来の期間には移動しない
        if (!PeriodCalculator.isInFuture(nextPeriod)) {
          ref.read(monthlyPeriodProvider.notifier).state = nextPeriod;
        }
        break;
      case PeriodType.yearly:
        final currentPeriod = ref.read(yearlyPeriodProvider);
        final nextPeriod = PeriodCalculator.getNextYear(currentPeriod);
        // 未来の期間には移動しない
        if (!PeriodCalculator.isInFuture(nextPeriod)) {
          ref.read(yearlyPeriodProvider.notifier).state = nextPeriod;
        }
        break;
    }
  }

  /// 現在の期間に戻る
  static void moveToPresent(WidgetRef ref, PeriodType type) {
    switch (type) {
      case PeriodType.weekly:
        ref.read(weeklyPeriodProvider.notifier).state =
            PeriodCalculator.getCurrentWeek();
        break;
      case PeriodType.monthly:
        ref.read(monthlyPeriodProvider.notifier).state =
            PeriodCalculator.getCurrentMonth();
        break;
      case PeriodType.yearly:
        ref.read(yearlyPeriodProvider.notifier).state =
            PeriodCalculator.getCurrentYear();
        break;
    }
  }

  /// 次の期間に移動できるかチェック
  static bool canMoveToNext(WidgetRef ref, PeriodType type) {
    switch (type) {
      case PeriodType.weekly:
        final currentPeriod = ref.read(weeklyPeriodProvider);
        final nextPeriod = PeriodCalculator.getNextWeek(currentPeriod);
        return !PeriodCalculator.isInFuture(nextPeriod);
      case PeriodType.monthly:
        final currentPeriod = ref.read(monthlyPeriodProvider);
        final nextPeriod = PeriodCalculator.getNextMonth(currentPeriod);
        return !PeriodCalculator.isInFuture(nextPeriod);
      case PeriodType.yearly:
        final currentPeriod = ref.read(yearlyPeriodProvider);
        final nextPeriod = PeriodCalculator.getNextYear(currentPeriod);
        return !PeriodCalculator.isInFuture(nextPeriod);
    }
  }
}
