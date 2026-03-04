# MadCAD 2D 3.1.1

Stabilizacyjne wydanie skupione na DWG (ODA), instalacji dodatku i czytelniejszym UX menu plików.

## ✨ Nowości

- Ujednolicony przepływ DWG w menu **Zapisz/Drukuj** dla importu i eksportu.
- Pozycje DWG przeniesione na dół menu.
- Gdy brak ODA, pozycje DWG pokazują jasny komunikat: brak dodatku + instalacja.
- Lepsza informacja o stanie instalacji ODA (mniej niepewności po kliknięciu).

## 🛠️ Poprawki

- Usunięto pytanie onboardingowe o DWG przy starcie aplikacji.
- Usprawniono instalator ODA na macOS (walidacja i bardziej odporne kopiowanie).
- Dodano automatyczną instalację ODA na Windows (MSI) + fallback lokalny.
- Dodano fallback kompatybilności dla środowisk, gdzie automatyczny bridge instalacji jest niedostępny.
- Poprawiono obsługę błędów sieci/DNS podczas pobierania instalatora ODA.

## 📦 Pliki release

- `MadCAD 2D-3.1.1-mac-arm64.zip`
- `MadCAD 2D-3.1.1-win-x64.exe`

## 🔎 Uwagi

- W tym wydaniu podpis/notaryzacja mogą zależeć od lokalnej konfiguracji certyfikatów.
- Jeśli ODA nie instaluje się automatycznie, aplikacja przełącza się na tryb ręcznej konfiguracji konwertera.
