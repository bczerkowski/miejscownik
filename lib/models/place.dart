import 'dart:convert';

/// Pojedyncze miejsce w katalogu.
///
/// Przechowywane w Hive jako zakodowany JSON, dzięki czemu nie potrzebujemy
/// generowanych adapterów (i build_runnera).
class Place {
  Place({
    required this.id,
    required this.title,
    this.description = '',
    List<String>? images,
    this.videoUrl,
    this.lat,
    this.lng,
    this.address,
    List<List<String>>? categories,
    required this.createdAt,
  })  : images = images ?? <String>[],
        categories = categories ?? <List<String>>[];

  String id;
  String title;
  String description;

  /// Zdjęcia zakodowane jako data-URL (base64) – działa offline na web.
  List<String> images;

  /// Link do rolki / wideo (IG, TikTok, YouTube…) lub osadzony plik.
  String? videoUrl;

  double? lat;
  double? lng;
  String? address;

  /// Lista przypisanych kategorii. Każda to hierarchiczna ścieżka, np.
  /// `["Polska", "Dolnośląskie", "Wrocław"]` albo płaski tag `["Jedzenie"]`.
  /// Miejsce może należeć do kilku kategorii naraz.
  List<List<String>> categories;

  int createdAt;

  bool get hasLocation => lat != null && lng != null;
  bool get hasVideo => videoUrl != null && videoUrl!.trim().isNotEmpty;
  bool get hasCategories => categories.isNotEmpty;
  String? get cover => images.isNotEmpty ? images.first : null;

  /// Etykiety-liście (ostatni segment każdej ścieżki) – do chipsów na karcie.
  List<String> get leafLabels =>
      categories.where((c) => c.isNotEmpty).map((c) => c.last).toList();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'images': images,
        'videoUrl': videoUrl,
        'lat': lat,
        'lng': lng,
        'address': address,
        'categories': categories,
        'createdAt': createdAt,
      };

  factory Place.fromMap(Map<String, dynamic> m) => Place(
        id: m['id'] as String,
        title: m['title'] as String? ?? '',
        description: m['description'] as String? ?? '',
        images: (m['images'] as List?)?.map((e) => e as String).toList() ??
            <String>[],
        videoUrl: m['videoUrl'] as String?,
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        address: m['address'] as String?,
        categories: _readCategories(m),
        createdAt: (m['createdAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      );

  /// Czyta nowy format `categories` (lista ścieżek) lub migruje stary
  /// `categoryPath` (pojedyncza ścieżka).
  static List<List<String>> _readCategories(Map<String, dynamic> m) {
    final raw = m['categories'];
    if (raw is List) {
      return raw
          .map((e) => (e as List).map((s) => s as String).toList())
          .where((c) => c.isNotEmpty)
          .toList();
    }
    final legacy = m['categoryPath'];
    if (legacy is List && legacy.isNotEmpty) {
      return [legacy.map((s) => s as String).toList()];
    }
    return <List<String>>[];
  }

  String toJson() => jsonEncode(toMap());
  factory Place.fromJson(String s) =>
      Place.fromMap(jsonDecode(s) as Map<String, dynamic>);
}
