import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_stats.freezed.dart';
part 'server_stats.g.dart';

@freezed
class ServerStats with _$ServerStats {
  const factory ServerStats({
    required int uptime,
    required int totalRequests,
    required int activeConnections,
    required int lastfmApiCalls,
    required int reportsGenerated,
    required MemoryUsage memoryUsage,
    String? lastReportTime,
  }) = _ServerStats;

  factory ServerStats.fromJson(Map<String, dynamic> json) =>
      _$ServerStatsFromJson(json);
}

@freezed
class MemoryUsage with _$MemoryUsage {
  const factory MemoryUsage({
    required int used,
    required int total,
    required int percentage,
  }) = _MemoryUsage;

  factory MemoryUsage.fromJson(Map<String, dynamic> json) =>
      _$MemoryUsageFromJson(json);
}

@freezed
class HealthCheckResponse with _$HealthCheckResponse {
  const factory HealthCheckResponse({
    String? status,
    String? timestamp,
    @Default(0) int uptime,
    String? version,
    ServiceStatus? services,
  }) = _HealthCheckResponse;

  factory HealthCheckResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthCheckResponseFromJson(json);
}

@freezed
class ServiceStatus with _$ServiceStatus {
  const factory ServiceStatus({
    @Default(false) bool lastfm,
    @Default(false) bool discord,
    @Default(false) bool websocket,
  }) = _ServiceStatus;

  factory ServiceStatus.fromJson(Map<String, dynamic> json) =>
      _$ServiceStatusFromJson(json);
}
