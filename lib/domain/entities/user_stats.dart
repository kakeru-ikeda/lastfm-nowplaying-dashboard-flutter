import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/utils/helpers.dart';

part 'user_stats.freezed.dart';
part 'user_stats.g.dart';

// カスタムコンバーター：UNIXタイムスタンプをISO文字列に変換
class UnixTimestampConverter implements JsonConverter<String, dynamic> {
  const UnixTimestampConverter();

  @override
  String fromJson(dynamic json) {
    if (json is int) {
      // UNIXタイムスタンプからDateTime、そしてISO文字列に変換
      return DateTime.fromMillisecondsSinceEpoch(json * 1000).toIso8601String();
    } else if (json is String) {
      // すでに文字列の場合はそのまま返す
      return json;
    } else if (json is Map && json['#text'] is String) {
      // Last.fm APIの場合、{'#text': 'timestamp'} 形式の場合がある
      final timestamp = int.tryParse(json['#text']);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toIso8601String();
      }
      return json['#text'];
    }
    return DateTime.now().toIso8601String(); // フォールバック
  }

  @override
  dynamic toJson(String object) {
    return object;
  }
}

@freezed
class UserStats with _$UserStats {
  const factory UserStats({
    required UserProfile profile,
    UserTopArtist? topArtist,
    UserTopTrack? topTrack,
    required String generatedAt,
  }) = _UserStats;

  factory UserStats.fromJson(Map<String, dynamic> json) {
    try {
      return UserStats(
        profile: UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
        topArtist: json['topArtist'] != null 
            ? UserTopArtist.fromJson(json['topArtist'] as Map<String, dynamic>)
            : null,
        topTrack: json['topTrack'] != null 
            ? UserTopTrack.fromJson(json['topTrack'] as Map<String, dynamic>)
            : null,
        generatedAt: json['generatedAt'] as String,
      );
    } catch (e) {
      AppLogger.error('UserStats.fromJson error', e);
      // フォールバック: デフォルト値を使用
      return UserStats(
        profile: UserProfile.fromJsonSafe(json['profile']),
        topArtist: null,
        topTrack: null,
        generatedAt: DateTime.now().toIso8601String(),
      );
    }
  }
}

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String username,
    String? realName,
    required String url,
    String? country,
    @UnixTimestampConverter() required String registeredDate,
    required int totalPlayCount,
    String? profileImage,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  factory UserProfile.fromJsonSafe(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        return UserProfile.fromJson(data);
      }
      // フォールバック
      return const UserProfile(
        username: 'Unknown',
        url: '',
        registeredDate: '',
        totalPlayCount: 0,
      );
    } catch (e) {
      AppLogger.error('UserProfile.fromJsonSafe error', e);
      return const UserProfile(
        username: 'Unknown',
        url: '',
        registeredDate: '',
        totalPlayCount: 0,
      );
    }
  }
}

@freezed
class UserTopArtist with _$UserTopArtist {
  const factory UserTopArtist({
    required String name,
    required int playCount,
    required String url,
    String? image,
  }) = _UserTopArtist;

  factory UserTopArtist.fromJson(Map<String, dynamic> json) =>
      _$UserTopArtistFromJson(json);
}

@freezed
class UserTopTrack with _$UserTopTrack {
  const factory UserTopTrack({
    required String name,
    required String artist,
    required int playCount,
    required String url,
    String? image,
  }) = _UserTopTrack;

  factory UserTopTrack.fromJson(Map<String, dynamic> json) =>
      _$UserTopTrackFromJson(json);
}
