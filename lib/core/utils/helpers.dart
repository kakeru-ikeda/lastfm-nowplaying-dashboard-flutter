import 'dart:convert';
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  static void debug(String? message) => _logger.d(message ?? 'null');
  static void info(String? message) => _logger.i(message ?? 'null');
  static void warning(String? message) => _logger.w(message ?? 'null');
  static void error(String? message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message ?? 'null', error: error, stackTrace: stackTrace);
}

class DateTimeHelper {
  static String formatDate(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';
  }

  static String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${formatTime(dateTime)}';
  }

  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }
}

class JsonHelper {
  static Map<String, dynamic>? safeDecode(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      final decoded = json.decode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      AppLogger.error('JSON decode error', e);
      return null;
    }
  }

  static String? safeGetString(Map<String, dynamic>? json, String key) {
    if (json == null) return null;
    final value = json[key];
    return value?.toString();
  }

  static int? safeGetInt(Map<String, dynamic>? json, String key) {
    if (json == null) return null;
    final value = json[key];
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static bool? safeGetBool(Map<String, dynamic>? json, String key) {
    if (json == null) return null;
    final value = json[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return null;
  }
}
