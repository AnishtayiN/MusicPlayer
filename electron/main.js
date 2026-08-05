const { app, BrowserWindow, shell, dialog, ipcMain, globalShortcut } = require('electron');
const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');
const mm = require('music-metadata');

const WEB_DIR = path.join(__dirname, '..', 'build', 'web');
const AUDIO_EXTS = ['.mp3', '.wav', '.ogg', '.m4a', '.flac', '.aac', '.wma'];

let server;
let mainWindow;

const mimeTypes = {
  '.html': 'text/html', '.js': 'application/javascript', '.css': 'text/css',
  '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg', '.gif': 'image/gif', '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon', '.mp3': 'audio/mpeg', '.wav': 'audio/wav',
  '.ogg': 'audio/ogg', '.m4a': 'audio/mp4', '.flac': 'audio/flac',
  '.aac': 'audio/aac', '.wma': 'audio/x-ms-wma', '.wasm': 'application/wasm',
};

function safePath(p) {
  const normalized = path.normalize(decodeURIComponent(p)).replace(/^([.][.][/\\])+/, '');
  const resolvedWeb = path.resolve(WEB_DIR);
  const full = path.resolve(path.join(WEB_DIR, normalized));
  return full.startsWith(resolvedWeb) ? full : null;
}

function collectAudioFiles(dir) {
  const results = [];
  let entries;
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch (_) { return results; }
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) results.push(...collectAudioFiles(full));
    else if (AUDIO_EXTS.includes(path.extname(e.name).toLowerCase())) results.push(full);
  }
  return results;
}

function sendMedia(key) {
  BrowserWindow.getAllWindows().forEach((w) => w.webContents.send('media-key', key));
}

ipcMain.handle('select-folder', async () => {
  const r = await dialog.showOpenDialog({ title: 'پوشه موزیک', properties: ['openDirectory'] });
  return r.canceled || r.filePaths.length === 0 ? null : r.filePaths[0];
});

ipcMain.handle('list-audio-files', async (e, p) => {
  if (!p || typeof p !== 'string') return [];
  return collectAudioFiles(path.resolve(p));
});

ipcMain.handle('file-rename', async (e, a, b) => {
  try { fs.renameSync(a, b); return true; } catch (_) { return false; }
});

ipcMain.handle('file-delete', async (e, p) => {
  try { fs.unlinkSync(p); return true; } catch (_) { return false; }
});

ipcMain.handle('file-reveal', async (e, p) => {
  try { shell.showItemInFolder(p); return true; } catch (_) { return false; }
});

ipcMain.handle('get-metadata', async (e, p) => {
  try {
    const meta = await mm.parseFile(p);
    let cover = null;
    const pics = meta.common.picture;
    if (pics && pics.length) {
      cover = 'data:' + pics[0].format + ';base64,' + pics[0].data.toString('base64');
    }
    return {
      album: meta.common.album || null,
      year: meta.common.year || null,
      bitrate: meta.format.bitrate ? Math.round(meta.format.bitrate / 1000) : null,
      cover,
    };
  } catch (_) { return null; }
});

ipcMain.handle('read-file-text', async (e, p) => {
  try { return fs.readFileSync(p, 'utf8'); } catch (_) { return null; }
});

ipcMain.handle('get-music-dir', async () => {
  const dir = path.join(os.homedir(), 'Music');
  return fs.existsSync(dir) ? dir : null;
});

function createServer() {
  return http.createServer((req, res) => {
    let parsed;
    try { parsed = new URL(req.url, 'http://127.0.0.1'); } catch (_) { parsed = null; }
    const urlPath = parsed ? parsed.pathname : req.url;

    if (urlPath === '/localfile') {
      const q = parsed ? parsed.searchParams.get('path') : null;
      if (!q) { res.writeHead(400); res.end(); return; }
      let fp;
      try { fp = path.resolve(decodeURIComponent(q)); } catch (_) { fp = null; }
      const ext = fp ? path.extname(fp).toLowerCase() : '';
      if (!fp || !AUDIO_EXTS.includes(ext) || !fs.existsSync(fp)) {
        res.writeHead(404); res.end(); return;
      }
      const stat = fs.statSync(fp);
      res.writeHead(200, {
        'Content-Type': mimeTypes[ext] || 'audio/mpeg',
        'Content-Length': stat.size,
        'Cache-Control': 'no-store',
      });
      fs.createReadStream(fp).pipe(res);
      return;
    }

    let asset = urlPath;
    if (asset === '/') asset = '/index.html';
    const fp = safePath(asset);
    if (!fp) { res.writeHead(403); res.end(); return; }

    fs.readFile(fp, (err, data) => {
      if (err) { res.writeHead(404); res.end(); return; }
      const ext = path.extname(fp).toLowerCase();
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
    width: 900,
    height: 800,
    minWidth: 380,
    minHeight: 600,
    backgroundColor: '#070B14',
    title: 'SonicWave',
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
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
  contents.on('will-navigate', (e) => e.preventDefault());
});

app.whenReady().then(async () => {
  server = createServer();
  await new Promise((res, rej) => {
    server.once('error', rej);
    server.listen(0, '127.0.0.1', res);
  });
  const port = server.address().port;
  createWindow(port);

  globalShortcut.register('MediaPlayPause', () => sendMedia('playpause'));
  globalShortcut.register('MediaNextTrack', () => sendMedia('next'));
  globalShortcut.register('MediaPreviousTrack', () => sendMedia('prev'));

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow(port);
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

app.on('before-quit', () => {
  globalShortcut.unregisterAll();
  if (server) server.close();
});
