# MadCAD Scan - checklista testu na iPhone Pro

## Przygotowanie
1. Podłącz iPhone Pro z LiDAR do Maca.
2. Otwórz `madcad-ios/MadCADScan.xcodeproj` w Xcode.
3. Ustaw swój `Team` w `Signing & Capabilities`.
4. Upewnij się, że telefon ma włączone:
   - aparat
   - ruch i orientację
   - wystarczająco miejsca na pliki

## Uruchomienie
1. Wybierz fizyczny iPhone jako target.
2. Uruchom aplikację z Xcode.
3. Potwierdź dostęp do kamery.
4. Sprawdź, czy ekran startowy pokazuje:
   - tryby `Brama`, `Balkon`, `Ogrodzenie`
   - listę ostatnich eksportów
   - brak ekranu `unsupported device`

## Test pomiaru
1. Wybierz jeden z trybów produktu.
2. Obejdź obszar produktu powoli, pokazując krawędzie montażowe i kontekst.
3. Przejdź do potwierdzenia pomiaru.
4. W `Review` sprawdź:
   - czy główny nacisk jest na liczbach i parametrach produktu
   - czy nazwa projektu da się zmienić
   - czy techniczna referencja jest opcjonalna i schowana
   - czy wymiary można skorygować ręcznie

## Test eksportu
1. Wybierz `Zapisz do Files`.
2. Zapisz plik `*.madcad.json`.
3. Wróć i sprawdź też `Udostępnij`.
4. Wyślij plik przez AirDrop na Maca.

## Test importu do desktopowego MadCAD
1. Otwórz desktopowy MadCAD.
2. Wejdź w `Pliki`.
3. Użyj `Import pomiaru iPhone`.
4. Wybierz zapisany plik `*.madcad.json`.
5. Sprawdź:
   - czy MadCAD rozpoznaje tryb `Brama` / `Balkon` / `Ogrodzenie`
   - czy pojawia się wybór `wypełnij formularz` vs `generuj od razu`
   - czy formularz `Stal` dostaje poprawne wartości

## Kontrola jakości
1. Zmierz ręcznie 3-5 kluczowych wymiarów produktu.
2. Porównaj je z wartościami w `Review` i po imporcie do MadCAD.
3. Zapisz różnice w mm.
4. Jeśli odchyłki są duże, powtórz pomiar wolniej i pokaż więcej krawędzi montażowych.

## Kryterium zaliczenia obecnej wersji
- pomiar kończy się bez błędu
- eksportuje się poprawny `*.madcad.json`
- MadCAD otwiera plik bez błędu
- formularz `Stal` dostaje sensowne wartości
- użytkownik nie ma wrażenia, że głównym produktem jest plan pokoju z góry
