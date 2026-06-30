import 'package:flutter_test/flutter_test.dart';

import 'package:miejscownik/models/place.dart';

void main() {
  test('Place serializuje się w obie strony', () {
    final p = Place(
      id: 'abc',
      title: 'Testowe miejsce',
      description: 'notatka',
      images: const ['data:image/jpeg;base64,AAAA'],
      videoUrl: 'https://example.com',
      lat: 51.1,
      lng: 17.03,
      address: 'Wrocław',
      categoryPath: const ['Polska', 'Dolnośląskie', 'Wrocław'],
      createdAt: 1700000000000,
    );
    final restored = Place.fromJson(p.toJson());
    expect(restored.title, p.title);
    expect(restored.categoryPath, p.categoryPath);
    expect(restored.lat, p.lat);
    expect(restored.hasLocation, isTrue);
    expect(restored.hasVideo, isTrue);
  });
}
