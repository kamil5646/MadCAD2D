const path = require('path');
const fs = require('fs/promises');
const { app, BrowserWindow, Menu, shell, nativeImage, dialog, ipcMain } = require('electron');

const isMac = process.platform === 'darwin';
const appIconPng = path.join(__dirname, '..', 'assets', 'icons', 'madcad-512.png');

async function handleSavePromptBeforeExit(win) {
  const response = await dialog.showMessageBox(win, {
    type: 'question',
    buttons: ['Zapisz i wyjdź', 'Wyjdź bez zapisu', 'Anuluj'],
    defaultId: 0,
    cancelId: 2,
    noLink: true,
    title: 'Zamykanie MadCAD 2D',
    message: 'Czy chcesz zapisać rysunek przed wyjściem?',
    detail: 'Po zamknięciu sesja robocza zostanie wyczyszczona.'
  });

  if (response.response === 2) {
    return false;
  }

  if (response.response === 0) {
    let exportedText = '';
    try {
      exportedText = await win.webContents.executeJavaScript(
        'window.__madcadGetSessionExport ? window.__madcadGetSessionExport() : ""',
        true
      );
    } catch (_error) {
      await dialog.showMessageBox(win, {
        type: 'error',
        title: 'Błąd zapisu',
        message: 'Nie udało się przygotować danych do zapisu.'
      });
      return false;
    }

    const saveResult = await dialog.showSaveDialog(win, {
      title: 'Zapisz rysunek przed wyjściem',
      defaultPath: path.join(app.getPath('documents'), 'rysunek.json'),
      filters: [{ name: 'JSON', extensions: ['json'] }],
      properties: ['createDirectory', 'showOverwriteConfirmation']
    });

    if (saveResult.canceled || !saveResult.filePath) {
      return false;
    }

    try {
      await fs.writeFile(saveResult.filePath, String(exportedText || ''), 'utf8');
    } catch (_error) {
      await dialog.showMessageBox(win, {
        type: 'error',
        title: 'Błąd zapisu',
        message: 'Nie udało się zapisać pliku.'
      });
      return false;
    }
  }

  try {
    await win.webContents.executeJavaScript(
      'window.__madcadClearRuntimeSession && window.__madcadClearRuntimeSession();',
      true
    );
  } catch (_error) {}

  return true;
}

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
          titleBarStyle: 'hiddenInset'
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

  let closeApproved = false;
  win.on('close', (event) => {
    if (closeApproved) {
      return;
    }
    event.preventDefault();
    void (async () => {
      if (win.isDestroyed()) {
        return;
      }
      const canClose = await handleSavePromptBeforeExit(win);
      if (!canClose || win.isDestroyed()) {
        return;
      }
      closeApproved = true;
      win.close();
    })();
  });

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

ipcMain.handle('madcad:save-text-file', async (event, payload) => {
  try {
    const senderWindow = BrowserWindow.fromWebContents(event.sender) || null;
    const defaultName =
      payload && typeof payload.defaultName === 'string' && payload.defaultName.trim()
        ? payload.defaultName.trim()
        : 'rysunek.txt';
    const text = payload && typeof payload.text === 'string' ? payload.text : '';
    const filters = Array.isArray(payload && payload.filters) ? payload.filters : [];

    const result = await dialog.showSaveDialog(senderWindow, {
      title: 'Zapisz plik',
      defaultPath: defaultName,
      filters,
      properties: ['createDirectory', 'showOverwriteConfirmation']
    });

    if (result.canceled || !result.filePath) {
      return { ok: false, canceled: true };
    }

    await fs.writeFile(result.filePath, text, 'utf8');
    return { ok: true, canceled: false, filePath: result.filePath };
  } catch (error) {
    return {
      ok: false,
      canceled: false,
      error: error && error.message ? String(error.message) : 'Nieznany błąd zapisu'
    };
  }
});

function getPrivateLicenseAuditPath() {
  const userDataDir = app.getPath('userData');
  return path.join(userDataDir, 'private', 'license-audit.jsonl');
}

ipcMain.handle('madcad:append-license-audit', async (_event, payload) => {
  try {
    const safePayload = payload && typeof payload === 'object' ? payload : {};
    const entry = {
      at: new Date().toISOString(),
      type: String(safePayload.type || 'akcja'),
      details: String(safePayload.details || ''),
      meta: safePayload.meta && typeof safePayload.meta === 'object' ? safePayload.meta : {}
    };
    const auditPath = getPrivateLicenseAuditPath();
    await fs.mkdir(path.dirname(auditPath), { recursive: true });
    await fs.appendFile(auditPath, `${JSON.stringify(entry)}\n`, 'utf8');
    return { ok: true, path: auditPath };
  } catch (error) {
    return {
      ok: false,
      error: error && error.message ? String(error.message) : 'Nieznany błąd zapisu audytu'
    };
  }
});

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
