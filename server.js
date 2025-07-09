const fs = require('fs');
const https = require('https');
const express = require('express');
const path = require('path');
const compression = require('compression');
const helmet = require('helmet');
const cors = require('cors');
const MkcertAutoRenewer = require('./mkcert-auto-renewer');

// .envファイルの読み込み
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 8444;
const BUILD_PATH = path.join(__dirname, 'build', 'web');

// HTTPS設定
const HTTPS_ENABLED = process.env.HTTPS_ENABLED === 'true';
const HTTPS_PORT = process.env.HTTPS_PORT || 8444;

// セキュリティミドルウェア（CSPを一時的に無効化）
app.use(helmet({
    contentSecurityPolicy: false, // デバッグのため一時的に無効化
}));

// CORS設定（HTTPS用に更新）
app.use(cors({
    origin: [
        'https://localhost:8444', 
        'https://localhost', 
        'https://127.0.0.1:8444',
        'https://127.0.0.1',
        'https://192.168.40.99:8444',
        'https://192.168.40.99',
        'http://localhost:8080',
        'https://localhost:8080',
        'http://localhost:3001'
    ],
    credentials: true
}));

// Gzip圧縮
app.use(compression());

// 静的ファイルの配信
app.use(express.static(BUILD_PATH, {
    maxAge: '1d',
    etag: true,
    lastModified: true,
    setHeaders: (res, filePath) => {
        // キャッシュ設定
        if (filePath.endsWith('.js') || filePath.endsWith('.css')) {
            res.setHeader('Cache-Control', 'public, max-age=31536000'); // 1年
        } else if (filePath.endsWith('.html')) {
            res.setHeader('Cache-Control', 'no-cache');
        }

        // Flutter Web特有のMIMEタイプ設定
        if (filePath.endsWith('.js')) {
            res.setHeader('Content-Type', 'application/javascript; charset=utf-8');
        } else if (filePath.endsWith('.wasm')) {
            res.setHeader('Content-Type', 'application/wasm');
        } else if (filePath.endsWith('.html')) {
            res.setHeader('Content-Type', 'text/html; charset=utf-8');
        }
        
        // HTTPS用セキュリティヘッダー
        res.setHeader('X-Content-Type-Options', 'nosniff');
        res.setHeader('X-Frame-Options', 'DENY');
        res.setHeader('X-XSS-Protection', '1; mode=block');
    }
}));

// ヘルスチェックエンドポイント
app.get('/health', (req, res) => {
    res.json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development'
    });
});

// SPAのルーティング対応 - すべてのルートをindex.htmlにリダイレクト
app.get('*', (req, res) => {
    res.sendFile(path.join(BUILD_PATH, 'index.html'), (err) => {
        if (err) {
            console.error('Error serving index.html:', err);
            res.status(500).send('Internal Server Error');
        }
    });
});

// エラーハンドリング
app.use((err, req, res, next) => {
    console.error('Server error:', err);
    res.status(500).json({
        error: 'Internal Server Error',
        message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
    });
});

// サーバー起動（HTTPS対応）
let server;

// mkcert-auto-renewer初期化（読み込みモードのみ）
const initializeServer = async () => {
    if (HTTPS_ENABLED) {
        try {
            // 証明書の読み込みモードでMkcertAutoRenewerを設定
            const renewer = new MkcertAutoRenewer({
                certPath: process.env.HTTPS_CERT_PATH,
                keyPath: process.env.HTTPS_KEY_PATH
            });
            
            // HTTPS設定を取得（証明書生成せず、既存の証明書を使用）
            const httpsOptions = await renewer.getHttpsOptions();
            
            if (!httpsOptions || !httpsOptions.key || !httpsOptions.cert) {
                throw new Error('HTTPS証明書が読み込めません。パスが正しいか確認してください。');
            }
            
            // HTTPSサーバー起動
            server = https.createServer(httpsOptions, app).listen(HTTPS_PORT, '0.0.0.0', () => {
                console.log(`🚀 Flutter Web HTTPS Server running on:`);
                console.log(`   👉 https://localhost:${HTTPS_PORT}`);
                console.log(`   👉 https://127.0.0.1:${HTTPS_PORT}`);
                console.log(`   👉 https://192.168.40.99:${HTTPS_PORT}`);
                console.log(`📁 Serving files from: ${BUILD_PATH}`);
                console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
                console.log(`💾 Health check available at: https://localhost:${HTTPS_PORT}/health`);
                console.log(`🛡️ HTTPS enabled with mkcert certificate`);
            });
            
            // 証明書変更の監視設定（オプション）
            renewer.startWatching(() => {
                console.log('🔄 証明書ファイルが変更されました');
                // 必要に応じてサーバー再起動などの処理
            });
            
        } catch (error) {
            console.error('HTTPSサーバーの起動に失敗しました:', error);
            process.exit(1);
        }
    } else {
        // HTTP専用サーバー（HTTPS無効時）
        server = app.listen(PORT, '0.0.0.0', () => {
            console.log(`🚀 Flutter Web HTTP Server running on:`);
            console.log(`   👉 http://localhost:${PORT}`);
            console.log(`   👉 http://127.0.0.1:${PORT}`);
            console.log(`   👉 http://192.168.40.99:${PORT}`);
            console.log(`📁 Serving files from: ${BUILD_PATH}`);
            console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
            console.log(`💾 Health check available at: http://localhost:${PORT}/health`);
        });
    }
};

// サーバー初期化実行
initializeServer();

// グレースフルシャットダウン
const gracefulShutdown = (signal) => {
    console.log(`${signal} received, shutting down gracefully`);
    if (server) {
        server.close((err) => {
            if (err) {
                console.error('Error during server shutdown:', err);
                process.exit(1);
            }
            console.log('✅ Server closed successfully');
            process.exit(0);
        });

        // 強制終了のタイムアウト
        setTimeout(() => {
            console.error('❌ Could not close connections in time, forcefully shutting down');
            process.exit(1);
        }, 10000);
    } else {
        console.log('Server not initialized, exiting');
        process.exit(0);
    }
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
