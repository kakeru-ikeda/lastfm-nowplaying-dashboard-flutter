# Last.fm Now Playing ダッシュボード - Flutter Web アプリケーション

レイヤードアーキテクチャとRiverpod状態管理を使用して、Last.fm APIバックエンドサーバーに接続し、現在再生中の情報と音楽レポートを視覚的コンポーネントで表示する洗練されたFlutter Webアプリケーションです。

## 🚀 機能

- **リアルタイム再生表示**: アニメーション付きLIVEインジケーター、音波効果、パルスエフェクトによる現在再生中のトラック表示
- **アニメーション機能**: スケール、オパシティ、回転アニメーションによる動的なUI体験
- **再生履歴表示**: 直近の再生履歴を時系列で表示（現在再生中は除外）
- **クリック可能なトラック情報**: トラックやアーティストをクリックしてLast.fmページを新しいタブで開く
- **音楽レポート**: 日次、週次、月次の音楽リスニング統計とインタラクティブチャート
- **サーバー統計**: リアルタイムサーバーパフォーマンス監視
- **テーマ設定**: ライト/ダーク/システムテーマ切り替え機能
- **レスポンシブデザイン**: 横向き/ランドスケープレイアウトに最適化
- **WebSocket統合**: 現在再生中情報のライブ更新と履歴の自動同期
- **設定の永続化**: SharedPreferencesによるテーマ設定とユーザー設定の保存

## 🏗️ アーキテクチャ

このプロジェクトは**Clean Architecture**の原則に従い、厳密なレイヤー分離を行っています：

```
lib/
├── presentation/          # UIレイヤー
│   ├── pages/            # 画面ウィジェット
│   ├── widgets/          # 再利用可能なUIコンポーネント
│   └── providers/        # Riverpod状態管理
├── domain/               # ビジネスロジックレイヤー
│   ├── entities/         # ビジネスオブジェクト
│   ├── repositories/     # リポジトリ契約
│   └── usecases/         # ビジネスユースケース
├── data/                 # データレイヤー
│   ├── models/           # データモデル
│   ├── repositories/     # リポジトリ実装
│   └── datasources/      # 外部データソース
└── core/                 # インフラストラクチャレイヤー
    ├── constants/        # アプリ定数
    ├── errors/           # エラーハンドリング
    └── utils/            # ユーティリティ関数
```

## 🛠️ 技術スタック

- **Flutter Web**: フロントエンドフレームワーク
- **Riverpod**: 依存性注入を備えた状態管理
- **Freezed**: イミュータブルデータクラスとユニオン型
- **FL Chart**: インタラクティブチャートとグラフ
- **HTTP & WebSocket**: API通信とリアルタイム更新
- **Google Fonts**: タイポグラフィ
- **Responsive Framework**: レスポンシブデザインユーティリティ
- **Cached Network Image**: 効率的な画像キャッシュとプレースホルダー
- **SharedPreferences**: ローカル設定の永続化
- **Animation Controllers**: スムーズなアニメーション効果

## 📡 バックエンド統合

`http://localhost:3001`で実行されているLast.fmプロキシサーバーに接続：

### APIエンドポイント
- `GET /health` - ヘルスチェック
- `GET /api/now-playing` - 現在再生中のトラック
- `GET /api/reports/{period}` - 音楽レポート（日次/週次/月次）
- `GET /api/recent-tracks` - 直近の再生履歴（パラメータ：limit、page、from、to）
- `GET /api/stats` - サーバー統計

### WebSocket接続
- `ws://localhost:3001` - リアルタイム再生情報更新と履歴同期

## 🎨 UIコンポーネント

### ダッシュボードレイアウト
- **Now Playing Card**: アニメーション付きLIVEインジケーター、音波エフェクト、スケールアニメーションを備えた現在のトラック表示
- **Recent Tracks Card**: 過去の再生履歴を時系列で表示（現在再生中は自動除外）
- **Server Stats Card**: 稼働時間、API呼び出し、接続数、メモリ使用量を表示
- **Period Selector**: 日次/週次/月次レポート間の切り替え
- **Music Report Card**: インタラクティブチャートとトップトラック/アーティストリスト
- **Settings Page**: テーマ設定（ライト/ダーク/システム）とLast.fmロゴ表示
- **Clickable Elements**: トラックとアーティスト名をクリックしてLast.fmページを新しいタブで開く

### ビジュアル要素
- 音楽アプリケーション向けに最適化されたダークテーマ
- Spotifyインスパイアのカラースキーム（グリーン: #1DB954、ダーク: #191414）
- スムーズなアニメーションとトランジション
- レスポンシブカードレイアウト

## 🚦 セットアップ

### 前提条件
- Flutter SDK (3.7.0+)
- localhost:3001で実行されているLast.fm APIバックエンドサーバー

### インストール

1. **リポジトリをクローン**
   ```bash
   git clone <repository-url>
   cd lastfm-nowplaying-dashboard-flutter
   ```

2. **依存関係をインストール**
   ```bash
   flutter pub get
   ```

3. **コードファイルを生成**（初回セットアップおよびエンティティ変更後に必要）
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **アプリケーションを実行**
   ```bash
   flutter run -d chrome
   ```

### 開発コマンド

```bash
# コード生成（Freezed、JSON、Riverpod）- エンティティ変更後に実行
dart run build_runner build --delete-conflicting-outputs

# 開発中の継続的コード生成用ウォッチモード
dart run build_runner watch

# すべてのコードファイルをクリーンして再生成
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs

# コード品質を分析
flutter analyze

# テストを実行
flutter test
```

### 重要な注意事項

- **生成ファイル**（*.g.dart、*.freezed.dart）はbuild_runnerによって自動的に作成されます
- これらのファイルは**Gitから除外**されています（.gitignore） - クローン後にコード生成を実行してください
- エンティティクラスを変更するプルリクエストの後は、必ず `dart run build_runner build` を実行してください

## 📱 レスポンシブデザイン

異なる画面サイズに最適化：
- **モバイル** (0-450px): スタックレイアウト
- **タブレット** (451-800px): アダプティブグリッド
- **デスクトップ** (801-1920px): フル横向きレイアウト
- **4K** (1921px+): 拡張スペーシング

## 🔄 状態管理

包括的な状態管理に**Riverpod**を使用：

- **Providers**: データ取得と依存性注入
- **StateProviders**: UI状態（選択された期間、テーマ設定など）
- **FutureProviders**: 非同期データ読み込み
- **StreamProviders**: WebSocketリアルタイム更新
- **ThemeProviders**: テーマ設定管理とSharedPreferences統合
- **MusicProviders**: 音楽データとWebSocket接続状態管理

## 🎯 主要機能の実装

### テーマシステム
- **SharedPreferences統合**: テーマ設定の永続化
- **システムテーマ対応**: OS設定との同期
- **動的テーマ切り替え**: ライト/ダーク/システムモード
- **Riverpod統合**: 状態管理とリアクティブな更新

### リアルタイム更新
- 現在再生中の情報をライブ更新するWebSocket接続
- WebSocketで楽曲変更時に再生履歴を自動同期
- レポートと統計の自動更新機能
- ローディング状態とエラーハンドリング
- 接続状態インジケーター（緑/オレンジ/赤）

### 再生履歴管理
- 直近の再生履歴を時系列で表示
- 現在再生中のトラック（`isPlaying: true`）を履歴から自動除外
- 相対的な再生時間表示（「3分前」「1時間前」など）
- WebSocketとの連携による履歴のリアルタイム更新
- クリック可能なトラック項目でLast.fmページへのナビゲーション

### インタラクティブ要素
- **クリック可能なトラック**: Last.fmトラックページを新しいタブで開く
- **クリック可能なアーティスト**: Last.fmアーティストページを新しいタブで開く
- **URL生成**: UrlHelperによる動的Last.fm URLの生成
- **マウスカーソル**: ホバー時のポインターカーソル変更

### ビジュアルデータ表現
- リスニングトレンド用の線グラフ
- サーバー統計用の進捗インジケーター
- キャッシュ機能付きアルバムアートワーク表示
- アニメーション付きローディング状態
- プレースホルダー画像とエラーハンドリング

### エラーハンドリング
- 包括的なエラー状態管理
- ユーザーフレンドリーなエラーメッセージ
- 自動再試行メカニズム
- Null安全なJSONパース
- Comprehensive failure types (Network, Server, Cache, WebSocket)
- User-friendly error messages
- Retry mechanisms

## 📊 設定可能な定数

カスタマイズ可能な設定：

```dart
// core/constants/app_constants.dart
class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:3001';
  static const String wsUrl = 'ws://localhost:3001';

  // API Endpoints
  static const String healthEndpoint = '/health';
  static const String nowPlayingEndpoint = '/api/now-playing';
  static const String statsEndpoint = '/api/stats';
  static const String reportsEndpoint = '/api/reports';
  static const String recentTracksEndpoint = '/api/recent-tracks';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double chartHeight = 300.0;

  // Animations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
```

## 📈 パフォーマンス最適化

- **キャッシュネットワーク画像**: 効率的な画像読み込みとキャッシュ
- **遅延読み込み**: チャートとコンポーネントのオンデマンド読み込み
- **状態の永続化**: Riverpodによる最小限の再レンダリング
- **WebSocket管理**: 適切な接続ライフサイクル管理

## 🧪 テスト

プロジェクトには以下が含まれます：
- UIコンポーネント用のウィジェットテスト
- ビジネスロジック用のユニットテスト
- API接続用の統合テスト

テストの実行：
```bash
flutter test
```

## 📦 ビルドとデプロイ

### Webビルド
```bash
flutter build web --release
```

### 開発サーバー
```bash
flutter run -d chrome --web-port 8080
```

## 📄 ライセンス

MIT

## 🙏 謝辞

- [Flutter](https://flutter.dev/) - クロスプラットフォームUIツールキット
- [Riverpod](https://riverpod.dev/) - シンプルかつ強力な状態管理
- [FL Chart](https://github.com/imaNNeoFighT/fl_chart) - 美しいチャートライブラリ
- [Freezed](https://pub.dev/packages/freezed) - Dartのコード生成
- [Last.fm API](https://www.last.fm/api) - 音楽データ提供
