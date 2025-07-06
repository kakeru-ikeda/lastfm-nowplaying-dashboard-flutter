#!/bin/bash

# Flutter Web + Node.js Server 起動スクリプト

set -e

echo "🧹 Cleaning Flutter project..."
flutter clean

echo "📥 Getting Flutter dependencies..."
flutter pub get

echo "⚙️ Generating Freezed and JSON serialization code..."
dart run build_runner build --delete-conflicting-outputs

echo "🔨 Building Flutter Web application..."
flutter build web --web-renderer html --no-tree-shake-icons

echo "📦 Installing Node.js dependencies..."
npm install

echo "🚀 Starting server..."

# HTTPSフラグをチェック
if [ "$1" = "--https" ] || [ "$1" = "-s" ]; then
    echo "🔒 Starting HTTPS server on port 6443..."
    echo "📱 Access the app at: https://localhost:6443"
    echo "⚠️ 自己署名証明書を使用します。ブラウザで警告が表示される場合があります。"
    npm run start:https
else
    echo "🚀 Starting HTTP server on port 6001..."
    echo "📱 Access the app at: http://localhost:6001"
    echo "💡 HTTPSサーバーを起動するには: ./start.sh --https"
    npm start
fi
