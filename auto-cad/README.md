# MadCAD 2D Desktop

Desktopowa aplikacja CAD 2D (Mac/Windows) MadCAD 2D, z naciskiem na projektowanie konstrukcji stalowych: bramy, ogrodzenia, balkony.

## Wydanie 3.1.1

Aktualne pliki instalacyjne znajdziesz w release `3.1.1`:

- macOS (arm64): https://github.com/kamil5646/MadCAD2D/releases/download/3.1.1/MadCAD.2D-3.1.1-mac-arm64.zip
- Windows (x64): https://github.com/kamil5646/MadCAD2D/releases/download/3.1.1/MadCAD.2D-3.1.1-win-x64.exe
- Strona release: https://github.com/kamil5646/MadCAD2D/releases/tag/3.1.1

## Struktura repo

- `auto-cad/` - główny kod aplikacji desktop (to katalog, z którego uruchamiasz build i dev)
- `docs/` - strona projektu / dokumentacja publikowana na GitHub Pages
- katalog główny repo - dokumenty prawne i organizacyjne projektu

## Najważniejsze funkcje

- Wstążka z zakładkami: `Główne`, `Wymiarowanie`, `Stal`, `Widok`, `Warstwy`, `Skróty`.
- Rysowanie: `Linia`, `Polilinia`, `Prostokąt/Kwadrat`, `Okrąg`, `Pomiar`, `Wymiar`.
- Przyciąganie: jeden tryb `SNAP` (punkty + krawędzie) + siatka i tryb `Poziom/Pion`.
- Modyfikacje: `Przesuń`, `Kopiuj`, `Odsuń`, `Duplikuj`, `Usuń`, `Na wierzch/Na spod`.
- Warstwy: aktywna warstwa, widoczność, blokada, dodawanie i zarządzanie listą warstw.
- Konstrukcje stalowe: generator bramy/ogrodzenia/balkonu z parametrami mm.
- Import/eksport: JSON, DXF, SVG oraz druk/PDF.
- Okno kontekstowe figur: konfiguracja prostokąta i okręgu zależna od aktywnego narzędzia/zaznaczenia.

## Uruchomienie desktop (dev)

1. Wejdź do katalogu aplikacji:

```bash
cd auto-cad
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

Wszystkie komendy build uruchamiaj z katalogu `auto-cad`.

### macOS

```bash
npm run dist:mac
```

Wynik:

- gotowa aplikacja `.app` w katalogu `release/mac-*/MadCAD 2D.app`

### Build wariantów językowych (PL/EN)

```bash
# PL
APP_LANG=pl npx electron-builder --mac zip --arm64 --publish never --config.productName="MadCAD 2D PL" --config.appId="pl.kamilkasprzak.madcad2d.pl" --config.artifactName='MadCAD.2D-${version}-pl-${os}-${arch}.${ext}'
APP_LANG=pl npx electron-builder --win nsis --x64 --publish never --config.productName="MadCAD 2D PL" --config.appId="pl.kamilkasprzak.madcad2d.pl" --config.artifactName='MadCAD.2D-${version}-pl-${os}-${arch}.${ext}'

# EN
APP_LANG=en npx electron-builder --mac zip --arm64 --publish never --config.productName="MadCAD 2D EN" --config.appId="pl.kamilkasprzak.madcad2d.en" --config.artifactName='MadCAD.2D-${version}-en-${os}-${arch}.${ext}'
APP_LANG=en npx electron-builder --win nsis --x64 --publish never --config.productName="MadCAD 2D EN" --config.appId="pl.kamilkasprzak.madcad2d.en" --config.artifactName='MadCAD.2D-${version}-en-${os}-${arch}.${ext}'
```

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

## Zaufane wydanie (bez ostrzeżeń systemu)

Aby użytkownicy nie dostawali ostrzeżeń o niezaufanej aplikacji, wymagane są:

- macOS: `Developer ID Application` + notaryzacja Apple
- Windows: certyfikat podpisu kodu (OV/EV) do podpisania instalatora `.exe`

Ustaw zmienne środowiskowe przed buildem:

```bash
export APPLE_ID="twoj-apple-id@example.com"
export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
export APPLE_TEAM_ID="TEAMID1234"

# certyfikat podpisu (macOS i/lub Windows)
export CSC_LINK="/sciezka/do/certyfikatu.p12"
export CSC_KEY_PASSWORD="haslo_do_certyfikatu"
```

Uruchom build z podpisem:

```bash
npm run dist:release:trusted
```

Skrypty wykonują podpisanie i notaryzację dla macOS oraz podpisanie instalatora Windows (jeśli certyfikat jest dostępny).

## Gdy aplikacja nie działa

### macOS (jeden krok naprawczy)

Jeśli pojawia się komunikat „Rzecz jest uszkodzona i nie można jej otworzyć”, wklej w Terminal:

```bash
xattr -dr com.apple.quarantine "/Applications/MadCAD 2D.app" && open -a "/Applications/MadCAD 2D.app"
```

### Windows

Jeśli instalator jest blokowany, uruchom PowerShell jako administrator i wklej:

```powershell
Unblock-File "$env:USERPROFILE\Downloads\MadCAD.2D-3.1.1-win-x64.exe"; Start-Process "$env:USERPROFILE\Downloads\MadCAD.2D-3.1.1-win-x64.exe" -Verb RunAs
```

Jeśli SmartScreen nadal pyta, wybierz: `Więcej informacji` -> `Uruchom mimo to`.

## Ręczna instalacja ODA (DWG)

Jeśli automatyczna instalacja ODA nie działa (np. problem sieci/DNS), możesz skonfigurować konwerter ręcznie.

1. Otwórz w aplikacji `Zapisz/Drukuj (Alt+S)`.
2. Kliknij pozycję DWG: `Brakuje dodatku DWG — zainstaluj (...)`.
3. Wskaż plik wykonywalny `ODAFileConverter`.

### Ścieżki domyślne

- macOS:
	- `/Applications/ODAFileConverter.app/Contents/MacOS/ODAFileConverter`
	- `/Applications/ODA File Converter.app/Contents/MacOS/ODAFileConverter`
- Windows:
	- `C:\Program Files\ODA\ODAFileConverter\ODAFileConverter.exe`
	- `C:\Program Files (x86)\ODA\ODAFileConverter\ODAFileConverter.exe`

### Gdy nie masz jeszcze ODA

- Pobierz instalator ze strony ODA File Converter: https://www.opendesign.com/guestfiles/oda_file_converter
- Zainstaluj ODA, uruchom ponownie MadCAD 2D i ponów wskazanie pliku `ODAFileConverter`.

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
- `F3` - Przyciąganie (SNAP)
- `F8` - Poziom/Pion
- `G` - Siatka
- `Ctrl+Z` - Cofnij
- `Ctrl+Y` - Ponów
- `Ctrl+C` / `Ctrl+V` - kopiuj/wklej
- `Ctrl+O` - wczytaj JSON
- `Ctrl+S` - zapisz JSON
- `Ctrl+P` - druk/PDF

### Dodatkowe skróty (Alt)

- `Alt+M` Przesuń
- `Alt+C` Kopiuj
- `Alt+F` Odsuń
- `Alt+J` Na wierzch
- `Alt+K` Na spod
- `Alt+0` Dopasuj widok
- `Alt+Delete` Wyczyść rysunek
- `Alt+1..4` tryby wymiarowania
- `Alt+I/E/V` import/eksport DXF/SVG
- `Alt+N` dodaj warstwę
- `Alt+Enter` generuj konstrukcję

## Komendy (skrótowe)

- `mode draw|steel`
- `tab główne|wymiarowanie|stal|widok|warstwy|skróty`
- `dimstyle [mm|cm|m] [prec] [text] [aligned|linear] [#RRGGBB]`
- `dimcolor #RRGGBB`
- `snap on|off|toggle`
- `grid on|off|toggle`
- `ortho on|off|toggle` (Poziom/Pion)
- `steel <brama|ogrodzenie|balkon> [szer] [wys]`

## Stack techniczny

- `Electron` (shell desktop na Mac/Windows)
- `HTML/CSS/JS` (renderer CAD)
- `electron-builder` (pakowanie instalatorów)

## Licencja

Projekt jest objęty licencją niestandardową (używanie dozwolone, modyfikacje zabronione):

- [`LICENSE`](./LICENSE)
