import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/transitions.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'place_edit_screen.dart';
import 'sync_screen.dart';

/// Główna powłoka aplikacji: zakładki Zapisane · Mapa · Profil
/// z dolnym paskiem nawigacji i dużym przyciskiem „+ Dodaj nowe".
class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;

  void _add() {
    Navigator.of(context).push(smoothRoute(const PlaceEditScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          MapScreen(),
          SyncScreen(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _index == 2
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: FloatingActionButton.extended(
                onPressed: _add,
                backgroundColor: AppColors.seed,
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Dodaj nowe',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.seed.withValues(alpha: 0.14),
        height: 68,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded, color: AppColors.seed),
            label: 'Zapisane',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: AppColors.seed),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.seed),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
