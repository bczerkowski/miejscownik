import 'dart:js_interop';

import 'package:web/web.dart' as web;

JSFunction? _handler;

/// Włącza nasłuch wklejania (Ctrl+V). Gdy w schowku jest obraz, wywołuje
/// [onImage] z data-URL (base64). Pamiętaj o [disableImagePaste] przy wyjściu.
void enableImagePaste(void Function(String dataUrl) onImage) {
  disableImagePaste();
  void onPaste(web.ClipboardEvent e) {
    final items = e.clipboardData?.items;
    if (items == null) return;
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      if (!it.type.startsWith('image/')) continue;
      final file = it.getAsFile();
      if (file == null) continue;
      final reader = web.FileReader();
      reader.addEventListener('load', (web.Event _) {
        final r = reader.result;
        if (r.isA<JSString>()) onImage((r as JSString).toDart);
      }.toJS);
      reader.readAsDataURL(file);
      e.preventDefault();
    }
  }

  _handler = onPaste.toJS;
  web.document.addEventListener('paste', _handler);
}

void disableImagePaste() {
  if (_handler != null) {
    web.document.removeEventListener('paste', _handler);
    _handler = null;
  }
}
