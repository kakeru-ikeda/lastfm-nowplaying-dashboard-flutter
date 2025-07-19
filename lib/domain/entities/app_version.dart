import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_version.freezed.dart';
part 'app_version.g.dart';

@freezed
class AppVersion with _$AppVersion {
  const factory AppVersion({
    required String version,
    required String buildNumber,
    required String fullVersion,
    required String buildTime,
    required String timestamp,
  }) = _AppVersion;

  factory AppVersion.fromJson(Map<String, dynamic> json) =>
      _$AppVersionFromJson(json);

  // デフォルトバージョン（ローカルビルド用）
  factory AppVersion.defaultVersion() => AppVersion(
        version: '1.0.0',
        buildNumber: '1',
        fullVersion: '1.0.0+1',
        buildTime: 'ローカルビルド',
        timestamp: DateTime.now().toIso8601String(),
      );
}
