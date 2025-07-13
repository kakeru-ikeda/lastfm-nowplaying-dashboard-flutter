import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// レスポンシブデザインのためのユーティリティクラス
class ResponsiveHelper {
  // ブレークポイント定義（AppConstantsから取得）
  static const double mobileBreakpoint = AppConstants.mobileBreakpoint;
  static const double tabletBreakpoint = AppConstants.tabletBreakpoint;
  static const double desktopBreakpoint = AppConstants.desktopBreakpoint;
  static const double largeDesktopBreakpoint =
      AppConstants.largeDesktopBreakpoint;

  /// 現在の画面サイズがモバイルかどうかを判定
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// 現在の画面サイズがタブレットかどうかを判定
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// 現在の画面サイズがデスクトップかどうかを判定
  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < largeDesktopBreakpoint;
  }

  /// 現在の画面サイズが大型デスクトップかどうかを判定
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktopBreakpoint;
  }

  /// 画面サイズに応じた適切なパディングを返す
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return EdgeInsets.all(
          AppConstants.defaultPadding * AppConstants.mobilePaddingScale);
    } else if (isTablet(context)) {
      return EdgeInsets.all(
          AppConstants.defaultPadding * AppConstants.tabletPaddingScale);
    } else if (isDesktop(context)) {
      return EdgeInsets.all(
          AppConstants.defaultPadding * AppConstants.desktopPaddingScale);
    } else {
      return EdgeInsets.all(
          AppConstants.defaultPadding * AppConstants.largeDesktopPaddingScale);
    }
  }

  /// 画面サイズに応じた適切なスペーシングを返す
  static double getResponsiveSpacing(BuildContext context) {
    if (isMobile(context)) {
      return AppConstants.defaultPadding * AppConstants.mobilePaddingScale;
    } else if (isTablet(context)) {
      return AppConstants.defaultPadding * AppConstants.tabletPaddingScale;
    } else if (isDesktop(context)) {
      return AppConstants.defaultPadding * AppConstants.desktopPaddingScale;
    } else {
      return AppConstants.defaultPadding *
          AppConstants.largeDesktopPaddingScale;
    }
  }

  /// 画面サイズに応じた適切なカラム数を返す（グリッドレイアウト用）
  static int getResponsiveColumns(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else if (isDesktop(context)) {
      return 3;
    } else {
      return 4;
    }
  }

  /// 画面サイズに応じた適切なカードの高さを返す
  static double getResponsiveCardHeight(BuildContext context) {
    if (isMobile(context)) {
      return AppConstants.mobileCardHeight;
    } else if (isTablet(context)) {
      return AppConstants.tabletCardHeight;
    } else if (isDesktop(context)) {
      return AppConstants.desktopCardHeight;
    } else {
      return AppConstants.largeDesktopCardHeight;
    }
  }

  /// NowPlayingCard用の画面サイズに応じた適切なカードの高さを返す（より余裕を持たせる）
  static double getNowPlayingCardHeight(BuildContext context) {
    if (isMobile(context)) {
      // モバイルでは縦向きレイアウト: ジャケット200px + テキスト + スペースで十分な高さ
      return 350.0;
    } else if (isTablet(context)) {
      return AppConstants.tabletCardHeight + 30.0; // +30px の余裕
    } else if (isDesktop(context)) {
      return AppConstants.desktopCardHeight + 20.0; // +20px の余裕
    } else {
      return AppConstants.largeDesktopCardHeight + 10.0; // +10px の余裕
    }
  }

  /// UserStatsCard用の画面サイズに応じた適切なカードの高さを返す（モバイルで余裕を持たせる）
  static double getUserStatsCardHeight(BuildContext context) {
    if (isMobile(context)) {
      return AppConstants.mobileCardHeight + 20.0; // +20px の余裕
    } else if (isTablet(context)) {
      return AppConstants.tabletCardHeight;
    } else if (isDesktop(context)) {
      return AppConstants.desktopCardHeight;
    } else {
      return AppConstants.largeDesktopCardHeight;
    }
  }

  /// 画面サイズに応じた適切なフォントサイズスケールを返す
  static double getResponsiveFontScale(BuildContext context) {
    if (isMobile(context)) {
      return 0.9;
    } else if (isTablet(context)) {
      return 1.0;
    } else if (isDesktop(context)) {
      return 1.1;
    } else {
      return 1.2;
    }
  }

  /// レスポンシブなレイアウトビルダー
  static Widget responsiveLayout({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
    Widget? largeDesktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else {
      return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }

  /// レスポンシブなビルダー関数
  static T responsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else {
      return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
}
