const path = require('path');
const fs = require('fs/promises');
const { app, BrowserWindow, Menu, shell, nativeImage, dialog, ipcMain } = require('electron');

const isMac = process.platform === 'darwin';
const appIconPng = path.join(__dirname, '..', 'assets', 'icons', 'madcad-512.png');

function resolveAppLanguage() {
  if (process.env.APP_LANG === 'en') {
    return 'en';
  }
  if (process.env.APP_LANG === 'pl') {
    return 'pl';
  }
  const appName = String(app.getName() || '').toLowerCase();
  if (appName.includes(' en')) {
    return 'en';
  }
  if (appName.includes(' pl')) {
    return 'pl';
  }
  return 'pl';
}

const t = (pl, en) => (resolveAppLanguage() === 'en' ? en : pl);

async function handleSavePromptBeforeExit(win) {
  const response = await dialog.showMessageBox(win, {
    type: 'question',
    buttons: [t('Zapisz i wyjdź', 'Save and Exit'), t('Wyjdź bez zapisu', 'Exit Without Saving'), t('Anuluj', 'Cancel')],
    defaultId: 0,
    cancelId: 2,
    noLink: true,
    title: t('Zamykanie MadCAD 2D', 'Closing MadCAD 2D'),
    message: t('Czy chcesz zapisać rysunek przed wyjściem?', 'Do you want to save the drawing before exit?'),
    detail: t('Po zamknięciu sesja robocza zostanie wyczyszczona.', 'The current runtime session will be cleared after closing.')
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
        title: t('Błąd zapisu', 'Save Error'),
        message: t('Nie udało się przygotować danych do zapisu.', 'Failed to prepare drawing data for saving.')
      });
      return false;
    }

    const saveResult = await dialog.showSaveDialog(win, {
      title: t('Zapisz rysunek przed wyjściem', 'Save Drawing Before Exit'),
      defaultPath: path.join(app.getPath('documents'), appLanguage === 'en' ? 'drawing.json' : 'rysunek.json'),
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
        title: t('Błąd zapisu', 'Save Error'),
        message: t('Nie udało się zapisać pliku.', 'Failed to save file.')
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
  const appLanguage = resolveAppLanguage();
  const win = new BrowserWindow({
    width: 1680,
    height: 980,
    minWidth: 1200,
    minHeight: 760,
    backgroundColor: '#111b29',
    title: appLanguage === 'en' ? 'MadCAD 2D EN' : 'MadCAD 2D PL',
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
      devTools: true,
      additionalArguments: [`--madcad-lang=${appLanguage}`]
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
      label: t('Plik', 'File'),
      submenu: [
        {
          label: t('Nowy rysunek', 'New drawing'),
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
        { role: isMac ? 'close' : 'quit', label: isMac ? t('Zamknij okno', 'Close window') : t('Wyjście', 'Exit') }
      ]
    },
    {
      label: t('Edycja', 'Edit'),
      submenu: [
        { role: 'undo', label: t('Cofnij', 'Undo') },
        { role: 'redo', label: t('Ponów', 'Redo') },
        { type: 'separator' },
        { role: 'cut', label: t('Wytnij', 'Cut') },
        { role: 'copy', label: t('Kopiuj', 'Copy') },
        { role: 'paste', label: t('Wklej', 'Paste') },
        { role: 'selectAll', label: t('Zaznacz wszystko', 'Select all') }
      ]
    },
    {
      label: t('Widok', 'View'),
      submenu: [
        { role: 'reload', label: t('Odśwież', 'Reload') },
        { role: 'forceReload', label: t('Wymuś odświeżenie', 'Force reload') },
        { role: 'toggleDevTools', label: t('Narzędzia deweloperskie', 'Developer tools') },
        { type: 'separator' },
        { role: 'resetZoom', label: t('Reset powiększenia', 'Reset zoom') },
        { role: 'zoomIn', label: t('Powiększ', 'Zoom in') },
        { role: 'zoomOut', label: t('Pomniejsz', 'Zoom out') },
        { type: 'separator' },
        { role: 'togglefullscreen', label: t('Pełny ekran', 'Full screen') }
      ]
    },
    {
      role: 'window',
      label: t('Okno', 'Window'),
      submenu: [
        { role: 'minimize', label: t('Minimalizuj', 'Minimize') },
        { role: 'zoom', label: t('Powiększ okno', 'Zoom window') },
        ...(isMac
          ? [{ type: 'separator' }, { role: 'front', label: t('Na wierzch', 'Bring all to front') }]
          : [{ role: 'close', label: t('Zamknij', 'Close') }])
      ]
    },
    {
      label: t('Pomoc', 'Help'),
      submenu: [
        {
          label: t('Dokumentacja projektu (README)', 'Project documentation (README)'),
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
        : appLanguage === 'en'
        ? 'drawing.txt'
        : 'rysunek.txt';
    const text = payload && typeof payload.text === 'string' ? payload.text : '';
    const filters = Array.isArray(payload && payload.filters) ? payload.filters : [];

    const result = await dialog.showSaveDialog(senderWindow, {
      title: t('Zapisz plik', 'Save file'),
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
      error: error && error.message ? String(error.message) : t('Nieznany błąd zapisu', 'Unknown save error')
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
      error: error && error.message ? String(error.message) : t('Nieznany błąd zapisu audytu', 'Unknown audit save error')
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
