import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Wybór zdjęć przez natywny element `<input type=file>` (web).
/// Obsługuje wiele plików naraz i można go wywoływać wielokrotnie.
/// Zwraca listę data-URL (base64).
Future<List<String>> pickImageFiles(
    {bool multiple = true, bool camera = false}) {
  final completer = Completer<List<String>>();
  final input = web.document.createElement('input') as web.HTMLInputElement
    ..type = 'file'
    ..accept = 'image/*'
    ..multiple = multiple;
  if (camera) input.setAttribute('capture', 'environment');

  input.addEventListener(
      'change',
      (web.Event _) {
        final files = input.files;
        if (files == null || files.length == 0) {
          if (!completer.isCompleted) completer.complete(<String>[]);
          return;
        }
        final out = <String>[];
        var pending = files.length;
        void done() {
          pending--;
          if (pending <= 0 && !completer.isCompleted) completer.complete(out);
        }

        for (var i = 0; i < files.length; i++) {
          final f = files.item(i);
          if (f == null) {
            done();
            continue;
          }
          final reader = web.FileReader();
          reader.addEventListener('load', (web.Event _) {
            final r = reader.result;
            if (r.isA<JSString>()) out.add((r as JSString).toDart);
            done();
          }.toJS);
          reader.addEventListener('error', (web.Event _) {
            done();
          }.toJS);
          reader.readAsDataURL(f);
        }
      }.toJS);

  input.click();
  return completer.future;
}

/// Odczytuje obraz ze schowka systemowego (Clipboard API) – wywołane z gestu
/// użytkownika (kliknięcie przycisku „Wklej"). Zwraca data-URL lub null.
Future<String?> readClipboardImage() async {
  try {
    final clipboard = web.window.navigator.clipboard;
    final items = (await clipboard.read().toDart).toDart;
    for (final item in items) {
      final types = item.types.toDart;
      for (final t in types) {
        final type = t.toDart;
        if (type.startsWith('image/')) {
          final blob = await item.getType(type).toDart;
          return await _blobToDataUrl(blob);
        }
      }
    }
  } catch (_) {/* brak uprawnień / pusty schowek */}
  return null;
}

Future<String?> _blobToDataUrl(web.Blob blob) {
  final c = Completer<String?>();
  final reader = web.FileReader();
  reader.addEventListener('load', (web.Event _) {
    final r = reader.result;
    c.complete(r.isA<JSString>() ? (r as JSString).toDart : null);
  }.toJS);
  reader.addEventListener('error', (web.Event _) {
    if (!c.isCompleted) c.complete(null);
  }.toJS);
  reader.readAsDataURL(blob);
  return c.future;
}
