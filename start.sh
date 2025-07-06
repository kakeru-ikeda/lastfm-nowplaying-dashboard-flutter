#!/bin/bash

# Flutter Web + Node.js Server 起動スクリプト

set -e

echo "🔨 Building Flutter Web application..."
flutter build web

echo "📦 Installing Node.js dependencies..."
npm install

echo "🚀 Starting server on port 6001..."
echo "📱 Access the app at: http://localhost:6001"
npm start
