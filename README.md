# MadCAD 2D Desktop

Desktopowa aplikacja CAD 2D (Mac/Windows) MadCAD 2D, z naciskiem na projektowanie konstrukcji stalowych: bramy, ogrodzenia, balkony.

## Najważniejsze funkcje

- Wstążka (Ribbon) z logiką trybów: `Start`, `Rysowanie 2D`, `Generator stali`.
- Rysowanie 2D: `Linia`, `Polilinia`, `Prostokąt`, `Okrąg`.
- Wymiarowanie: `DIM Aligned`, `DIM Linear`, jednostki, precyzja, rozmiar i kolor DIM.
- SNAP do siatki i obiektów (końce, środki, narożniki, krawędzie).
- Modyfikacje: `MOVE`, `COPY`, `OFFSET`, duplikacja, usuwanie, kolejność.
- Warstwy: aktywna warstwa, widoczność, blokady, tworzenie/usuwanie.
- Generator stali: brama / ogrodzenie / balkon z parametrami w mm.
- Import/eksport: JSON, DXF, SVG oraz druk/PDF.

## Uruchomienie desktop (dev)

1. Wejdź do katalogu projektu:

```bash
cd /Users/kamilkasprzak/Documents/inne/auto-cad
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

## Licencja i aktywacja

Projekt jest objęty licencją niestandardową: [`LICENSE.md`](./LICENSE.md).

Najważniejsze zasady:

- Użytek prywatny: dozwolony, bezpłatny, po aktywacji tokenem prywatnym.
- Modyfikacje aplikacji: niedozwolone.
- Użytek komercyjny: wymaga datku 50 USD za każde urządzenie (1 licencja = 1 urządzenie).

### Token prywatny (darmowy)

Po uruchomieniu aplikacji pojawia się ekran aktywacji:

1. Skopiuj `ID urządzenia` z okna aktywacji.
2. Otwórz formularz na stronie GitHub Pages: `https://kamil5646.github.io/MadCAD2D/#token-prywatny`.
3. Wygeneruj token prywatny na stronie.
4. Wklej token w aplikacji i kliknij `Aktywuj token`.

Token jest przypisany do ID urządzenia i zapisywany lokalnie.
