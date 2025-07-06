# Last.fm Now Playing ダッシュボード - Flutter Web アプリケーション

レイヤードアーキテクチャとRiverpod状態管理を使用して、Last.fm APIバックエンドサーバーに接続し、現在再生中の情報と音楽レポートを視覚的コンポーネントで表示する洗練されたFlutter Webアプリケーションです。

## 🚀 機能

- **リアルタイム再生表示**: アルバムアートワーク付きで現在再生中のトラックを表示
- **音楽レポート**: 日次、週次、月次の音楽リスニング統計
- **インタラクティブチャート**: FL Chartを使用したリスニングトレンドの視覚的表現
- **サーバー統計**: リアルタイムサーバーパフォーマンス監視
- **レスポンシブデザイン**: 横向き/ランドスケープレイアウトに最適化
- **WebSocket統合**: 現在再生中情報のライブ更新

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
- **HTTP & WebSocket**: API通信
- **Google Fonts**: タイポグラフィ
- **Responsive Framework**: レスポンシブデザインユーティリティ

## 📡 バックエンド統合

`http://localhost:3001`で実行されているLast.fmプロキシサーバーに接続：

### APIエンドポイント
- `GET /health` - ヘルスチェック
- `GET /api/now-playing` - 現在再生中のトラック
- `GET /api/reports/{period}` - 音楽レポート（日次/週次/月次）
- `GET /api/stats` - サーバー統計

### WebSocket接続
- `ws://localhost:3001` - リアルタイム再生情報更新

## 🎨 UIコンポーネント

### ダッシュボードレイアウト
- **Now Playing Card**: アルバムアートとライブインジケーター付きで現在のトラックを表示
- **Server Stats Card**: 稼働時間、API呼び出し、接続数、メモリ使用量を表示
- **Period Selector**: 日次/週次/月次レポート間の切り替え
- **Music Report Card**: インタラクティブチャートとトップトラック/アーティストリスト

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
- **StateProviders**: UI状態（選択された期間など）
- **FutureProviders**: 非同期データ読み込み
- **StreamProviders**: WebSocketリアルタイム更新

## 🎯 主要機能の実装

### リアルタイム更新
- 現在再生中の情報をライブ更新するWebSocket接続
- レポートと統計の自動更新機能
- ローディング状態とエラーハンドリング

### ビジュアルデータ表現
- リスニングトレンド用の線グラフ
- サーバー統計用の進捗インジケーター
- キャッシュ機能付きアルバムアートワーク表示
- アニメーション付きローディング状態

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
  static const String baseUrl = 'http://localhost:3001';
  static const String wsUrl = 'ws://localhost:3001';
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const int primaryColorValue = 0xFF1DB954;
  static const int secondaryColorValue = 0xFF191414;
  static const double chartHeight = 300.0;
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

## 🤝 コントリビューション

1. リポジトリをフォーク
2. フィーチャーブランチを作成（`git checkout -b feature/amazing-feature`）
3. 変更をコミット（`git commit -m 'Add amazing feature'`）
4. ブランチにプッシュ（`git push origin feature/amazing-feature`）
5. プルリクエストを開く

## 📄 ライセンス

このプロジェクトはMITライセンスの下で配布されています。詳細は[LICENSE](LICENSE)ファイルをご覧ください。

## 🙏 謝辞

- [Flutter](https://flutter.dev/) - クロスプラットフォームUIツールキット
- [Riverpod](https://riverpod.dev/) - シンプルかつ強力な状態管理
- [FL Chart](https://github.com/imaNNeoFighT/fl_chart) - 美しいチャートライブラリ
- [Freezed](https://pub.dev/packages/freezed) - Dartのコード生成
- [Last.fm API](https://www.last.fm/api) - 音楽データ提供
