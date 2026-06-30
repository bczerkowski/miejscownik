/// Dane połączenia z Supabase (publiczne z założenia — chroni je Row Level
/// Security, więc każdy zalogowany użytkownik widzi wyłącznie swój wiersz).
///
/// Reużywamy tego samego projektu Supabase co Lexicon (te same konta), ale
/// osobnej tabeli `places` — patrz docs/SUPABASE.md po SQL tworzący tabelę.
class SupabaseConfig {
  static const String url = 'https://yqmlbfgxzqhqstdktibg.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlxbWxiZmd4enFocXN0ZGt0aWJnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1Njc5ODAsImV4cCI6MjA5ODE0Mzk4MH0.3-MqAPjlqQbh1MsiIVv9O2I0D_ZkBBvDJlPjgQJCTc4';

  /// Tabela przechowująca po jednym dokumencie JSON na użytkownika.
  static const String table = 'places';

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
