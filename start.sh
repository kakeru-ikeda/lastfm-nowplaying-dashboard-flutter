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

# HTTPSモードの場合は証明書の確認
if [ "$HTTPS_MODE" = true ]; then
    echo "🔒 HTTPS mode enabled - checking certificates..."
    
    if [ ! -f "./localhost+3.pem" ] || [ ! -f "./localhost+3-key.pem" ]; then
        echo "❌ mkcert証明書が見つかりません"
        echo "📋 証明書を作成してください:"
        echo "   mkcert localhost 127.0.0.1 ::1 192.168.40.99"
        echo "   または: npm run cert:create"
        exit 1
    fi
    echo "✅ 証明書の確認完了"
fi

echo "🧹 Cleaning Flutter project..."
flutter clean

echo "📥 Getting Flutter dependencies..."
flutter pub get

echo "⚙️ Generating Freezed and JSON serialization code..."
dart run build_runner build --delete-conflicting-outputs

echo "🔨 Building Flutter Web application..."
flutter build web --dart-define=API_HOST=$API_HOST --dart-define=API_PORT=$API_PORT --dart-define=API_PROTOCOL=$API_PROTOCOL --no-tree-shake-icons

echo "📦 Installing Node.js dependencies..."
npm install

echo "� Installing Node.js dependencies..."
npm install

if [ "$HTTPS_MODE" = true ]; then
    echo "�🚀 Starting HTTPS server on port 443..."
    echo "📍 アクセスURL:"
    echo "   👉 https://localhost"
    echo "   👉 https://127.0.0.1"
    echo "   👉 https://192.168.40.99"
    echo ""
    echo "🛡️ HTTPS enabled with mkcert certificate"
    echo "🛑 停止する場合は Ctrl+C を押してください"
    echo ""
    node server.js
else
    echo "🚀 Starting HTTP server on port 6001..."
    echo "📱 Access the app at: http://localhost:6001"
    echo "💡 HTTPS配信を利用する場合: ./start.sh https"
    echo ""
    npm start
fi
