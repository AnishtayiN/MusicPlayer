const { contextBridge, ipcRenderer } = require('electron');

let dropHandler = null;
let mediaHandler = null;

window.addEventListener('dragover', (e) => e.preventDefault());
window.addEventListener('drop', (e) => {
  e.preventDefault();
  const paths = [];
  for (const f of e.dataTransfer.files) {
    if (f.path) paths.push(f.path);
  }
  if (paths.length && dropHandler) dropHandler(paths);
});

ipcRenderer.on('media-key', (e, key) => {
  if (mediaHandler) mediaHandler(key);
});

contextBridge.exposeInMainWorld('sonicwave', {
  selectFolder: () => ipcRenderer.invoke('select-folder'),
  listAudioFiles: (p) => ipcRenderer.invoke('list-audio-files', p),
  renameFile: (a, b) => ipcRenderer.invoke('file-rename', a, b),
  deleteFile: (p) => ipcRenderer.invoke('file-delete', p),
  revealFile: (p) => ipcRenderer.invoke('file-reveal', p),
  getMetadata: (p) => ipcRenderer.invoke('get-metadata', p),
  readFileText: (p) => ipcRenderer.invoke('read-file-text', p),
  getMusicDir: () => ipcRenderer.invoke('get-music-dir'),
  onFilesDropped: (cb) => { dropHandler = cb; },
  onMediaKey: (cb) => { mediaHandler = cb; },
});
