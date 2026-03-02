# MadCAD 2D Desktop

MadCAD 2D is a desktop 2D CAD application (macOS/Windows) focused on steel structure design: gates, fences, and balconies.

## Release 2.0

Current installers are available in release `2.0`:

- PL macOS: https://github.com/kamil5646/MadCAD2D/releases/download/2.0/MadCAD.2D-2.0.0-pl-mac-arm64.zip
- PL Windows: https://github.com/kamil5646/MadCAD2D/releases/download/2.0/MadCAD.2D-2.0.0-pl-win-x64.exe
- EN macOS: https://github.com/kamil5646/MadCAD2D/releases/download/2.0/MadCAD.2D-2.0.0-en-mac-arm64.zip
- EN Windows: https://github.com/kamil5646/MadCAD2D/releases/download/2.0/MadCAD.2D-2.0.0-en-win-x64.exe
- Release page: https://github.com/kamil5646/MadCAD2D/releases/tag/2.0

## Repository structure

- `auto-cad/` - main desktop app source code (build and dev commands are run from here)
- `docs/` - project website / GitHub Pages documentation
- repository root - legal and organizational project files

## Key features

- Ribbon-based workflow for drawing, dimensioning, steel generation and view controls.
- 2D drawing: line, polyline, rectangle, circle.
- Dimensioning: aligned/linear/rotated/angular modes.
- Editing: move, copy, offset, duplicate, delete, z-order.
- Layer support: active layer, visibility, lock/unlock.
- Steel generator: gate / fence / balcony templates.
- Import/export: JSON, DXF, SVG and print/PDF.

## If the app is blocked by the OS

### macOS

If macOS shows a damaged-app warning, run:

```bash
xattr -dr com.apple.quarantine "/Applications/MadCAD 2D.app" && open -a "/Applications/MadCAD 2D.app"
```

### Windows

If the installer is blocked, run PowerShell as administrator and execute:

```powershell
Unblock-File "$env:USERPROFILE\Downloads\MadCAD.2D-2.0.0-en-win-x64.exe"; Start-Process "$env:USERPROFILE\Downloads\MadCAD.2D-2.0.0-en-win-x64.exe" -Verb RunAs
```

For Polish installer, replace filename with `MadCAD.2D-2.0.0-pl-win-x64.exe`.

## Tech stack

- `Electron`
- `HTML/CSS/JavaScript`
- `electron-builder`

## License

This project uses a custom license (usage allowed, modifications forbidden):

- [`LICENSE`](./LICENSE)
