import 'package:freezed_annotation/freezed_annotation.dart';

part 'recent_track_info.freezed.dart';
part 'recent_track_info.g.dart';

@freezed
class RecentTrackInfo with _$RecentTrackInfo {
  const factory RecentTrackInfo({
    required String artist,
    required String track,
    @Default('') String album,
    @Default('') String imageUrl,
    required bool isPlaying,
    DateTime? playedAt,
    @Default('') String url,
  }) = _RecentTrackInfo;

  factory RecentTrackInfo.fromJson(Map<String, dynamic> json) =>
      _$RecentTrackInfoFromJson(json);
}

@freezed
class RecentTracksResponse with _$RecentTracksResponse {
  const factory RecentTracksResponse({
    required List<RecentTrackInfo> tracks,
    required Pagination pagination,
    Period? period,
  }) = _RecentTracksResponse;

  factory RecentTracksResponse.fromJson(Map<String, dynamic> json) =>
      _$RecentTracksResponseFromJson(json);
}

@freezed
class Pagination with _$Pagination {
  const factory Pagination({
    required int page,
    required int limit,
    required int total,
  }) = _Pagination;

  factory Pagination.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);
}

@freezed
class Period with _$Period {
  const factory Period({DateTime? from, DateTime? to}) = _Period;

  factory Period.fromJson(Map<String, dynamic> json) => _$PeriodFromJson(json);
}
