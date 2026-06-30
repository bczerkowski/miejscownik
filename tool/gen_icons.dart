// Generuje ikony PWA + favicon: zielone tło marki + biała pinezka.
// Uruchom: dart run tool/gen_icons.dart   (z katalogu projektu)
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

final _green = img.ColorRgba8(0x12, 0x71, 0x5E, 255);
final _white = img.ColorRgba8(0xFF, 0xFF, 0xFF, 255);

img.Image _icon(int s, {required double k, bool transparentBg = false}) {
  final image = img.Image(width: s, height: s, numChannels: 4);
  if (transparentBg) {
    img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
  } else {
    img.fill(image, color: _green);
  }

  final cx = s / 2.0;
  final r = s * 0.19 * k;
  final cy = s / 2.0 - 0.7 * r;
  final apexY = cy + 2.4 * r;

  // Biała pinezka: koło + trójkąt.
  img.fillCircle(image,
      x: cx.round(), y: cy.round(), radius: r.round(), color: _white, antialias: true);
  img.fillPolygon(image, vertices: [
    img.Point(cx - r * 0.98, cy + r * 0.15),
    img.Point(cx + r * 0.98, cy + r * 0.15),
    img.Point(cx, apexY),
  ], color: _white);

  // Otwór w pinezce (kolor tła).
  final hole = transparentBg ? _green : _green;
  img.fillCircle(image,
      x: cx.round(),
      y: cy.round(),
      radius: (r * 0.42).round(),
      color: hole,
      antialias: true);

  return image;
}

void _write(String path, img.Image image) {
  File(path).writeAsBytesSync(img.encodePng(image));
  stdout.writeln('  $path  (${image.width}x${image.height})');
}

void main() {
  // Pełne tło (zwykłe ikony).
  _write('web/icons/Icon-192.png', _icon(192, k: 1.0));
  _write('web/icons/Icon-512.png', _icon(512, k: 1.0));
  // Maskable: większy margines bezpieczeństwa (mniejsza pinezka, pełne tło).
  _write('web/icons/Icon-maskable-192.png', _icon(192, k: 0.74));
  _write('web/icons/Icon-maskable-512.png', _icon(512, k: 0.74));
  // Favicon.
  _write('web/favicon.png', _icon(64, k: 1.0));
  stdout.writeln('Gotowe.');
  // Wycisz ostrzeżenie o nieużywanej zmiennej w niektórych wersjach.
  math.pi;
}
