#!/bin/bash

# Flutter Web + Node.js Server 起動スクリプト
# 使用方法: ./start.sh [https]
# .envファイルから環境変数を自動読み込み

set -e

# .envファイルの読み込み
if [ -f ".env" ]; then
    echo "📄 .envファイルを読み込み中..."
    export $(grep -v '^#' .env | grep -v '^$' | xargs)
    echo "✅ 環境変数を読み込みました"
else
    echo "⚠️  .envファイルが見つかりません (.env.exampleからコピーしてください)"
fi

# HTTPSモードの判定
HTTPS_MODE=false
if [ "$1" = "https" ]; then
    HTTPS_MODE=true
fi

# 環境変数のデフォルト値設定
export API_HOST=${API_HOST:-localhost}
export API_PORT=${API_PORT:-3001}
export API_PROTOCOL=${API_PROTOCOL:-http}

echo "🔧 Flutter Web + Node.js Server 起動スクリプト"
echo "================================================="
echo "🌐 API設定:"
echo "   Host: $API_HOST"
echo "   Port: $API_PORT"
echo "   Protocol: $API_PROTOCOL"
echo "   Base URL: $API_PROTOCOL://$API_HOST:$API_PORT"
echo ""

echo "🧹 Cleaning Flutter project..."
flutter clean

echo "📥 Getting Flutter dependencies..."
flutter pub get

echo "☝ Incrementing build number..."
if [ -f "scripts/version_manager.sh" ]; then
    ./scripts/version_manager.sh increment
else
    echo "⚠️  Version manager script not found, skipping version increment"
fi

echo "⚙️ Generating Freezed and JSON serialization code..."
dart run build_runner build --delete-conflicting-outputs

echo "💪 Building Flutter Web application..."
flutter build web --web-renderer html --dart-define=API_HOST=$API_HOST --dart-define=API_PORT=$API_PORT --dart-define=API_PROTOCOL=$API_PROTOCOL --no-tree-shake-icons

echo "📦 Installing Node.js dependencies..."
npm install

echo "🚀 Starting Node.js server..."
node server.js
