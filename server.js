const fs = require('fs');
const https = require('https');
const express = require('express');
const path = require('path');
const compression = require('compression');
const helmet = require('helmet');
const cors = require('cors');

// .envファイルの読み込み
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 8443;
const BUILD_PATH = path.join(__dirname, 'build', 'web');

// HTTPS証明書の設定
const httpsOptions = {
    key: fs.readFileSync('./localhost+3-key.pem'),
    cert: fs.readFileSync('./localhost+3.pem'),
};

// セキュリティミドルウェア（CSPを一時的に無効化）
app.use(helmet({
    contentSecurityPolicy: false, // デバッグのため一時的に無効化
}));

// CORS設定（HTTPS用に更新）
app.use(cors({
    origin: [
        'https://localhost:8443', 
        'https://localhost', 
        'https://127.0.0.1:8443',
        'https://127.0.0.1',
        'https://192.168.40.99:8443',
        'https://192.168.40.99',
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

// HTTPSサーバー起動
const server = https.createServer(httpsOptions, app).listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Flutter Web HTTPS Server running on:`);
    console.log(`   👉 https://localhost:${PORT}`);
    console.log(`   👉 https://127.0.0.1:${PORT}`);
    console.log(`   👉 https://192.168.40.99:${PORT}`);
    console.log(`📁 Serving files from: ${BUILD_PATH}`);
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`💾 Health check available at: https://localhost:${PORT}/health`);
    console.log(`🛡️ HTTPS enabled with mkcert certificate`);
});

// グレースフルシャットダウン
const gracefulShutdown = (signal) => {
    console.log(`${signal} received, shutting down gracefully`);
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
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
