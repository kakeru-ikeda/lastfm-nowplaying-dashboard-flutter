import 'package:freezed_annotation/freezed_annotation.dart';

part 'music_report.freezed.dart';
part 'music_report.g.dart';

@freezed
class MusicReport with _$MusicReport {
  const factory MusicReport({
    required String period,
    required List<TopTrack> topTracks,
    required List<TopArtist> topArtists,
    required List<TopAlbum> topAlbums,
    required String username,
    required DateRange dateRange,
    required List<ListeningTrendData> listeningTrends,
  }) = _MusicReport;

  factory MusicReport.fromJson(Map<String, dynamic> json) =>
      _$MusicReportFromJson(json);
}

@freezed
class TopTrack with _$TopTrack {
  const factory TopTrack({
    required String name,
    required TrackArtist artist,
    required String playcount,
    required List<TrackImage> image,
    String? url,
    String? duration,
    Map<String, dynamic>? attr,
  }) = _TopTrack;

  factory TopTrack.fromJson(Map<String, dynamic> json) =>
      _$TopTrackFromJson(json);
}

@freezed
class TrackArtist with _$TrackArtist {
  const factory TrackArtist({required String name, String? url, String? mbid}) =
      _TrackArtist;

  factory TrackArtist.fromJson(Map<String, dynamic> json) =>
      _$TrackArtistFromJson(json);
}

@freezed
class TrackImage with _$TrackImage {
  const factory TrackImage({required String text, required String size}) =
      _TrackImage;

  factory TrackImage.fromJson(Map<String, dynamic> json) =>
      _$TrackImageFromJson({'text': json['#text'], 'size': json['size']});
}

@freezed
class TopArtist with _$TopArtist {
  const factory TopArtist({
    required String name,
    required String playcount,
    required List<TrackImage> image,
    String? url,
    String? mbid,
    Map<String, dynamic>? attr,
  }) = _TopArtist;

  factory TopArtist.fromJson(Map<String, dynamic> json) =>
      _$TopArtistFromJson(json);
}

@freezed
class TopAlbum with _$TopAlbum {
  const factory TopAlbum({
    required String name,
    required TrackArtist artist,
    required String playcount,
    required List<TrackImage> image,
    String? url,
    String? mbid,
    Map<String, dynamic>? attr,
  }) = _TopAlbum;

  factory TopAlbum.fromJson(Map<String, dynamic> json) =>
      _$TopAlbumFromJson(json);
}

@freezed
class DateRange with _$DateRange {
  const factory DateRange({required String start, required String end}) =
      _DateRange;

  factory DateRange.fromJson(Map<String, dynamic> json) =>
      _$DateRangeFromJson(json);
}

@freezed
class ListeningTrendData with _$ListeningTrendData {
  const factory ListeningTrendData({
    required String date,
    required int scrobbles,
    required String label,
  }) = _ListeningTrendData;

  factory ListeningTrendData.fromJson(Map<String, dynamic> json) =>
      _$ListeningTrendDataFromJson(json);
}
