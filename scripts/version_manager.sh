#!/bin/bash

# バージョン管理用スクリプト
# pubspec.yamlのビルド番号をインクリメントし、バージョン情報をJSONファイルに出力

set -e

PUBSPEC_FILE="pubspec.yaml"
VERSION_INFO_FILE="assets/version.json"

# バージョン情報を取得する関数
get_current_version() {
    if [ ! -f "$PUBSPEC_FILE" ]; then
        echo "Error: pubspec.yaml not found" >&2
        exit 1
    fi
    
    # sedを使用してバージョン行を抽出
    local version_line=$(grep "^version:" "$PUBSPEC_FILE")
    if [ -z "$version_line" ]; then
        echo "Error: version not found in pubspec.yaml" >&2
        exit 1
    fi
    
    # バージョンとビルド番号を分離
    local version_full=$(echo "$version_line" | sed 's/version: *//')
    local version_name=$(echo "$version_full" | cut -d'+' -f1)
    local build_number=$(echo "$version_full" | cut -d'+' -f2)
    
    echo "$version_name+$build_number"
}

# ビルド番号をインクリメントする関数
increment_build_number() {
    if [ ! -f "$PUBSPEC_FILE" ]; then
        echo "Error: pubspec.yaml not found" >&2
        exit 1
    fi
    
    # 現在のバージョン情報を取得
    local version_line=$(grep "^version:" "$PUBSPEC_FILE")
    local version_full=$(echo "$version_line" | sed 's/version: *//')
    local version_name=$(echo "$version_full" | cut -d'+' -f1)
    local build_number=$(echo "$version_full" | cut -d'+' -f2)
    
    # ビルド番号をインクリメント
    local new_build_number=$((build_number + 1))
    local new_version="$version_name+$new_build_number"
    
    # pubspec.yamlを更新
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS用のsed
        sed -i '' "s/^version: .*/version: $new_version/" "$PUBSPEC_FILE"
    else
        # Linux用のsed
        sed -i "s/^version: .*/version: $new_version/" "$PUBSPEC_FILE"
    fi
    
    echo "✅ バージョンを更新: $version_full → $new_version" >&2
    echo "$new_version"
}

# バージョン情報をJSONファイルに出力する関数
generate_version_json() {
    local version="$1"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local build_time=$(date +"%Y年%m月%d日 %H:%M:%S")
    
    # バージョンとビルド番号を分離
    local version_name=$(echo "$version" | cut -d'+' -f1)
    local build_number=$(echo "$version" | cut -d'+' -f2)
    
    # Flutterアセット用JSONファイルを生成
    local assets_version_dir=$(dirname "assets/version.json")
    mkdir -p "$assets_version_dir"
    
    cat > "assets/version.json" << EOF
{
  "version": "$version_name",
  "buildNumber": "$build_number",
  "fullVersion": "$version",
  "buildTime": "$build_time",
  "timestamp": "$timestamp"
}
EOF
    
    echo "✅ Flutterアセット用バージョン情報ファイルを生成: assets/version.json" >&2
}

# ビルド後にサーバー用バージョンファイルを生成する関数
copy_version_for_server() {
    local build_version_file="build/web/assets/version.json"
    local server_version_file="assets/version.json"
    
    # Flutterビルド内のバージョンファイルが存在するかチェック
    if [ -f "$build_version_file" ]; then
        # サーバー用にassetsディレクトリにもコピー
        cp "$build_version_file" "$server_version_file"
        echo "✅ サーバー用バージョンファイルをコピー: $server_version_file" >&2
    else
        echo "⚠️  ビルド版バージョンファイルが見つかりません: $build_version_file" >&2
        # 既存のassetsファイルがあればそれを使用
        if [ -f "$server_version_file" ]; then
            echo "ℹ️  既存のassetsバージョンファイルを使用: $server_version_file" >&2
        else
            echo "❌ バージョンファイルが見つかりません" >&2
            return 1
        fi
    fi
}

# メイン実行部分
case "${1:-}" in
    "get")
        get_current_version
        ;;
    "increment")
        new_version=$(increment_build_number)
        generate_version_json "$new_version"
        ;;
    "generate")
        current_version=$(get_current_version)
        generate_version_json "$current_version"
        ;;
    "copy-for-server")
        copy_version_for_server
        ;;
    *)
        echo "使用方法: $0 {get|increment|generate|copy-for-server}"
        echo "  get             - 現在のバージョンを取得"
        echo "  increment       - ビルド番号をインクリメント"
        echo "  generate        - バージョン情報JSONを生成"
        echo "  copy-for-server - ビルド後にサーバー用バージョンファイルをコピー"
        exit 1
        ;;
esac
