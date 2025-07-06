import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';

/// 共通のセクションカードレイアウトコンポーネント
/// 
/// 一貫したパディング、カードスタイル、タイトル表示を提供します
class SectionCard extends StatelessWidget {
  /// カードのタイトルに表示するアイコン（オプション）
  final IconData? icon;
  
  /// セクションのタイトル（オプション）
  final String? title;
  
  /// タイトル行の右側に表示するウィジェット（オプション）
  final Widget? trailing;
  
  /// カードの内容となるウィジェット
  final Widget child;
  
  /// カードの高さ（オプション）
  final double? height;
  
  /// カスタムパディング（デフォルトはAppConstants.defaultPadding）
  final EdgeInsetsGeometry? padding;
  
  /// タイトルとコンテンツ間のスペーシング（デフォルトはAppConstants.defaultPadding）
  final double? titleSpacing;
  
  const SectionCard({
    super.key,
    this.icon,
    this.title,
    required this.child,
    this.trailing,
    this.height,
    this.padding,
    this.titleSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final primaryColor = theme.colorScheme.primary;
    final onSurfaceColor = theme.colorScheme.onSurface;
    
    final effectivePadding = padding ?? const EdgeInsets.all(AppConstants.defaultPadding);
    final effectiveTitleSpacing = titleSpacing ?? AppConstants.defaultPadding;
    
    // タイトル行を表示するかどうかを判定
    final showTitle = title != null && title!.isNotEmpty;
    
    Widget cardContent = Padding(
      padding: effectivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトル行（タイトルがある場合のみ表示）
          if (showTitle) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon!,
                    color: ColorHelper.getContrastIconColor(
                      cardColor,
                      primaryColor,
                      onSurfaceColor,
                    ),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  title!,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing!,
                ],
              ],
            ),
            SizedBox(height: effectiveTitleSpacing),
          ],
          // コンテンツ
          child,
        ],
      ),
    );

    // 高さが指定されている場合はContainerでラップ
    if (height != null) {
      cardContent = SizedBox(
        height: height,
        child: cardContent,
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      elevation: 4,
      child: cardContent,
    );
  }
}
