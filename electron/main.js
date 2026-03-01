const path = require('path');
const { app, BrowserWindow, Menu, shell, nativeImage } = require('electron');

const isMac = process.platform === 'darwin';
const appIconPng = path.join(__dirname, '..', 'assets', 'icons', 'madcad-512.png');

function createMainWindow() {
  const win = new BrowserWindow({
    width: 1680,
    height: 980,
    minWidth: 1200,
    minHeight: 760,
    backgroundColor: '#111b29',
    title: 'MadCAD 2D',
    icon: appIconPng,
    ...(isMac
      ? {
          titleBarStyle: 'hidden',
          trafficLightPosition: { x: 14, y: 12 }
        }
      : {}),
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      devTools: true
    }
  });

  win.loadFile(path.join(__dirname, '..', 'index.html'));

  win.webContents.setWindowOpenHandler(({ url }) => {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      shell.openExternal(url);
      return { action: 'deny' };
    }
    return { action: 'allow' };
  });

  if (!app.isPackaged) {
    win.webContents.openDevTools({ mode: 'detach' });
  }

  return win;
}

function createMenu() {
  const template = [
    ...(isMac
      ? [
          {
            label: app.name,
            submenu: [
              { role: 'about' },
              { type: 'separator' },
              { role: 'services' },
              { type: 'separator' },
              { role: 'hide' },
              { role: 'hideOthers' },
              { role: 'unhide' },
              { type: 'separator' },
              { role: 'quit' }
            ]
          }
        ]
      : []),
    {
      label: 'Plik',
      submenu: [
        {
          label: 'Nowy rysunek',
          accelerator: 'CmdOrCtrl+N',
          click: () => {
            const focused = BrowserWindow.getFocusedWindow();
            if (focused) {
              focused.webContents.executeJavaScript(
                "window.dispatchEvent(new KeyboardEvent('keydown', { key: 'n', ctrlKey: true }));"
              );
            }
          }
        },
        { type: 'separator' },
        { role: isMac ? 'close' : 'quit', label: isMac ? 'Zamknij okno' : 'Wyjście' }
      ]
    },
    {
      label: 'Edycja',
      submenu: [
        { role: 'undo', label: 'Cofnij' },
        { role: 'redo', label: 'Ponów' },
        { type: 'separator' },
        { role: 'cut', label: 'Wytnij' },
        { role: 'copy', label: 'Kopiuj' },
        { role: 'paste', label: 'Wklej' },
        { role: 'selectAll', label: 'Zaznacz wszystko' }
      ]
    },
    {
      label: 'Widok',
      submenu: [
        { role: 'reload', label: 'Odśwież' },
        { role: 'forceReload', label: 'Wymuś odświeżenie' },
        { role: 'toggleDevTools', label: 'Narzędzia deweloperskie' },
        { type: 'separator' },
        { role: 'resetZoom', label: 'Reset powiększenia' },
        { role: 'zoomIn', label: 'Powiększ' },
        { role: 'zoomOut', label: 'Pomniejsz' },
        { type: 'separator' },
        { role: 'togglefullscreen', label: 'Pełny ekran' }
      ]
    },
    {
      role: 'window',
      label: 'Okno',
      submenu: [
        { role: 'minimize', label: 'Minimalizuj' },
        { role: 'zoom', label: 'Powiększ okno' },
        ...(isMac ? [{ type: 'separator' }, { role: 'front', label: 'Na wierzch' }] : [{ role: 'close', label: 'Zamknij' }])
      ]
    },
    {
      label: 'Pomoc',
      submenu: [
        {
          label: 'Dokumentacja projektu (README)',
          click: () => {
            const readmePath = path.join(__dirname, '..', 'README.md');
            shell.openPath(readmePath);
          }
        }
      ]
    }
  ];

  Menu.setApplicationMenu(Menu.buildFromTemplate(template));
}

app.whenReady().then(() => {
  // Wymuszamy ikonę w Docku (szczególnie ważne przy uruchamianiu deweloperskim).
  if (isMac && app.dock) {
    const dockIcon = nativeImage.createFromPath(appIconPng);
    if (!dockIcon.isEmpty()) {
      app.dock.setIcon(dockIcon);
    }
  }

  createMenu();
  createMainWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createMainWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (!isMac) {
    app.quit();
  }
});
