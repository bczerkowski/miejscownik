import 'package:flutter/material.dart';

import 'data/repository.dart';
import 'screens/root_scaffold.dart';
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
      builder: (context, child) => _MobileFrame(child: child),
      home: const RootScaffold(),
    );
  }
}

/// Mobile-first: na szerokim ekranie zamyka aplikację w wyśrodkowanej kolumnie
/// o stałej szerokości (jak web Instagrama/Telegrama), zamiast rozciągać ją na
/// cały monitor. Na telefonie nic nie zmienia.
class _MobileFrame extends StatelessWidget {
  const _MobileFrame({required this.child});

  final Widget? child;

  static const double _maxWidth = 600;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (child == null || width <= _maxWidth) return child!;
    return ColoredBox(
      color: AppColors.backdrop,
      child: Center(
        child: ClipRect(
          child: SizedBox(
            width: _maxWidth,
            child: Material(color: AppColors.bg, child: child),
          ),
        ),
      ),
    );
  }
}
