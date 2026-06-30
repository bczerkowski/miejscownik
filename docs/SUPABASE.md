# Synchronizacja w chmurze (Supabase)

Miejscownik synchronizuje cały katalog (miejsca + kategorie) jako **jeden
dokument JSON na użytkownika**, przez zwykłe HTTP do Supabase (bez wtyczek
Fluttera uruchamianych przy starcie). Reużywamy tego samego projektu Supabase co
Lexicon — wystarczy **raz** utworzyć osobną tabelę `places`.

## 1. Utwórz tabelę (jednorazowo)

W panelu Supabase → **SQL Editor** → wklej i uruchom:

```sql
-- Jeden wiersz na użytkownika; cały katalog w kolumnie data (JSON jako tekst).
create table if not exists public.places (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  data       text not null,
  updated_at timestamptz not null default now()
);

alter table public.places enable row level security;

-- Każdy widzi i modyfikuje wyłącznie swój wiersz.
create policy "own row - select" on public.places
  for select using (auth.uid() = user_id);
create policy "own row - insert" on public.places
  for insert with check (auth.uid() = user_id);
create policy "own row - update" on public.places
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

To wszystko. Klucze połączenia są w `lib/services/supabase_config.dart`
(publiczne z założenia — chroni je Row Level Security).

## 2. Jak to działa

- **Logowanie/rejestracja**: e-mail + hasło (Supabase Auth). Możesz użyć tego
  samego konta co w innych aplikacjach na tym projekcie.
- **Wypychanie**: po każdej zmianie (debounce ~2 s) wysyłany jest cały katalog
  (`upsert` z `Prefer: resolution=merge-duplicates`).
- **Pobieranie**: polling co ~15 s oraz przy wejściu na ekran „Synchronizuj
  teraz". Rozstrzyganie „ostatni wygrywa" po `updated_at`.
- **Pierwsze logowanie z danymi po obu stronach**: aplikacja pyta, którą wersję
  zostawić (urządzenie vs chmura).
- **Sesja** trzymana lokalnie w Hive (box `meta`), nie w sieci — brak ryzyka
  białej strony przy starcie.

## 3. Kopia zapasowa bez chmury

Ekran „Synchronizacja i kopie" ma też **Eksportuj / Importuj** — pobiera cały
katalog do pliku `.json` i wczytuje go z powrotem (ręczny backup / przeniesienie
bez konta).
