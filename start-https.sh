#!/bin/bash

# Flutter Web + Node.js HTTPS Server 起動スクリプト（Chromeのセキュリティバナーを回避）

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

echo "🔒 Starting HTTPS server on port 6443..."
echo "📱 Access the app at: https://localhost:6443"
echo "⚠️ 自己署名証明書を使用します。ブラウザで警告が表示された場合は「詳細設定」→「localhost にアクセスする（安全ではありません）」をクリックしてください。"
echo "✅ この方法でChromeの「保護されていない通信」バナーが表示されなくなります。"

npm run start:https
