import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// タイトル無しの共通カードレイアウトコンポーネント
/// 
/// 一貫したパディングとカードスタイルのみを提供します
class SimpleCard extends StatelessWidget {
  /// カードの内容となるウィジェット
  final Widget child;
  
  /// カードの高さ（オプション）
  final double? height;
  
  /// カスタムパディング（デフォルトはAppConstants.defaultPadding）
  final EdgeInsetsGeometry? padding;
  
  const SimpleCard({
    super.key,
    required this.child,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(AppConstants.defaultPadding);
    
    Widget cardContent = Padding(
      padding: effectivePadding,
      child: child,
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
