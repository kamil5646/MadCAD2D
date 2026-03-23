# MadCAD Scan

Natywna aplikacja iOS do zbierania wymiarów pod produkt za pomocą LiDAR / RoomPlan i eksportu ich do pliku `*.madcad.json` dla desktopowego MadCAD.

## Co robi obecna wersja
- działa tylko na **iPhone Pro z LiDAR**
- prowadzi użytkownika przez tryby:
  - `Brama`
  - `Balkon`
  - `Ogrodzenie`
- używa **RoomPlan** jako warstwy pomocniczej do stabilizacji geometrii i sugestii wymiarów
- głównym rezultatem eksportu są:
  - potwierdzone wymiary produktu
  - podstawowe parametry montażowe
  - opcjonalna techniczna referencja ze skanu
- import do desktopowego MadCAD przez `Pliki -> Import pomiaru iPhone`

## Struktura aplikacji
- `Start`: wybór trybu pomiaru i lista ostatnich eksportów
- `Scan`: zbieranie kontekstu LiDAR dla produktu
- `Review`: potwierdzenie i korekta wymiarów produktu
- `Export`: zapis do Files albo Share Sheet

## Wymagania
- macOS z pełnym Xcode
- `xcodegen`
- iPhone Pro z LiDAR do realnych testów RoomPlan
- iOS 17+

## Build lokalny
```bash
cd madcad-ios
xcodegen generate
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project MadCADScan.xcodeproj -scheme MadCADScan \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build CODE_SIGNING_ALLOWED=NO
```

## Uruchomienie na prawdziwym iPhone Pro
1. Otwórz `madcad-ios/MadCADScan.xcodeproj` w Xcode.
2. W `Signing & Capabilities` ustaw swój Team i unikalny bundle id, jeśli będzie potrzebny.
3. Podłącz iPhone Pro z LiDAR.
4. Wybierz urządzenie jako target uruchomienia.
5. Uruchom appkę z Xcode.
6. Zezwól na dostęp do kamery i ruchu.

## Flow testowy na urządzeniu
1. wybierz `Brama`, `Balkon` albo `Ogrodzenie`
2. obejdź obszar produktu i pokaż krawędzie montażowe
3. przejdź do potwierdzenia wymiarów
4. sprawdź i popraw liczby w `Review`
5. `Zapisz do Files` lub `Udostępnij`
6. na desktopie MadCAD: `Pliki -> Import pomiaru iPhone`

Pełna checklista testu na prawdziwym iPhone Pro:
- [DEVICE-TEST-CHECKLIST.md](DEVICE-TEST-CHECKLIST.md)

## Format eksportu
Payload jest zgodny z desktopowym MadCAD i zawiera:
- `version`
- `exportedAt`
- `entities`
- `layers`
- `activeLayerId`
- `scanMeta`

Najważniejsze pola w `scanMeta`:
- `source = "madcad-scan-product"`
- `productMode`
- `measurements`
- opcjonalna techniczna `referencePlan`

## Ograniczenia obecnej wersji
- LiDAR pomaga, ale użytkownik nadal potwierdza finalne wymiary ręcznie
- brak pełnej punkt-po-punkcie miarki AR dla każdego wymiaru montażowego
- brak chmury i synchronizacji
- brak pełnego 3D w desktopowym MadCAD
- brak iPadów i zwykłych iPhone'ów bez LiDAR
