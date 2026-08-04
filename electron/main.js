const { app, BrowserWindow, shell } = require('electron');
const http = require('http');
const fs = require('fs');
const path = require('path');

const WEB_DIR = path.join(__dirname, '..', 'build', 'web');

let server;
let mainWindow;

const mimeTypes = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.mp3': 'audio/mpeg',
  '.wav': 'audio/wav',
  '.wasm': 'application/wasm',
};

function safePath(requestPath) {
  const normalized = path
    .normalize(decodeURIComponent(requestPath))
    .replace(/^([.][.][/\\])+/, '');

  const resolvedWeb = path.resolve(WEB_DIR);
  const fullPath = path.resolve(path.join(WEB_DIR, normalized));

  if (!fullPath.startsWith(resolvedWeb)) {
    return null;
  }

  return fullPath;
}

function createServer() {
  return http.createServer((req, res) => {
    let urlPath;

    try {
      urlPath = new URL(req.url, 'http://127.0.0.1').pathname;
    } catch (_) {
      urlPath = req.url;
    }

    if (urlPath === '/') {
      urlPath = '/index.html';
    }

    const filePath = safePath(urlPath);

    if (!filePath) {
      res.writeHead(403);
      res.end('Forbidden');
      return;
    }

    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }

      const ext = path.extname(filePath).toLowerCase();

      res.writeHead(200, {
        'Content-Type': mimeTypes[ext] || 'application/octet-stream',
        'Cache-Control': 'no-store',
      });

      res.end(data);
    });
  });
}

function createWindow(port) {
  mainWindow = new BrowserWindow({
    width: 430,
    height: 900,
    minWidth: 380,
    minHeight: 700,
    backgroundColor: '#070B14',
    autoHideMenuBar: true,
    title: 'SonicWave',
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });

  mainWindow.loadURL(`http://127.0.0.1:${port}/`);
}

app.commandLine.appendSwitch('autoplay-policy', 'no-user-gesture-required');

app.on('web-contents-created', (event, contents) => {
  contents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });

  contents.on('will-navigate', (event) => {
    event.preventDefault();
  });
});

app.whenReady().then(async () => {
  server = createServer();

  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', resolve);
  });

  const port = server.address().port;

  createWindow(port);

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow(port);
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('before-quit', () => {
  if (server) {
    server.close();
  }
});
