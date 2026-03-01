const { contextBridge } = require('electron');

contextBridge.exposeInMainWorld('desktopApp', {
  platform: process.platform,
  isDesktop: true
});
