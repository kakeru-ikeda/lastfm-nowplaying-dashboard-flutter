import 'dart:convert';
import 'package:flutter/material.dart';
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

class ColorHelper {
  /// 背景色とのコントラストを考慮して最適なアイコンカラーを返す
  ///
  /// [backgroundColor] - 背景色
  /// [primaryColor] - テーマのプライマリカラー
  /// [onSurfaceColor] - テーマのonSurfaceカラー（通常のテキスト色）
  ///
  /// 返り値：背景色とのコントラストが十分な場合はprimaryColor、
  /// そうでない場合は明度に応じて白または黒を返す
  static Color getContrastIconColor(
    Color backgroundColor,
    Color primaryColor,
    Color onSurfaceColor,
  ) {
    // プライマリカラーと背景色のコントラストをチェック
    final primaryContrast = _calculateContrast(backgroundColor, primaryColor);

    // コントラスト比が3.0以上なら十分読みやすい
    if (primaryContrast >= 3.0) {
      return primaryColor;
    }

    // プライマリカラーのコントラストが不十分な場合、
    // onSurfaceColorを使用（これは通常、テーマに適した色）
    return onSurfaceColor;
  }

  /// 2つの色のコントラスト比を計算
  static double _calculateContrast(Color color1, Color color2) {
    final luminance1 = _getLuminance(color1);
    final luminance2 = _getLuminance(color2);

    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// 色の相対輝度を計算
  static double _getLuminance(Color color) {
    final r = _linearizeColorComponent(color.red / 255.0);
    final g = _linearizeColorComponent(color.green / 255.0);
    final b = _linearizeColorComponent(color.blue / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// 色成分を線形化
  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    } else {
      return ((component + 0.055) / 1.055) * ((component + 0.055) / 1.055);
    }
  }

  /// 背景色の明度を判定してテキストカラーを決定
  static Color getContrastTextColor(Color backgroundColor) {
    final luminance = _getLuminance(backgroundColor);
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}
