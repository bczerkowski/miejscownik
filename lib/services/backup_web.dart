import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Pobiera [content] jako plik [filename] w przeglądarce.
void downloadText(String filename, String content,
    {String mime = 'application/json;charset=utf-8'}) {
  final blob = web.Blob([content.toJS].toJS, web.BlobPropertyBag(type: mime));
  final url = web.URL.createObjectURL(blob);
  final a = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename;
  web.document.body!.appendChild(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
}

/// Otwiera systemowy wybór pliku i zwraca jego treść tekstową (lub null).
Future<String?> pickTextFile({String accept = 'application/json,.json'}) {
  final completer = Completer<String?>();
  final input = web.document.createElement('input') as web.HTMLInputElement
    ..type = 'file'
    ..accept = accept;

  input.addEventListener(
      'change',
      (web.Event _) {
        final files = input.files;
        if (files == null || files.length == 0) {
          completer.complete(null);
          return;
        }
        final reader = web.FileReader();
        reader.addEventListener(
            'load',
            (web.Event _) {
              final r = reader.result;
              completer
                  .complete(r.isA<JSString>() ? (r as JSString).toDart : null);
            }.toJS);
        reader.addEventListener('error', (web.Event _) {
          completer.complete(null);
        }.toJS);
        reader.readAsText(files.item(0)!);
      }.toJS);

  input.click();
  return completer.future;
}
