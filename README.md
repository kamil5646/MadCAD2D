# MadCAD 2D

Desktopowa aplikacja CAD 2D (Windows/macOS) do projektowania konstrukcji stalowych: bramy, ogrodzenia, balkony.

## Linki

- Strona projektu (GitHub Pages): https://kamil5646.github.io/MadCAD2D/
- Repozytorium: https://github.com/kamil5646/MadCAD2D
- Release 1.0: https://github.com/kamil5646/MadCAD2D/releases/tag/1.0

## Pobieranie (Release 1.0)

- Windows: `MadCAD.2D-1.0.0-win-x64.exe`
- macOS: `MadCAD.2D-1.0.0-mac-x64.zip`

Pliki są dostępne w sekcji release:  
https://github.com/kamil5646/MadCAD2D/releases/tag/1.0

## Najważniejsze funkcje

- Wstążka narzędzi i polski interfejs.
- Narzędzia 2D: `Linia`, `Polilinia`, `Prostokąt`, `Okrąg`, `Pomiar`, `Wymiar`.
- Wymiarowanie: `Aligned`, `Linear`, `Rotated`, `Angular` (kątowe).
- SNAP i ORTHO, przyciąganie do punktów charakterystycznych.
- Edycja: `MOVE`, `COPY`, `OFFSET`, duplikacja, usuwanie, kolejność.
- Warstwy: aktywna warstwa, widoczność, blokady.
- Generator stali: szablony `Brama`, `Ogrodzenie`, `Balkon`.
- Import/eksport: `JSON`, `DXF`, `SVG`, oraz `Druk/PDF`.
- Menu `Zapisz/Drukuj` bezpośrednio w górnym pasku.

## Uruchomienie lokalne (dev)

```bash
npm ci
npm run dev
```

## Build aplikacji

```bash
# paczka katalogowa (lokalny test app)
npm run dist:dir

# macOS (dir)
npm run dist:mac

# Windows (instalator NSIS x64)
npm run dist:win

# oba targety jednocześnie
npm run dist
```

Artefakty trafiają do katalogu `release/`.

## Skróty klawiszowe

- `Z` - Zaznacz
- `L` - Linia
- `Y` - Polilinia
- `P` - Prostokąt
- `O` - Okrąg
- `M` - Pomiar
- `D` - Wymiar
- `F2` - Start/Model
- `F4` - zwiń/rozwiń wstążkę
- `F6` - ukryj/pokaż panele
- `F8` - ORTHO
- `G` - Siatka
- `Ctrl+Z` - Cofnij
- `Ctrl+Y` - Ponów
- `Ctrl+C` / `Ctrl+V` - kopiuj/wklej
- `Ctrl+S` - Zapisz JSON
- `Ctrl+P` - Druk/PDF

## Komendy CAD (przykłady)

- `mode start|draw|steel`
- `layout model|sheet1`
- `dimstyle [mm|cm|m] [prec] [text] [aligned|linear|rotated|angular] [#RRGGBB]`
- `dimension angular`
- `dimangular`
- `dimcolor #RRGGBB`
- `snap on|off|toggle`
- `grid on|off|toggle`
- `ortho on|off|toggle`
- `steel <brama|ogrodzenie|balkon> [szer] [wys]`

## Stack techniczny

- `Electron`
- `HTML/CSS/JavaScript`
- `electron-builder`
