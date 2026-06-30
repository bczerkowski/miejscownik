# Miejscownik 📍

Osobisty katalog **miejsc do odkrycia** — content-first, mobile-first PWA.
Zapisuj miejsca ze zdjęciami, notatkami, linkiem do rolki (IG/TikTok/YT) i
pinezką na mapie; układaj je w hierarchiczne kategorie i filtruj.

Aplikacja jest **offline-first** (Hive) z opcjonalną **synchronizacją w chmurze**
między urządzeniami i ręcznym backupem JSON.

## Funkcje

- **Karta miejsca**: galeria zdjęć (galeria/aparat), opis/notatki, link wideo,
  lokalizacja z mapą OpenStreetMap i przyciskiem „Nawiguj" (Mapy Google).
- **Hierarchiczne kategorie**: np. `Polska › Dolnośląskie › Wrocław`, tworzone w
  locie; puste foldery również się utrzymują.
- **Filtrowanie i wyszukiwanie**: chipy kategorii górnego poziomu, arkusz z całym
  drzewem (z licznikami) oraz wyszukiwarka.
- **Synchronizacja w chmurze** (Supabase, plain-HTTP) + **kopia JSON**.

## Stack

Flutter web · Hive · flutter_map (OpenStreetMap) · image_picker · url_launcher ·
google_fonts · http.

## Uruchomienie lokalne

```bash
flutter pub get
flutter run -d chrome
```

## Budowanie web

```bash
flutter build web --release
```

## Synchronizacja

Patrz [docs/SUPABASE.md](docs/SUPABASE.md) — jednorazowy SQL tworzący tabelę
`places` z Row Level Security.

## Ikony

Regeneracja ikon PWA (zielone tło + biała pinezka):

```bash
dart run tool/gen_icons.dart
```

## Wdrożenie

Push na `main` wdraża web na GitHub Pages
([.github/workflows/deploy-pages.yml](.github/workflows/deploy-pages.yml)),
z `--base-href "/<repo>/"`.
