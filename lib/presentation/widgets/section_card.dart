import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// 共通のセクションカードレイアウトコンポーネント
/// 
/// 一貫したパディング、カードスタイル、タイトル表示を提供します
class SectionCard extends StatelessWidget {
  /// カードのタイトルに表示するアイコン
  final IconData icon;
  
  /// アイコンの色
  final Color iconColor;
  
  /// セクションのタイトル
  final String title;
  
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
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.trailing,
    this.height,
    this.padding,
    this.titleSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(AppConstants.defaultPadding);
    final effectiveTitleSpacing = titleSpacing ?? AppConstants.defaultPadding;
    
    Widget cardContent = Padding(
      padding: effectivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトル行
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
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
