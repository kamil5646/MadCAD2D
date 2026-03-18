# MadCAD Scan - checklista testu na iPhone Pro

## Przygotowanie
1. Podlacz iPhone Pro z LiDAR do Maca.
2. Otworz `madcad-ios/MadCADScan.xcodeproj` w Xcode.
3. Ustaw swoj `Team` w `Signing & Capabilities`.
4. Upewnij sie, ze telefon ma wlaczone:
   - aparat
   - ruch i orientacje
   - wystarczajaco miejsca na pliki

## Uruchomienie
1. Wybierz fizyczny iPhone jako target.
2. Uruchom aplikacje z Xcode.
3. Potwierdz dostep do kamery.
4. Sprawdz, czy ekran startowy pokazuje:
   - `Nowy skan`
   - liste ostatnich eksportow
   - brak ekranu `unsupported device`

## Test skanu
1. Kliknij `Nowy skan`.
2. Obejdz pokoj powoli, pokazujac:
   - wszystkie sciany
   - przynajmniej jedne drzwi
   - przynajmniej jedno okno
3. Zakoncz skan.
4. W `Review` sprawdz:
   - czy widoczny jest plan 2D
   - czy liczniki scian i otworow maja sens
   - czy nazwa projektu da sie zmienic

## Test eksportu
1. Wybierz `Zapisz do Files`.
2. Zapisz plik `*.madcad.json`.
3. Wroc i sprawdz tez `Udostepnij`.
4. Wyslij plik przez AirDrop na Maca.

## Test importu do desktopowego MadCAD
1. Otworz desktopowy MadCAD.
2. Wejdz w `Pliki`.
3. Uzyj `Import skanu iPhone` albo `Wczytaj JSON`.
4. Wybierz zapisany plik `*.madcad.json`.
5. Sprawdz:
   - warstwy `SCIANY`, `OTWORY`, `WYMIARY`
   - czy obrys jest edytowalny
   - czy wymiary sa widoczne

## Kontrola jakosci
1. Zmierz recznie przynajmniej 3 odcinki w pokoju.
2. Porownaj z wymiarami po imporcie do MadCAD.
3. Zapisz roznice w mm.
4. Jesli sciany lub otwory sa zle, powtorz skan wolniej i porownaj wynik.

## Kryterium zaliczenia v1
- skan konczy sie bez bledu
- eksportuje sie poprawny `*.madcad.json`
- MadCAD otwiera plik bez bledu
- widac sciany, otwory i wymiary
- odchylenie wybranych pomiarow jest akceptowalne dla szybkiego planu pomieszczenia
