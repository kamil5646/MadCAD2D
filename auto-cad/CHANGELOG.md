# Changelog

## 3.1.1 (2026-03-04)

### Dodano / zmieniono
- Ujednolicono obsługę DWG w menu `Zapisz/Drukuj` dla importu i eksportu.
- Gdy ODA nie jest dostępne, pozycje DWG pokazują komunikat o braku dodatku i możliwość instalacji.
- Pozycje DWG przeniesiono na sam dół menu `Zapisz/Drukuj`.
- Dodano czytelniejszy przepływ instalacji ODA (status/komunikaty podczas akcji).

### Poprawki
- Usunięto pytanie onboardingowe o DWG przy starcie aplikacji.
- Usprawniono instalację ODA na macOS (lepsza walidacja i obsługa błędów).
- Dodano automatyczną instalację ODA także dla Windows (MSI) + fallback lokalny.
- Dodano fallback kompatybilności, gdy automatyczny bridge instalacji nie jest dostępny.

### Artefakty release
- `MadCAD 2D-3.1.1-mac-arm64.zip`
- `MadCAD 2D-3.1.1-win-x64.exe`
