const { app, BrowserWindow, shell, dialog, ipcMain } = require('electron');
const http = require('http');
const fs = require('fs');
const path = require('path');

const WEB_DIR = path.join(__dirname, '..', 'build', 'web');

const AUDIO_EXTS = ['.mp3', '.wav', '.ogg', '.m4a', '.flac', '.aac', '.wma'];

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
  '.ogg': 'audio/ogg',
  '.m4a': 'audio/mp4',
  '.flac': 'audio/flac',
  '.aac': 'audio/aac',
  '.wma': 'audio/x-ms-wma',
  '.wasm': 'application/wasm',
};

function safePath(requestPath) {
  const normalized = path
    .normalize(decodeURIComponent(requestPath))
    .replace(/^([.][.][/\\])+/, '');

  const resolvedWeb = path.resolve(WEB_DIR);
  const fullPath = path.resolve(path.join(WEB_DIR, normalized));

  if (!fullPath.startsWith(resolvedWeb)) return null;
  return fullPath;
}

function collectAudioFiles(dir) {
  const results = [];
  let entries;

  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch (_) {
    return results;
  }

  for (const entry of entries) {
    const full = path.join(dir, entry.name);

    if (entry.isDirectory()) {
      results.push(...collectAudioFiles(full));
    } else if (AUDIO_EXTS.includes(path.extname(entry.name).toLowerCase())) {
      results.push(full);
    }
  }

  return results;
}

// ---------- پنجره ----------
ipcMain.handle('win-minimize', () => {
  if (mainWindow) mainWindow.minimize();
});

ipcMain.handle('win-maximize', () => {
  if (!mainWindow) return;
  if (mainWindow.isMaximized()) mainWindow.unmaximize();
  else mainWindow.maximize();
});

ipcMain.handle('win-close', () => {
  if (mainWindow) mainWindow.close();
});

// ---------- فایل‌ها ----------
ipcMain.handle('select-folder', async () => {
  const result = await dialog.showOpenDialog({
    title: 'پوشه موزیک خود را انتخاب کنید',
    properties: ['openDirectory'],
  });

  if (result.canceled || result.filePaths.length === 0) return null;
  return result.filePaths[0];
});

ipcMain.handle('list-audio-files', async (event, folderPath) => {
  if (!folderPath || typeof folderPath !== 'string') return [];
  return collectAudioFiles(path.resolve(folderPath));
});

ipcMain.handle('file-rename', async (event, oldPath, newPath) => {
  try {
    fs.renameSync(oldPath, newPath);
    return true;
  } catch (_) {
    return false;
  }
});

ipcMain.handle('file-delete', async (event, filePath) => {
  try {
    fs.unlinkSync(filePath);
    return true;
  } catch (_) {
    return false;
  }
});

ipcMain.handle('file-reveal', async (event, filePath) => {
  try {
    shell.showItemInFolder(filePath);
    return true;
  } catch (_) {
    return false;
  }
});

// ---------- سرور محلی ----------
function createServer() {
  return http.createServer((req, res) => {
    let parsed;

    try {
      parsed = new URL(req.url, 'http://127.0.0.1');
    } catch (_) {
      parsed = null;
    }

    const urlPath = parsed ? parsed.pathname : req.url;

    if (urlPath === '/localfile') {
      const q = parsed ? parsed.searchParams.get('path') : null;

      if (!q) {
        res.writeHead(400);
        res.end('Missing path');
        return;
      }

      let filePath;
      try {
        filePath = path.resolve(decodeURIComponent(q));
      } catch (_) {
        filePath = null;
      }

      const ext = filePath ? path.extname(filePath).toLowerCase() : '';

      if (!filePath || !AUDIO_EXTS.includes(ext) || !fs.existsSync(filePath)) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }

      const stat = fs.statSync(filePath);

      res.writeHead(200, {
        'Content-Type': mimeTypes[ext] || 'audio/mpeg',
        'Content-Length': stat.size,
        'Cache-Control': 'no-store',
      });

      fs.createReadStream(filePath).pipe(res);
      return;
    }

    let assetPath = urlPath;
    if (assetPath === '/') assetPath = '/index.html';

    const filePath = safePath(assetPath);

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
    frame: false,
    backgroundColor: '#070B14',
    title: 'SonicWave',
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
      preload: path.join(__dirname, 'preload.js'),
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
