import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/period_calculator.dart';
import '../../core/constants/app_constants.dart';
import '../providers/period_providers.dart';

/// 期間ナビゲーションバー
class PeriodNavigationBar extends ConsumerWidget {
  final PeriodType periodType;
  final bool isLoading;

  const PeriodNavigationBar({
    super.key,
    required this.periodType,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 期間に応じた現在の期間を取得
    final currentPeriod = _getCurrentPeriod(ref);
    final canMoveNext = PeriodNavigationHelper.canMoveToNext(ref, periodType);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.defaultPadding * 0.5,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 前の期間ボタン
          _NavigationButton(
            icon: Icons.chevron_left,
            onPressed: isLoading
                ? null
                : () => PeriodNavigationHelper.moveToPrevious(ref, periodType),
            tooltip: '前の${_getPeriodName()}',
          ),

          // 現在の期間表示
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentPeriod.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  _getPeriodDescription(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // 次の期間ボタン
          _NavigationButton(
            icon: Icons.chevron_right,
            onPressed: isLoading || !canMoveNext
                ? null
                : () => PeriodNavigationHelper.moveToNext(ref, periodType),
            tooltip: '次の${_getPeriodName()}',
          ),
        ],
      ),
    );
  }

  /// 現在の期間を取得
  PeriodRange _getCurrentPeriod(WidgetRef ref) {
    switch (periodType) {
      case PeriodType.weekly:
        return ref.watch(weeklyPeriodProvider);
      case PeriodType.monthly:
        return ref.watch(monthlyPeriodProvider);
      case PeriodType.yearly:
        return ref.watch(yearlyPeriodProvider);
    }
  }

  /// 期間名を取得
  String _getPeriodName() {
    switch (periodType) {
      case PeriodType.weekly:
        return '週';
      case PeriodType.monthly:
        return '月';
      case PeriodType.yearly:
        return '年';
    }
  }

  /// 期間説明を取得
  String _getPeriodDescription() {
    switch (periodType) {
      case PeriodType.weekly:
        return '週間統計';
      case PeriodType.monthly:
        return '月間統計';
      case PeriodType.yearly:
        return '年間統計';
    }
  }
}

/// ナビゲーションボタン
class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  const _NavigationButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 24,
              color: onPressed != null
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }
}

/// 現在の期間に戻るボタン
class PeriodResetButton extends ConsumerWidget {
  final PeriodType periodType;

  const PeriodResetButton({
    super.key,
    required this.periodType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: '現在の${_getPeriodName()}に戻る',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => PeriodNavigationHelper.moveToPresent(ref, periodType),
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.today,
              size: 20,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ),
    );
  }

  /// 期間名を取得
  String _getPeriodName() {
    switch (periodType) {
      case PeriodType.weekly:
        return '週';
      case PeriodType.monthly:
        return '月';
      case PeriodType.yearly:
        return '年';
    }
  }
}
