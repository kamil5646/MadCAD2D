# MadCAD 2D Desktop

![MadCAD 2D Banner](./docs/readme-banner.svg)

![Release](https://img.shields.io/github/v/release/kamil5646/MadCAD2D?display_name=tag&label=release)
![Platform](https://img.shields.io/badge/platform-macOS%20ARM64%20%7C%20Windows%20x64-1c7ed6)
![UI](https://img.shields.io/badge/interface-PL%20%2F%20EN-2f9e44)

MadCAD 2D to desktopowa aplikacja CAD 2D do szybkiego projektowania elementów technicznych i konstrukcji stalowych.

## Szybkie Linki
- Release `5.1`: https://github.com/kamil5646/MadCAD2D/releases/tag/5.1
- GitHub Pages: https://kamil5646.github.io/MadCAD2D/
- Dokumentacja aplikacji: [`auto-cad/README.md`](./auto-cad/README.md)

## PL
### Co to jest
MadCAD 2D łączy klasyczne narzędzia CAD 2D z gotowym workflow pod bramy, ogrodzenia i balkony.

### Najważniejsze możliwości
- Rysowanie: linia, polilinia, prostokąt, okrąg, pomiar, wymiarowanie.
- Wymiarowanie: tryby wyrównany, liniowy, obrócony i kątowy.
- Modyfikacje: przesuń, kopiuj, odsuń, duplikuj, warstwy, kolejność obiektów.
- Generator stali: szybkie szablony `brama`, `ogrodzenie`, `balkon`.
- Eksport i wydruk: `JSON`, `DXF`, `SVG`, `PDF`.
- Aktualizacje aplikacji z poziomu interfejsu.

### Pobieranie
- macOS (arm64): https://github.com/kamil5646/MadCAD2D/releases/download/5.1/MadCAD.2D-5.1-mac-arm64.zip
- Windows (x64): https://github.com/kamil5646/MadCAD2D/releases/download/5.1/MadCAD.2D-5.1-win-x64.exe

### Szybki Start (dev)
```bash
cd auto-cad
npm install
npm run dev
```

### Build
```bash
cd auto-cad
npm run dist:release:trusted
```

### Struktura repo
- `auto-cad/` - główny kod aplikacji desktop (Electron + UI CAD).
- `docs/` - strona projektu na GitHub Pages.
- katalog główny - pliki prawne i organizacyjne.

---

## EN
### What It Is
MadCAD 2D is a desktop 2D CAD app focused on technical drawing and steel-structure workflows.

### Key Features
- Drawing tools: line, polyline, rectangle, circle, measure, dimension.
- Dimensioning modes: aligned, linear, rotated, angular.
- Editing: move, copy, offset, duplicate, layers, object order.
- Steel generator templates: `gate`, `fence`, `balcony`.
- Export and print: `JSON`, `DXF`, `SVG`, `PDF`.
- Built-in update flow from the app UI.

### Download
- macOS (arm64): https://github.com/kamil5646/MadCAD2D/releases/download/5.1/MadCAD.2D-5.1-mac-arm64.zip
- Windows (x64): https://github.com/kamil5646/MadCAD2D/releases/download/5.1/MadCAD.2D-5.1-win-x64.exe

### Quick Start (dev)
```bash
cd auto-cad
npm install
npm run dev
```

### Build
```bash
cd auto-cad
npm run dist:release:trusted
```

### Repository Layout
- `auto-cad/` - main desktop app code (Electron + CAD UI).
- `docs/` - project website hosted on GitHub Pages.
- repository root - legal and project files.

## License
Projekt korzysta z licencji niestandardowej:
- [`LICENSE`](./LICENSE)
