# MadCAD 2D Desktop

MadCAD 2D is a desktop 2D CAD application (macOS/Windows) focused on steel structure design: gates, fences, and balconies.

## Release 3.0

Current installers are available in release `3.0`:

- macOS (arm64): https://github.com/kamil5646/MadCAD2D/releases/download/3.0/MadCAD.2D-3.0.0-mac-arm64.zip
- Windows (x64): https://github.com/kamil5646/MadCAD2D/releases/download/3.0/MadCAD.2D-3.0.0-win-x64.exe
- Release page: https://github.com/kamil5646/MadCAD2D/releases/tag/3.0

## Quick start (desktop dev)

```bash
cd auto-cad
npm install
npm run dev
```

## Build

Run build commands from `auto-cad` directory.

### Standard build

```bash
npm run dist:mac
npm run dist:win
```

### Language variants (PL/EN)

```bash
# PL
APP_LANG=pl npx electron-builder --mac zip --arm64 --publish never --config.productName="MadCAD 2D PL" --config.appId="pl.kamilkasprzak.madcad2d.pl" --config.artifactName='MadCAD.2D-${version}-pl-${os}-${arch}.${ext}'
APP_LANG=pl npx electron-builder --win nsis --x64 --publish never --config.productName="MadCAD 2D PL" --config.appId="pl.kamilkasprzak.madcad2d.pl" --config.artifactName='MadCAD.2D-${version}-pl-${os}-${arch}.${ext}'

# EN
APP_LANG=en npx electron-builder --mac zip --arm64 --publish never --config.productName="MadCAD 2D EN" --config.appId="pl.kamilkasprzak.madcad2d.en" --config.artifactName='MadCAD.2D-${version}-en-${os}-${arch}.${ext}'
APP_LANG=en npx electron-builder --win nsis --x64 --publish never --config.productName="MadCAD 2D EN" --config.appId="pl.kamilkasprzak.madcad2d.en" --config.artifactName='MadCAD.2D-${version}-en-${os}-${arch}.${ext}'
```

## Trusted release (without OS warnings)

To avoid trust warnings for end users:

- macOS: `Developer ID Application` + Apple notarization
- Windows: code signing certificate (OV/EV)

Signed build script:

```bash
npm run dist:release:trusted
```

## If the app is blocked by the OS

### macOS

```bash
xattr -dr com.apple.quarantine "/Applications/MadCAD 2D.app" && open -a "/Applications/MadCAD 2D.app"
```

### Windows

```powershell
Unblock-File "$env:USERPROFILE\Downloads\MadCAD.2D-3.0.0-win-x64.exe"; Start-Process "$env:USERPROFILE\Downloads\MadCAD.2D-3.0.0-win-x64.exe" -Verb RunAs
```

## License

This project uses a custom license (usage allowed, modifications forbidden):

- [`LICENSE`](./LICENSE)
