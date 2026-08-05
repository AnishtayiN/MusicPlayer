const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('sonicwave', {
  selectFolder: () => ipcRenderer.invoke('select-folder'),
  listAudioFiles: (folderPath) => ipcRenderer.invoke('list-audio-files', folderPath),
});
