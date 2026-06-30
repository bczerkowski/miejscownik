import 'dart:convert';
import 'dart:typed_data';

/// Dekoduje data-URL (np. "data:image/jpeg;base64,...") lub czysty base64
/// na bajty obrazu gotowe dla Image.memory.
Uint8List decodeDataUrl(String dataUrl) {
  final comma = dataUrl.indexOf(',');
  final b64 = comma >= 0 ? dataUrl.substring(comma + 1) : dataUrl;
  return base64Decode(b64);
}

/// Tworzy data-URL z bajtów obrazu.
String encodeDataUrl(Uint8List bytes, {String mime = 'image/jpeg'}) =>
    'data:$mime;base64,${base64Encode(bytes)}';
