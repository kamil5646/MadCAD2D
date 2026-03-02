# MadCAD 2D Desktop

Desktopowa aplikacja CAD 2D (Mac/Windows) MadCAD 2D, z naciskiem na projektowanie konstrukcji stalowych: bramy, ogrodzenia, balkony.

## Wydanie 2.0

Aktualne pliki instalacyjne znajdziesz w release `2.0`:

- PL macOS: https://github.com/kamil5646/MadCAD2D/releases/download/2.0/MadCAD.2D-2.0.0-pl-mac-arm64.zip
- PL Windows: https://github.com/kamil5646/MadCAD2D/releases/download/2.0/MadCAD.2D-2.0.0-pl-win-x64.exe
- EN macOS: https://github.com/kamil5646/MadCAD2D/releases/download/2.0/MadCAD.2D-2.0.0-en-mac-arm64.zip
- EN Windows: https://github.com/kamil5646/MadCAD2D/releases/download/2.0/MadCAD.2D-2.0.0-en-win-x64.exe
- Strona release: https://github.com/kamil5646/MadCAD2D/releases/tag/2.0

## Struktura repo

- `auto-cad/` - główny kod aplikacji desktop (to katalog, z którego uruchamiasz build i dev)
- `docs/` - strona projektu / dokumentacja publikowana na GitHub Pages
- katalog główny repo - dokumenty prawne i organizacyjne projektu

## Najważniejsze funkcje

- Wstążka (Ribbon) z zakładkami: `Główne`, `Wymiarowanie`, `Stal`, `Układ`, `Widok`, `Skróty`.
- Rysowanie 2D: `Linia`, `Polilinia`, `Prostokąt`, `Okrąg`.
- Wymiarowanie: `DIM Aligned`, `DIM Linear`, jednostki, precyzja, rozmiar i kolor DIM.
- SNAP do siatki i obiektów (końce, środki, narożniki, krawędzie).
- Modyfikacje: `MOVE`, `COPY`, `OFFSET`, duplikacja, usuwanie, kolejność.
- Warstwy: aktywna warstwa, widoczność, blokady, tworzenie/usuwanie.
- Generator stali: brama / ogrodzenie / balkon z parametrami w mm.
- Import/eksport: JSON, DXF, SVG oraz druk/PDF.

## Gdy aplikacja nie działa

### macOS (jeden krok naprawczy)

Jeśli pojawia się komunikat „Rzecz jest uszkodzona i nie można jej otworzyć”, wklej w Terminal:

```bash
xattr -dr com.apple.quarantine "/Applications/MadCAD 2D.app" && open -a "/Applications/MadCAD 2D.app"
```

### Windows

Jeśli instalator jest blokowany, uruchom PowerShell jako administrator i wklej:

```powershell
Unblock-File "$env:USERPROFILE\Downloads\MadCAD.2D-2.0.0-pl-win-x64.exe"; Start-Process "$env:USERPROFILE\Downloads\MadCAD.2D-2.0.0-pl-win-x64.exe" -Verb RunAs
```

Dla wersji angielskiej podmień nazwę pliku na `MadCAD.2D-2.0.0-en-win-x64.exe`.

Jeśli SmartScreen nadal pyta, wybierz: `Więcej informacji` -> `Uruchom mimo to`.

## Skróty klawiszowe

- `Z` - Zaznacz
- `L` - Linia
- `Y` - Polilinia
- `P` - Prostokąt
- `O` - Okrąg
- `M` - Pomiar
- `D` - Wymiar
- `F2` - zakładka `Skróty`
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

- `mode draw|steel`
- `tab główne|wymiarowanie|stal|układ|widok|skróty`
- `layout model|sheet1`
- `dimstyle [mm|cm|m] [prec] [text] [aligned|linear] [#RRGGBB]`
- `dimcolor #RRGGBB`
- `snap on|off|toggle`
- `grid on|off|toggle`
- `ortho on|off|toggle`
- `steel <brama|ogrodzenie|balkon> [szer] [wys]`

## Stack techniczny

- `Electron` (shell desktop na Mac/Windows)
- `HTML/CSS/JS` (renderer CAD)
- `electron-builder` (pakowanie instalatorów)

## Licencja

Projekt jest objęty licencją niestandardową (używanie dozwolone, modyfikacje zabronione):

- [`LICENSE`](./LICENSE)
