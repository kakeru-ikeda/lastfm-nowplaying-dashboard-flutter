const express = require('express');
const https = require('https');
const http = require('http');
const path = require('path');
const compression = require('compression');
const helmet = require('helmet');
const cors = require('cors');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 6001;
const HTTPS_PORT = process.env.HTTPS_PORT || 6443;
const BUILD_PATH = path.join(__dirname, 'build', 'web');
const USE_HTTPS = process.env.USE_HTTPS === 'true' || process.argv.includes('--https');

// セキュリティミドルウェア（CSPを一時的に無効化）
app.use(helmet({
    contentSecurityPolicy: false, // デバッグのため一時的に無効化
}));

// CORS設定
app.use(cors({
    origin: ['http://localhost:6000', 'http://localhost:6001', 'https://localhost:6443', 'http://localhost:3001'],
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

// 自己署名証明書を作成する関数
function generateSelfSignedCert() {
    const forge = require('node-forge');
    const keys = forge.pki.rsa.generateKeyPair(2048);
    const cert = forge.pki.createCertificate();
    
    cert.publicKey = keys.publicKey;
    cert.serialNumber = '01';
    cert.validity.notBefore = new Date();
    cert.validity.notAfter = new Date();
    cert.validity.notAfter.setFullYear(cert.validity.notBefore.getFullYear() + 1);
    
    const attrs = [{
        name: 'commonName',
        value: 'localhost'
    }, {
        name: 'organizationName',
        value: 'Last.fm Dashboard'
    }];
    
    cert.setSubject(attrs);
    cert.setIssuer(attrs);
    cert.setExtensions([{
        name: 'basicConstraints',
        cA: true
    }, {
        name: 'keyUsage',
        keyCertSign: true,
        digitalSignature: true,
        nonRepudiation: true,
        keyEncipherment: true,
        dataEncipherment: true
    }, {
        name: 'extKeyUsage',
        serverAuth: true,
        clientAuth: true,
        codeSigning: true,
        emailProtection: true,
        timeStamping: true
    }, {
        name: 'nsCertType',
        client: true,
        server: true,
        email: true,
        objsign: true,
        sslCA: true,
        emailCA: true,
        objCA: true
    }, {
        name: 'subjectAltName',
        altNames: [{
            type: 2, // DNS
            value: 'localhost'
        }, {
            type: 7, // IP
            ip: '127.0.0.1'
        }]
    }]);
    
    cert.sign(keys.privateKey);
    
    return {
        cert: forge.pki.certificateToPem(cert),
        key: forge.pki.privateKeyToPem(keys.privateKey)
    };
}

// HTTPS証明書の設定
function getHTTPSOptions() {
    const certPath = path.join(__dirname, 'localhost.crt');
    const keyPath = path.join(__dirname, 'localhost.key');
    
    try {
        // 既存の証明書ファイルがあるかチェック
        if (fs.existsSync(certPath) && fs.existsSync(keyPath)) {
            return {
                key: fs.readFileSync(keyPath),
                cert: fs.readFileSync(certPath)
            };
        }
    } catch (error) {
        console.log('既存の証明書ファイルが見つからないか、読み込めません');
    }
    
    try {
        // 自己署名証明書を動的に生成
        console.log('🔐 自己署名証明書を生成中...');
        const { cert, key } = generateSelfSignedCert();
        
        // ファイルに保存（次回起動時に再利用）
        fs.writeFileSync(certPath, cert);
        fs.writeFileSync(keyPath, key);
        
        console.log('✅ 自己署名証明書が生成されました');
        return { key, cert };
    } catch (error) {
        console.warn('⚠️ 自己署名証明書の生成に失敗しました:', error.message);
        console.log('💡 node-forgeをインストールしてください: npm install node-forge');
        return null;
    }
}

// サーバー起動
const startServer = () => {
    if (USE_HTTPS) {
        const httpsOptions = getHTTPSOptions();
        if (httpsOptions) {
            const httpsServer = https.createServer(httpsOptions, app);
            httpsServer.listen(HTTPS_PORT, () => {
                console.log(`🔒 HTTPS Flutter Web Server running on https://localhost:${HTTPS_PORT}`);
                console.log(`📁 Serving files from: ${BUILD_PATH}`);
                console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
                console.log(`💾 Health check available at: https://localhost:${HTTPS_PORT}/health`);
                console.log(`⚠️ 自己署名証明書を使用しています。ブラウザで警告が表示された場合は「詳細設定」→「localhost にアクセスする（安全ではありません）」をクリックしてください。`);
            });
            
            // グレースフルシャットダウンの設定
            setupGracefulShutdown(httpsServer);
            return httpsServer;
        } else {
            console.log('🔄 HTTPS証明書の準備ができていないため、HTTPサーバーを起動します...');
        }
    }
    
    // HTTPサーバー
    const httpServer = http.createServer(app);
    httpServer.listen(PORT, () => {
        console.log(`🚀 HTTP Flutter Web Server running on http://localhost:${PORT}`);
        console.log(`📁 Serving files from: ${BUILD_PATH}`);
        console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
        console.log(`💾 Health check available at: http://localhost:${PORT}/health`);
        if (!USE_HTTPS) {
            console.log(`💡 HTTPSサーバーを起動するには --https フラグを追加してください`);
        }
    });
    
    setupGracefulShutdown(httpServer);
    return httpServer;
};

// グレースフルシャットダウンの設定
function setupGracefulShutdown(server) {
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
}

startServer();
