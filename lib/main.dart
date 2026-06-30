import 'package:flutter/material.dart';

import 'data/repository.dart';
import 'screens/home_screen.dart';
import 'services/sync_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await repo.init();

  runApp(const MiejscownikApp());

  // Rysuj aplikację najpierw; sync to zwykły HTTP (bez wtyczek) i robi cokolwiek
  // dopiero po zalogowaniu. Odtworzenie sesji w tle nie blokuje pierwszej klatki.
  Future(() async {
    try {
      await sync.init();
    } catch (_) {/* zostań w trybie offline, jeśli odtworzenie zawiedzie */}
  });
}

class MiejscownikApp extends StatelessWidget {
  const MiejscownikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Miejscownik',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeScreen(),
    );
  }
}
