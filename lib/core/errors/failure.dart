import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure.network({required String message, int? statusCode}) =
      NetworkFailure;

  const factory Failure.server({required String message, int? statusCode}) =
      ServerFailure;

  const factory Failure.cache({required String message}) = CacheFailure;

  const factory Failure.validation({required String message}) =
      ValidationFailure;

  const factory Failure.websocket({required String message}) = WebSocketFailure;

  const factory Failure.unknown({required String message}) = UnknownFailure;
}
