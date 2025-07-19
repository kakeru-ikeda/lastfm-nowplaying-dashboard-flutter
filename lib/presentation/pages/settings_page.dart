import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;
import '../providers/theme_providers.dart';
import '../providers/version_provider.dart';
import '../../domain/entities/theme_settings.dart';
import '../../core/utils/responsive_helper.dart';
import '../widgets/section_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeSettingsNotifierProvider);
    final themeNotifier = ref.read(themeSettingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          children: [
            // テーマモード設定
            SectionCard(
              icon: Icons.palette,
              title: 'テーマモード',
              child:
                  _buildThemeModeSection(context, themeSettings, themeNotifier),
            ),
            const SizedBox(height: 16),

            // カラーテーマ設定
            SectionCard(
              icon: Icons.color_lens,
              title: 'カラーテーマ',
              child: _buildColorThemeSection(
                  context, themeSettings, themeNotifier),
            ),
            const SizedBox(height: 16),

            // カスタムカラー設定（カスタムテーマ選択時のみ表示）
            if (themeSettings.colorTheme == ColorThemePreset.custom)
              SectionCard(
                icon: Icons.tune,
                title: 'カスタムカラー',
                child: _buildCustomColorSection(
                    context, themeSettings, themeNotifier),
              ),

            const SizedBox(height: 32),

            // アプリケーション情報セクション
            SectionCard(
              icon: Icons.info_outline,
              title: 'アプリケーション情報',
              child: _buildVersionSection(context, ref),
            ),

            const SizedBox(height: 32),

            // リセットボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showResetDialog(context, themeNotifier),
                icon: const Icon(Icons.restore),
                label: const Text('デフォルトに戻す'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeSection(
    BuildContext context,
    ThemeSettings settings,
    ThemeSettingsNotifier notifier,
  ) {
    return Column(
      children: ThemeMode.values.map((mode) {
        final isSelected = settings.themeMode == mode;
        return ListTile(
          leading: Icon(_getThemeModeIcon(mode)),
          title: Text(_getThemeModeLabel(mode)),
          trailing: isSelected
              ? Icon(Icons.check,
                  color: Theme.of(context).colorScheme.secondary)
              : null,
          onTap: () => notifier.updateThemeMode(mode),
          selected: isSelected,
        );
      }).toList(),
    );
  }

  Widget _buildColorThemeSection(
    BuildContext context,
    ThemeSettings settings,
    ThemeSettingsNotifier notifier,
  ) {
    return Column(
      children: ColorThemePreset.values.map((preset) {
        final isSelected = settings.colorTheme == preset;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: preset.primaryColorValue,
            radius: 12,
          ),
          title: Text(preset.displayName),
          trailing: isSelected
              ? Icon(Icons.check,
                  color: Theme.of(context).colorScheme.secondary)
              : null,
          onTap: () => notifier.updateColorTheme(preset),
          selected: isSelected,
        );
      }).toList(),
    );
  }

  Widget _buildCustomColorSection(
    BuildContext context,
    ThemeSettings settings,
    ThemeSettingsNotifier notifier,
  ) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: settings.customPrimaryColor ??
                ColorThemePreset.custom.primaryColorValue,
            radius: 12,
          ),
          title: const Text('プライマリーカラー'),
          trailing: const Icon(Icons.edit),
          onTap: () => _showColorPicker(
            context,
            'プライマリーカラーを選択',
            settings.customPrimaryColor ??
                ColorThemePreset.custom.primaryColorValue,
            (color) => notifier.updateCustomColors(primaryColor: color),
          ),
        ),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: settings.customAccentColor ??
                ColorThemePreset.custom.accentColorValue,
            radius: 12,
          ),
          title: const Text('アクセントカラー'),
          trailing: const Icon(Icons.edit),
          onTap: () => _showColorPicker(
            context,
            'アクセントカラーを選択',
            settings.customAccentColor ??
                ColorThemePreset.custom.accentColorValue,
            (color) => notifier.updateCustomColors(accentColor: color),
          ),
        ),
      ],
    );
  }

  void _showColorPicker(
    BuildContext context,
    String title,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ColorPicker(
            currentColor: currentColor,
            onColorChanged: onColorChanged,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('完了'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, ThemeSettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定をリセット'),
        content: const Text('すべての設定をデフォルトに戻しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              notifier.resetToDefaults();
              Navigator.of(context).pop();
            },
            child: const Text('リセット'),
          ),
        ],
      ),
    );
  }

  IconData _getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.auto_mode;
    }
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'ライト';
      case ThemeMode.dark:
        return 'ダーク';
      case ThemeMode.system:
        return 'システム';
    }
  }

  Widget _buildVersionSection(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(appVersionProvider);
    final versionService = ref.read(versionServiceProvider);

    return versionAsync.when(
      loading: () => const Column(
        children: [
          ListTile(
            leading: CircularProgressIndicator(),
            title: Text('バージョン情報を読み込み中...'),
          ),
        ],
      ),
      error: (error, stack) => Column(
        children: [
          ListTile(
            leading: Icon(Icons.error_outline, color: Colors.red),
            title: Text('バージョン情報の取得に失敗'),
            subtitle: Text('エラー: $error'),
          ),
        ],
      ),
      data: (version) => Column(
        children: [
          ListTile(
            leading: const Icon(Icons.tag),
            title: const Text('バージョン'),
            subtitle: Text(versionService.formatVersion(version)),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('ビルド日時'),
            subtitle: Text(versionService.formatBuildTime(version)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('アップデートを確認'),
            subtitle: const Text('最新バージョンがあるかチェックします'),
            onTap: () => _checkForUpdates(context, ref),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  void _checkForUpdates(BuildContext context, WidgetRef ref) async {
    final versionService = ref.read(versionServiceProvider);

    // ローディングダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('更新を確認中...'),
          ],
        ),
      ),
    );

    try {
      final hasUpdates = await versionService.checkForUpdates();

      if (context.mounted) {
        Navigator.of(context).pop(); // ローディングダイアログを閉じる

        if (hasUpdates) {
          _showUpdateDialog(context, versionService);
        } else {
          _showNoUpdateDialog(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // ローディングダイアログを閉じる
        _showUpdateErrorDialog(context);
      }
    }
  }

  void _showUpdateDialog(BuildContext context, VersionService versionService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アップデートが利用可能'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('新しいバージョンが利用可能です。'),
            SizedBox(height: 8),
            Text(
              '更新によりページが再読み込みされます。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('後で'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _performUpdate(context, versionService);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('今すぐ更新'),
          ),
        ],
      ),
    );
  }

  void _performUpdate(
      BuildContext context, VersionService versionService) async {
    // 更新処理中のダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('アプリケーションを更新中...'),
            const SizedBox(height: 8),
            Text(
              'キャッシュをクリアしています',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // 非同期で更新処理を実行
      await versionService.updateApplication();
    } catch (e) {
      // エラーが発生した場合でもリロードを試行
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('更新処理中にエラーが発生しましたが、リロードを実行します'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // フォールバック: 直接リロード
      Future.delayed(const Duration(milliseconds: 1000), () {
        html.window.location.reload();
      });
    }
  }

  void _showNoUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('最新バージョンです'),
        content: const Text('お使いのアプリケーションは最新バージョンです。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showUpdateErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('更新確認エラー'),
        content: const Text('アップデートの確認中にエラーが発生しました。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class ColorPicker extends StatelessWidget {
  const ColorPicker({
    super.key,
    required this.currentColor,
    required this.onColorChanged,
  });

  final Color currentColor;
  final Function(Color) onColorChanged;

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.secondary;

    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
    ];

    return SizedBox(
      width: double.maxFinite,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: colors.map((color) {
          final isSelected = color.value == currentColor.value;
          return GestureDetector(
            onTap: () => onColorChanged(color),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: accentColor, width: 3)
                    : null,
              ),
              child: isSelected ? Icon(Icons.check, color: accentColor) : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}
