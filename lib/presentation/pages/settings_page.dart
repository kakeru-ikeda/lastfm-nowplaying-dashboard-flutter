import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_providers.dart';
import '../../domain/entities/theme_settings.dart';
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // テーマモード設定
            SectionCard(
              icon: Icons.palette,
              title: 'テーマモード',
              child: _buildThemeModeSection(context, themeSettings, themeNotifier),
            ),
            const SizedBox(height: 16),
            
            // カラーテーマ設定
            SectionCard(
              icon: Icons.color_lens,
              title: 'カラーテーマ',
              child: _buildColorThemeSection(context, themeSettings, themeNotifier),
            ),
            const SizedBox(height: 16),
            
            // カスタムカラー設定（カスタムテーマ選択時のみ表示）
            if (themeSettings.colorTheme == ColorThemePreset.custom)
              SectionCard(
                icon: Icons.tune,
                title: 'カスタムカラー',
                child: _buildCustomColorSection(context, themeSettings, themeNotifier),
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
          trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.secondary) : null,
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
          trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.secondary) : null,
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
            backgroundColor: settings.customPrimaryColor ?? ColorThemePreset.custom.primaryColorValue,
            radius: 12,
          ),
          title: const Text('プライマリーカラー'),
          trailing: const Icon(Icons.edit),
          onTap: () => _showColorPicker(
            context,
            'プライマリーカラーを選択',
            settings.customPrimaryColor ?? ColorThemePreset.custom.primaryColorValue,
            (color) => notifier.updateCustomColors(primaryColor: color),
          ),
        ),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: settings.customAccentColor ?? ColorThemePreset.custom.accentColorValue,
            radius: 12,
          ),
          title: const Text('アクセントカラー'),
          trailing: const Icon(Icons.edit),
          onTap: () => _showColorPicker(
            context,
            'アクセントカラーを選択',
            settings.customAccentColor ?? ColorThemePreset.custom.accentColorValue,
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
              child: isSelected
                  ? Icon(Icons.check, color: accentColor)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}
