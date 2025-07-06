<!-- このファイルを使用して、Copilotにワークスペース固有のカスタム指示を提供します。詳細については、https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file をご覧ください -->

# Last.fm Now Playing ダッシュボード - Flutter Web アプリケーション

これは、Last.fm API バックエンドサーバーに接続して、現在再生中の情報と音楽レポートを視覚的コンポーネントで表示する Flutter Web アプリケーションです。Clean ArchitectureとRiverpod状態管理を採用し、アニメーション機能とテーマ切り替え機能を備えています。

## アーキテクチャガイドライン

- **レイヤードアーキテクチャ**: プレゼンテーション、ドメイン、データ、インフラストラクチャレイヤー間の厳密な分離に従う
- **状態管理**: 適切なプロバイダーでRiverpodをすべての状態管理に使用する
- **UIコンポーネント**: `presentation/widgets` ディレクトリに再利用可能なコンポーネントを作成する
- **アニメーション設計**: TickerProviderStateMixinを使用した複数のAnimationControllerの効率的な管理
- **横向きレイアウト**: ランドスケープ/横向き画面の向きに合わせて設計する
- **レスポンシブデザイン**: 異なる画面サイズに対応するレスポンシブフレームワークを使用する
- **テーマ管理**: SharedPreferencesを使用した設定の永続化とRiverpodによる状態管理

## 主要技術

- Flutter Web
- Riverpod（状態管理）
- HTTP & WebSocket通信
- Freezed（イミュータブルデータクラス）
- JSON シリアライゼーション
- FlChart（チャートとグラフ）
- CachedNetworkImage（画像キャッシュ）
- SharedPreferences（設定永続化）
- Google Fonts（タイポグラフィ）
- Animation Controllers（アニメーション効果）

## バックエンドAPI

アプリケーションは `http://localhost:3001` で実行されているLast.fmプロキシサーバーに接続し、以下のエンドポイントを使用します：
- `GET /health` - ヘルスチェック
- `GET /api/now-playing` - 現在再生中のトラック
- `GET /api/reports/{period}` - 音楽レポート（日次/週次/月次）
- `GET /api/recent-tracks` - 直近の再生履歴（パラメータ：limit、page、from、to）
- `GET /api/stats` - サーバー統計
- WebSocket接続: `ws://localhost:3001`

## コード生成

Freezed、JSONシリアライゼーション、Riverpodでのコード生成には `dart run build_runner build --delete-conflicting-outputs` を使用してください。

## 開発プラクティス

- Clean Architectureの原則に従う
- Riverpodを使用した依存性注入を実装する
- 適切なエラーハンドリングを実装する
- 音楽データ用の視覚的で直感的なUIコンポーネントを作成する
- 音楽レポート用の適切なチャートと視覚化を使用する
- null安全性を重視し、JSONパースではnullチェックを行う
- 生成ファイル（*.g.dart、*.freezed.dart）はGitignoreに含める
- エラーログとデバッグ情報を適切に実装する

## ファイル構造

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

## コーディング規則

- エンティティクラスではnull許容フィールドを適切に使用する
- JsonHelperクラスを使用して安全なJSONパースを実行する
- AppLoggerを使用してnull安全なログ出力を行う
- WebSocketとAPI通信では適切なエラーハンドリングを実装する
- UIコンポーネントではnull値に対するフォールバック表示を提供する
- TickerProviderStateMixinを使用してアニメーションコントローラーを効率的に管理する
- アニメーションコントローラーはdispose()で適切に破棄する
- クリック可能な要素にはMouseRegionとGestureDetectorを組み合わせて使用する
- UrlHelperを使用してLast.fm URLの生成と新しいタブでの開放を実装する
- テーマ設定はSharedPreferencesで永続化し、Riverpodで状態管理する

## アニメーション実装ガイドライン

- 複数のアニメーションには個別のAnimationControllerを使用する
- アニメーションの開始はinitState()で、停止はdispose()で実行する
- CurvedAnimationを使用して自然なアニメーション効果を実現する
- リピートアニメーションには適切なreverse設定を行う
- AnimatedBuilderでアニメーション値を効率的にリッスンする

## UI/UXパターン

- SectionCardを使用して統一されたカードレイアウトを作成する
- ClickableTrackItemとClickableArtistItemでインタラクティブな要素を実装する
- ローディング、エラー、空の状態に対して適切なフォールバック表示を提供する
- マウスカーソルの変更でユーザビリティを向上させる
- アニメーション付きインジケーターでリアルタイム状態を表現する
