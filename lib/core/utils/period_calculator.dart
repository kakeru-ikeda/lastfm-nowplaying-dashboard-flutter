/// 期間タイプ
enum PeriodType {
  weekly,
  monthly,
  yearly,
}

/// 期間範囲情報
class PeriodRange {
  final DateTime from;
  final DateTime to;
  final String label;
  final PeriodType type;

  const PeriodRange({
    required this.from,
    required this.to,
    required this.label,
    required this.type,
  });

  @override
  String toString() =>
      'PeriodRange(from: $from, to: $to, label: $label, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PeriodRange &&
        other.from == from &&
        other.to == to &&
        other.label == label &&
        other.type == type;
  }

  @override
  int get hashCode =>
      from.hashCode ^ to.hashCode ^ label.hashCode ^ type.hashCode;
}

/// 期間計算用ユーティリティ
class PeriodCalculator {
  /// 現在の週間期間を取得
  static PeriodRange getCurrentWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return PeriodRange(
      from: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      to: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
      label: _formatWeekLabel(startOfWeek, endOfWeek),
      type: PeriodType.weekly,
    );
  }

  /// 指定した週間期間の前の週を取得
  static PeriodRange getPreviousWeek(PeriodRange current) {
    final newStart = current.from.subtract(const Duration(days: 7));
    final newEnd = current.to.subtract(const Duration(days: 7));

    return PeriodRange(
      from: DateTime(newStart.year, newStart.month, newStart.day),
      to: DateTime(newEnd.year, newEnd.month, newEnd.day, 23, 59, 59),
      label: _formatWeekLabel(newStart, newEnd),
      type: PeriodType.weekly,
    );
  }

  /// 指定した週間期間の次の週を取得
  static PeriodRange getNextWeek(PeriodRange current) {
    final newStart = current.from.add(const Duration(days: 7));
    final newEnd = current.to.add(const Duration(days: 7));

    return PeriodRange(
      from: DateTime(newStart.year, newStart.month, newStart.day),
      to: DateTime(newEnd.year, newEnd.month, newEnd.day, 23, 59, 59),
      label: _formatWeekLabel(newStart, newEnd),
      type: PeriodType.weekly,
    );
  }

  /// 現在の月間期間を取得
  static PeriodRange getCurrentMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return PeriodRange(
      from: startOfMonth,
      to: endOfMonth,
      label: _formatMonthLabel(startOfMonth),
      type: PeriodType.monthly,
    );
  }

  /// 指定した月間期間の前の月を取得
  static PeriodRange getPreviousMonth(PeriodRange current) {
    final startOfMonth = DateTime(current.from.year, current.from.month - 1, 1);
    final endOfMonth =
        DateTime(current.from.year, current.from.month, 0, 23, 59, 59);

    return PeriodRange(
      from: startOfMonth,
      to: endOfMonth,
      label: _formatMonthLabel(startOfMonth),
      type: PeriodType.monthly,
    );
  }

  /// 指定した月間期間の次の月を取得
  static PeriodRange getNextMonth(PeriodRange current) {
    final startOfMonth = DateTime(current.from.year, current.from.month + 1, 1);
    final endOfMonth =
        DateTime(current.from.year, current.from.month + 2, 0, 23, 59, 59);

    return PeriodRange(
      from: startOfMonth,
      to: endOfMonth,
      label: _formatMonthLabel(startOfMonth),
      type: PeriodType.monthly,
    );
  }

  /// 現在の年間期間を取得
  static PeriodRange getCurrentYear() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

    return PeriodRange(
      from: startOfYear,
      to: endOfYear,
      label: _formatYearLabel(startOfYear),
      type: PeriodType.yearly,
    );
  }

  /// 指定した年間期間の前の年を取得
  static PeriodRange getPreviousYear(PeriodRange current) {
    final startOfYear = DateTime(current.from.year - 1, 1, 1);
    final endOfYear = DateTime(current.from.year - 1, 12, 31, 23, 59, 59);

    return PeriodRange(
      from: startOfYear,
      to: endOfYear,
      label: _formatYearLabel(startOfYear),
      type: PeriodType.yearly,
    );
  }

  /// 指定した年間期間の次の年を取得
  static PeriodRange getNextYear(PeriodRange current) {
    final startOfYear = DateTime(current.from.year + 1, 1, 1);
    final endOfYear = DateTime(current.from.year + 1, 12, 31, 23, 59, 59);

    return PeriodRange(
      from: startOfYear,
      to: endOfYear,
      label: _formatYearLabel(startOfYear),
      type: PeriodType.yearly,
    );
  }

  /// 日付が現在の期間を超えているかチェック
  static bool isInFuture(PeriodRange period) {
    final now = DateTime.now();
    return period.from.isAfter(now);
  }

  /// 週間ラベルのフォーマット
  static String _formatWeekLabel(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return '${start.year}年${start.month}月${start.day}日-${end.day}日';
    } else if (start.year == end.year) {
      return '${start.year}年${start.month}月${start.day}日-${end.month}月${end.day}日';
    } else {
      return '${start.year}年${start.month}月${start.day}日-${end.year}年${end.month}月${end.day}日';
    }
  }

  /// 月間ラベルのフォーマット
  static String _formatMonthLabel(DateTime date) {
    return '${date.year}年${date.month}月';
  }

  /// 年間ラベルのフォーマット
  static String _formatYearLabel(DateTime date) {
    return '${date.year}年';
  }
}
