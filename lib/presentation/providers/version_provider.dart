import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/helpers.dart';
import '../../domain/entities/app_version.dart';

final versionServiceProvider = Provider<VersionService>((ref) {
  return VersionService();
});

// アプリバージョンプロバイダー
final appVersionProvider = FutureProvider<AppVersion>((ref) async {
  final service = ref.read(versionServiceProvider);
  return await service.getCurrentVersion();
});

class VersionService {
  static const String _versionAssetPath = 'assets/version.json';

  /// 現在のアプリバージョンを取得
  Future<AppVersion> getCurrentVersion() async {
    try {
      // まずはアセットから読み込み試行
      final versionJson = await _loadVersionFromAssets();
      if (versionJson != null) {
        return AppVersion.fromJson(versionJson);
      }

      // アセットファイルが見つからない場合はデフォルトバージョンを返す
      AppLogger.warning('Version file not found, using default version');
      return AppVersion.defaultVersion();
    } catch (e) {
      AppLogger.error('Failed to load version info', e);
      return AppVersion.defaultVersion();
    }
  }

  /// バージョン情報をアセットから読み込み
  Future<Map<String, dynamic>?> _loadVersionFromAssets() async {
    try {
      final versionString = await rootBundle.loadString(_versionAssetPath);
      return json.decode(versionString) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.debug('Version asset not found: $_versionAssetPath');
      return null;
    }
  }

  /// サーバーから最新バージョン情報を取得
  Future<AppVersion?> getLatestVersionFromServer() async {
    try {
      final currentOrigin = html.window.location.origin;
      final versionUrl = '$currentOrigin/api/version';

      final response = await http.get(
        Uri.parse(versionUrl),
        headers: {'Cache-Control': 'no-cache'},
      );

      if (response.statusCode == 200) {
        final versionData = json.decode(response.body) as Map<String, dynamic>;
        return AppVersion.fromJson(versionData);
      }

      AppLogger.warning(
          'Failed to fetch version from server: ${response.statusCode}');
      return null;
    } catch (e) {
      AppLogger.error('Failed to fetch latest version from server', e);
      return null;
    }
  }

  /// Webアプリケーションの更新チェック
  Future<bool> checkForUpdates() async {
    try {
      final currentVersion = await getCurrentVersion();

      // サーバーから最新のバージョン情報を取得
      final latestVersion = await getLatestVersionFromServer();
      if (latestVersion == null) {
        return false;
      }

      // ビルド番号を比較
      final currentBuildNumber = int.tryParse(currentVersion.buildNumber) ?? 0;
      final latestBuildNumber = int.tryParse(latestVersion.buildNumber) ?? 0;

      AppLogger.info(
          'Version check: current=${currentVersion.fullVersion}, latest=${latestVersion.fullVersion}');

      return latestBuildNumber > currentBuildNumber;
    } catch (e) {
      AppLogger.error('Failed to check for updates', e);
      return false;
    }
  }

  /// Webアプリケーションの更新を実行
  Future<void> updateApplication() async {
    try {
      AppLogger.info('Starting application update process...');

      // 1. Service Workerがある場合は登録解除（同期的に待つ）
      await _unregisterServiceWorkersAsync();

      // 3. 少し待ってからリロード実行
      await Future.delayed(const Duration(milliseconds: 1000));

      _performForceReload();
    } catch (e) {
      AppLogger.error('Failed to update application', e);
      // フォールバック: 通常のリロード
      _performForceReload();
    }
  }

  /// 強制リロードを実行
  void _performForceReload() {
    try {
      // 方法1: location.href を使用して完全な再読み込み
      final currentUrl = html.window.location.href;

      // キャッシュバスティングパラメータを追加
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final separator = currentUrl.contains('?') ? '&' : '?';
      final newUrl = '$currentUrl${separator}_cb=$timestamp';

      AppLogger.info('Force reloading with cache busting: $newUrl');

      // location.href で完全な新しいページ読み込み
      html.window.location.href = newUrl;
    } catch (e1) {
      try {
        AppLogger.warning('location.href failed, trying location.replace: $e1');

        // 方法2: location.replace を使用
        final currentUrl = html.window.location.href;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final separator = currentUrl.contains('?') ? '&' : '?';
        final newUrl = '$currentUrl${separator}_cb=$timestamp';

        html.window.location.replace(newUrl);
      } catch (e2) {
        try {
          AppLogger.warning('location.replace failed, trying hard reload: $e2');

          // 方法3: location.reload(true) 強制リロード
          html.window.location.reload();
        } catch (e3) {
          AppLogger.error('All reload methods failed: $e3');

          // 最後の手段: ページ全体を置き換え
          try {
            html.document.body?.setInnerHtml('''
              <div style="text-align: center; margin-top: 50px;">
                <h2>アプリケーションを更新中...</h2>
                <p>しばらくお待ちください。自動的にリダイレクトされます。</p>
                <p><a href="${html.window.location.origin}">こちらをクリック</a>して手動でリロードしてください。</p>
              </div>
            ''');

            // JavaScriptで強制リダイレクト
            Future.delayed(const Duration(seconds: 2), () {
              html.window.location.assign(html.window.location.origin);
            });
          } catch (e4) {
            AppLogger.error('Final fallback failed: $e4');
          }
        }
      }
    }
  }

  /// Service Workerの登録を解除（非同期版）
  Future<void> _unregisterServiceWorkersAsync() async {
    try {
      // Service Worker APIが利用可能かチェック
      if (html.window.navigator.serviceWorker != null) {
        final registrations =
            await html.window.navigator.serviceWorker!.getRegistrations();

        for (final registration in registrations) {
          try {
            final success = await registration.unregister();
            if (success) {
              AppLogger.info('Service Worker unregistered successfully');
            }
          } catch (error) {
            AppLogger.warning('Failed to unregister Service Worker: $error');
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Service Worker unregistration failed: $e');
    }
  }

  /// フォーマットされたバージョン文字列を取得
  String formatVersion(AppVersion version) {
    return 'v${version.version} (${version.buildNumber})';
  }

  /// フォーマットされたビルド時刻を取得
  String formatBuildTime(AppVersion version) {
    try {
      final buildTime = DateTime.parse(version.timestamp);
      return '${buildTime.year}年${buildTime.month}月${buildTime.day}日 ${buildTime.hour.toString().padLeft(2, '0')}:${buildTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return version.buildTime;
    }
  }
}
