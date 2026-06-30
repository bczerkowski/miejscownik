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
    List<String>? categoryPath,
    required this.createdAt,
  })  : images = images ?? <String>[],
        categoryPath = categoryPath ?? <String>[];

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

  /// Ścieżka kategorii, np. ["Polska", "Dolnośląskie", "Wrocław"].
  List<String> categoryPath;

  int createdAt;

  bool get hasLocation => lat != null && lng != null;
  bool get hasVideo => videoUrl != null && videoUrl!.trim().isNotEmpty;
  String? get cover => images.isNotEmpty ? images.first : null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'images': images,
        'videoUrl': videoUrl,
        'lat': lat,
        'lng': lng,
        'address': address,
        'categoryPath': categoryPath,
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
        categoryPath: (m['categoryPath'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            <String>[],
        createdAt: (m['createdAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      );

  String toJson() => jsonEncode(toMap());
  factory Place.fromJson(String s) =>
      Place.fromMap(jsonDecode(s) as Map<String, dynamic>);
}
