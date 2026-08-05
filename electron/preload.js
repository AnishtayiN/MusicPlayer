const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('sonicwave', {
  selectFolder: () => ipcRenderer.invoke('select-folder'),
  listAudioFiles: (folderPath) => ipcRenderer.invoke('list-audio-files', folderPath),
  renameFile: (oldPath, newPath) => ipcRenderer.invoke('file-rename', oldPath, newPath),
  deleteFile: (filePath) => ipcRenderer.invoke('file-delete', filePath),
  revealFile: (filePath) => ipcRenderer.invoke('file-reveal', filePath),
});
