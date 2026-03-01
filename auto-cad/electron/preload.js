const os = require('os');
const crypto = require('crypto');
const { contextBridge, ipcRenderer } = require('electron');

function resolveDeviceId() {
  try {
    const username = os.userInfo().username || 'unknown-user';
    const hostname = os.hostname() || 'unknown-host';
    const machine = `${process.platform}|${process.arch}|${hostname}|${username}`;
    return crypto.createHash('sha256').update(machine).digest('hex').slice(0, 32);
  } catch {
    return crypto
      .createHash('sha256')
      .update(`${process.platform}|${process.arch}|fallback`)
      .digest('hex')
      .slice(0, 32);
  }
}

contextBridge.exposeInMainWorld('desktopApp', {
  platform: process.platform,
  isDesktop: true,
  deviceId: resolveDeviceId(),
  saveTextFile: (payload) => ipcRenderer.invoke('madcad:save-text-file', payload),
  appendLicenseAudit: (payload) => ipcRenderer.invoke('madcad:append-license-audit', payload)
});
