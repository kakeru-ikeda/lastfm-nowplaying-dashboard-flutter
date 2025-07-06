import 'package:freezed_annotation/freezed_annotation.dart';

part 'recent_tracks_params.freezed.dart';
part 'recent_tracks_params.g.dart';

@freezed
class RecentTracksParams with _$RecentTracksParams {
  const factory RecentTracksParams({
    int? limit,
    int? page,
    DateTime? from,
    DateTime? to,
  }) = _RecentTracksParams;

  factory RecentTracksParams.fromJson(Map<String, dynamic> json) =>
      _$RecentTracksParamsFromJson(json);
}
