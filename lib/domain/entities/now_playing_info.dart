import 'package:freezed_annotation/freezed_annotation.dart';

part 'now_playing_info.freezed.dart';
part 'now_playing_info.g.dart';

@freezed
class NowPlayingInfo with _$NowPlayingInfo {
  const factory NowPlayingInfo({
    String? artist,
    String? track,
    String? album,
    String? imageUrl,
    @Default(false) bool isPlaying,
  }) = _NowPlayingInfo;

  factory NowPlayingInfo.fromJson(Map<String, dynamic> json) =>
      _$NowPlayingInfoFromJson(json);
}
