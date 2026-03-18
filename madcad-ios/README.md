# MadCAD Scan

Natywna aplikacja iOS do skanowania pomieszczeń za pomocą LiDAR / RoomPlan i eksportu planu 2D do pliku `*.madcad.json`.

## Co robi v1
- działa tylko na **iPhone Pro z LiDAR**
- skanuje pomieszczenie przez **RoomPlan**
- eksportuje 2D do MadCAD jako:
  - `line` dla ścian
  - `rect` dla otworów
  - `dimension` dla długości ścian
- import do desktopowego MadCAD przez `Pliki -> Wczytaj JSON`

## Struktura aplikacji
- `Start`: nowy skan i lista ostatnich eksportów
- `Scan`: live capture przez `RoomCaptureView`
- `Review`: podgląd uproszczonego planu 2D i liczby ścian / otworów / wymiarów
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
1. `Nowy skan`
2. obejdź ściany, drzwi i okna
3. `Zakończ skan`
4. sprawdź podgląd w `Review`
5. `Zapisz do Files` lub `Udostępnij`
6. na desktopie MadCAD: `Pliki -> Import skanu iPhone` albo `Pliki -> Wczytaj JSON`

Pelna checklista testu na prawdziwym iPhone Pro:
- [DEVICE-TEST-CHECKLIST.md](DEVICE-TEST-CHECKLIST.md)

## Format eksportu
Payload jest zgodny z desktopowym MadCAD i zawiera:
- `version`
- `exportedAt`
- `entities`
- `layers`
- `activeLayerId`
- opcjonalne `scanMeta`

## Warstwy eksportu
- `ŚCIANY`
- `OTWORY`
- `WYMIARY`

## Ograniczenia v1
- brak ręcznej miarki AR punkt-punkt
- brak chmury i synchronizacji
- brak pełnego 3D w desktopowym MadCAD
- brak iPadów i zwykłych iPhone'ów bez LiDAR
