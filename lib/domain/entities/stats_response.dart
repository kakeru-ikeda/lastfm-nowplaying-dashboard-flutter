import 'package:freezed_annotation/freezed_annotation.dart';

part 'stats_response.freezed.dart';
part 'stats_response.g.dart';

@freezed
class WeekDailyStatsResponse with _$WeekDailyStatsResponse {
  const factory WeekDailyStatsResponse({
    required List<DailyStatsItem> stats,
    required StatsMeta meta,
  }) = _WeekDailyStatsResponse;

  factory WeekDailyStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$WeekDailyStatsResponseFromJson(json);
}

@freezed
class MonthWeeklyStatsResponse with _$MonthWeeklyStatsResponse {
  const factory MonthWeeklyStatsResponse({
    required List<WeeklyStatsItem> stats,
    required StatsMeta meta,
  }) = _MonthWeeklyStatsResponse;

  factory MonthWeeklyStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$MonthWeeklyStatsResponseFromJson(json);
}

@freezed
class YearMonthlyStatsResponse with _$YearMonthlyStatsResponse {
  const factory YearMonthlyStatsResponse({
    required List<MonthlyStatsItem> stats,
    required StatsMeta meta,
  }) = _YearMonthlyStatsResponse;

  factory YearMonthlyStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$YearMonthlyStatsResponseFromJson(json);
}

@freezed
class DailyStatsItem with _$DailyStatsItem {
  const factory DailyStatsItem({
    required String date,
    required int scrobbles,
    required int dayOfWeek,
    required String label,
  }) = _DailyStatsItem;

  factory DailyStatsItem.fromJson(Map<String, dynamic> json) =>
      _$DailyStatsItemFromJson(json);
}

@freezed
class WeeklyStatsItem with _$WeeklyStatsItem {
  const factory WeeklyStatsItem({
    required String startDate,
    required String endDate,
    required int scrobbles,
    required int weekNumber,
    required String label,
  }) = _WeeklyStatsItem;

  factory WeeklyStatsItem.fromJson(Map<String, dynamic> json) =>
      _$WeeklyStatsItemFromJson(json);
}

@freezed
class MonthlyStatsItem with _$MonthlyStatsItem {
  const factory MonthlyStatsItem({
    required int year,
    required int month,
    required int scrobbles,
    required String startDate,
    required String endDate,
    required String label,
  }) = _MonthlyStatsItem;

  factory MonthlyStatsItem.fromJson(Map<String, dynamic> json) =>
      _$MonthlyStatsItemFromJson(json);
}

@freezed
class StatsMeta with _$StatsMeta {
  const factory StatsMeta({
    required int total,
    required String period,
    String? referenceDate,
    int? month,
    int? year,
    String? label,
  }) = _StatsMeta;

  factory StatsMeta.fromJson(Map<String, dynamic> json) =>
      _$StatsMetaFromJson(json);
}
