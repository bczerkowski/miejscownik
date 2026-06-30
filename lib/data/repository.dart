import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/place.dart';

/// Globalne repozytorium aplikacji. Trzyma miejsca i drzewo kategorii,
/// powiadamia UI o zmianach (ChangeNotifier).
class PlaceRepository extends ChangeNotifier {
  static const _placesBoxName = 'places';
  static const _metaBoxName = 'meta';

  late Box _places;
  late Box _meta;

  final List<Place> _items = [];

  /// Zarejestrowane ścieżki kategorii (także puste foldery).
  final List<List<String>> _categories = [];

  List<Place> get items => List.unmodifiable(_items);
  List<List<String>> get categories => List.unmodifiable(_categories);

  Future<void> init() async {
    await Hive.initFlutter();
    _places = await Hive.openBox(_placesBoxName);
    _meta = await Hive.openBox(_metaBoxName);
    _load();
  }

  void _load() {
    _items.clear();
    for (final v in _places.values) {
      try {
        _items.add(Place.fromJson(v as String));
      } catch (_) {/* pomiń uszkodzony wpis */}
    }
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _categories.clear();
    final raw = _meta.get('categories') as String?;
    if (raw != null) {
      final list = (jsonDecode(raw) as List)
          .map((e) => (e as List).map((s) => s as String).toList())
          .toList();
      _categories.addAll(list);
    }
    // Upewnij się, że każda ścieżka użyta przez miejsce istnieje w drzewie.
    for (final p in _items) {
      for (final c in p.categories) {
        _registerPath(c);
      }
    }
    notifyListeners();
  }

  // ---- Miejsca -------------------------------------------------------------

  Future<void> upsert(Place place) async {
    if (place.categories.isNotEmpty) {
      for (final c in place.categories) {
        _registerPath(c);
      }
      await _persistCategories();
    }
    await _places.put(place.id, place.toJson());
    final i = _items.indexWhere((e) => e.id == place.id);
    if (i >= 0) {
      _items[i] = place;
    } else {
      _items.add(place);
    }
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _places.delete(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  int get count => _items.length;

  // ---- Eksport / import (backup JSON + sync) -------------------------------

  /// Cała zawartość katalogu jako jeden dokument JSON.
  String exportData() => jsonEncode({
        'version': 1,
        'places': _items.map((e) => e.toMap()).toList(),
        'categories': _categories,
      });

  /// Zastępuje całą zawartość danymi z [json] (format jak [exportData]).
  Future<void> importData(String json) async {
    final m = jsonDecode(json) as Map<String, dynamic>;
    final places = (m['places'] as List? ?? [])
        .map((e) => Place.fromMap(e as Map<String, dynamic>))
        .toList();
    final cats = (m['categories'] as List? ?? [])
        .map((e) => (e as List).map((s) => s as String).toList())
        .toList();

    await _places.clear();
    for (final p in places) {
      await _places.put(p.id, p.toJson());
    }
    _categories
      ..clear()
      ..addAll(cats);
    await _persistCategories();
    _load();
  }

  // ---- Kategorie -----------------------------------------------------------

  void _registerPath(List<String> path) {
    // Rejestruje ścieżkę oraz wszystkie jej prefiksy (poziomy nadrzędne).
    for (var i = 1; i <= path.length; i++) {
      final prefix = path.sublist(0, i);
      final exists = _categories.any((c) => _pathEquals(c, prefix));
      if (!exists) _categories.add(prefix);
    }
  }

  Future<void> addCategory(List<String> path) async {
    if (path.isEmpty) return;
    _registerPath(path);
    await _persistCategories();
    notifyListeners();
  }

  /// Usuwa kategorię i wszystkie podkategorie z drzewa oraz z miejsc (każde
  /// miejsce traci pasujące przypisania, pozostałe zostają).
  Future<void> deleteCategory(List<String> path) async {
    _categories.removeWhere((c) => _isPrefix(path, c));
    for (final p in _items) {
      final before = p.categories.length;
      p.categories.removeWhere((c) => _isPrefix(path, c));
      if (p.categories.length != before) {
        await _places.put(p.id, p.toJson());
      }
    }
    await _persistCategories();
    notifyListeners();
  }

  Future<void> _persistCategories() async {
    await _meta.put('categories', jsonEncode(_categories));
  }

  // ---- Trwałe klucz-wartość (dla sync: sesja, znaczniki) -------------------

  String? metaGetString(String key) => _meta.get(key) as String?;
  bool? metaGetBool(String key) => _meta.get(key) as bool?;
  int? metaGetInt(String key) => _meta.get(key) as int?;
  Future<void> metaSet(String key, Object? value) async =>
      value == null ? _meta.delete(key) : _meta.put(key, value);
  Future<void> metaRemove(String key) async => _meta.delete(key);

  // ---- Pomocnicze ----------------------------------------------------------

  /// Liczba miejsc, których dowolna kategoria mieści się w [path].
  int countIn(List<String> path) =>
      _items.where((p) => matches(path, p)).length;

  /// Czy miejsce [p] pasuje do filtra [filter] (pusty = wszystkie; w innym
  /// wypadku którakolwiek z kategorii miejsca musi mieć [filter] jako prefiks).
  static bool matches(List<String> filter, Place p) {
    if (filter.isEmpty) return true;
    return p.categories.any((c) => _isPrefix(filter, c));
  }

  static bool _pathEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Czy [prefix] jest prefiksem (lub równy) [path].
  static bool _isPrefix(List<String> prefix, List<String> path) {
    if (prefix.isEmpty) return true; // pusta = "wszystkie"
    if (path.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (path[i] != prefix[i]) return false;
    }
    return true;
  }

  static bool isPrefix(List<String> prefix, List<String> path) =>
      _isPrefix(prefix, path);
}

/// Singleton używany w całej aplikacji.
final repo = PlaceRepository();
