// Minimalny serwer statyczny dla build/web Miejscownika (absolutna ścieżka).
import 'dart:io';

const _root = r'C:\Users\ae4770\Miejscownik\build\web';

const _types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.mjs': 'application/javascript',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? int.parse(args.first) : 8077;
  final server = await HttpServer.bind('127.0.0.1', port);
  stdout.writeln('Serving $_root at http://127.0.0.1:$port');

  await for (final req in server) {
    try {
      var p = req.uri.path;
      if (p == '/' || p.isEmpty) p = '/index.html';
      var file = File('$_root$p');
      if (!await file.exists()) {
        file = File('$_root\\index.html');
      }
      final ext = p.contains('.') ? p.substring(p.lastIndexOf('.')) : '';
      final bytes = await file.readAsBytes();
      req.response.headers
          .set('Content-Type', _types[ext] ?? 'application/octet-stream');
      req.response.add(bytes);
      await req.response.close();
    } catch (_) {
      try {
        await req.response.close();
      } catch (_) {/* nic */}
    }
  }
}
