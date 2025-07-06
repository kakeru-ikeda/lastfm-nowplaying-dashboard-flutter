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
flutter build web

echo "📦 Installing Node.js dependencies..."
npm install

echo "🚀 Starting server on port 6001..."
echo "📱 Access the app at: http://localhost:6001"
npm start
