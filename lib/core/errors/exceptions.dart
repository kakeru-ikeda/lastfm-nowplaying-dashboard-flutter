abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.statusCode});
}

class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode});
}

class CacheException extends AppException {
  const CacheException(super.message);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class WebSocketException extends AppException {
  const WebSocketException(super.message);
}
