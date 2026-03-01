# MadCAD 2D Desktop

Desktopowa aplikacja CAD 2D (Mac/Windows) MadCAD 2D, z naciskiem na projektowanie konstrukcji stalowych: bramy, ogrodzenia, balkony.

## About

MadCAD 2D to lekka aplikacja desktopowa CAD 2D dla warsztatów i projektantów konstrukcji stalowych.
Projekt skupia się na szybkim rysowaniu, wymiarowaniu i generowaniu elementów takich jak bramy, ogrodzenia i balkony.

Aktualne wydanie `1.0`:

- Windows installer: `MadCAD.2D-1.0.0-win-x64.exe`
- macOS package: `MadCAD.2D-1.0.0-mac-x64.zip`
- Release: `https://github.com/kamil5646/MadCAD2D/releases/tag/1.0`

## Najważniejsze funkcje

- Wstążka (Ribbon) z logiką trybów: `Start`, `Rysowanie 2D`, `Generator stali`.
- Rysowanie 2D: `Linia`, `Polilinia`, `Prostokąt`, `Okrąg`.
- Wymiarowanie: `DIM Aligned`, `DIM Linear`, `DIM Rotated`, `DIM Angular` (kątowy), jednostki, precyzja, rozmiar i kolor DIM.
- SNAP do siatki i obiektów (końce, środki, narożniki, krawędzie).
- Modyfikacje: `MOVE`, `COPY`, `OFFSET`, duplikacja, usuwanie, kolejność.
- Warstwy: aktywna warstwa, widoczność, blokady, tworzenie/usuwanie.
- Generator stali: brama / ogrodzenie / balkon z parametrami w mm.
- Import/eksport: JSON, DXF, SVG oraz druk/PDF.

## Uruchomienie desktop (dev)

1. Wejdź do katalogu projektu:

```bash
cd /Users/kamilkasprzak/Documents/inne
```

2. Zainstaluj zależności:

```bash
npm install
```

3. Uruchom aplikację desktop:

```bash
npm run dev
```

## Build aplikacji

### macOS

```bash
npm run dist:mac
```

Wynik:

- gotowa aplikacja `.app` w katalogu `release/mac-*/MadCAD 2D.app`

### Windows

```bash
npm run dist:win
```

Wynik:

- instalator `.exe` (NSIS) w katalogu `release/`

### Jednocześnie (Mac/Windows/Linux)

```bash
npm run dist
```

Artefakty builda trafiają do katalogu `release/`.

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
- `G` - GRID
- `Ctrl+Z` - Cofnij
- `Ctrl+Y` - Ponów
- `Ctrl+C` / `Ctrl+V` - kopiuj/wklej
- `Ctrl+S` - zapisz JSON
- `Ctrl+P` - druk/PDF

## Komendy (skrótowe)

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

- `Electron` (shell desktop na Mac/Windows)
- `HTML/CSS/JS` (renderer CAD)
- `electron-builder` (pakowanie instalatorów)
