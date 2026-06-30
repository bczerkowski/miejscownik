import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../models/place.dart';
import '../theme.dart';
import '../utils/transitions.dart';
import '../widgets/category_picker.dart';
import '../widgets/place_card.dart';
import 'place_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _filter = const [];
  String _query = '';
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Place> _visible() {
    final q = _query.trim().toLowerCase();
    return repo.items.where((p) {
      if (!PlaceRepository.matches(_filter, p)) return false;
      if (q.isEmpty) return true;
      final cats = p.categories.map((c) => c.join(' ')).join(' ');
      return p.title.toLowerCase().contains(q) ||
          (p.address ?? '').toLowerCase().contains(q) ||
          cats.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openFilter() async {
    final picked = await pickCategory(
      context,
      initial: _filter,
      allowCreate: false,
      showCounts: true,
      title: 'Filtruj wg kategorii',
      rootLabel: 'Wszystkie miejsca',
    );
    if (picked != null) setState(() => _filter = picked);
  }

  void _open(Place p) {
    Navigator.of(context).push(smoothRoute(PlaceDetailScreen(placeId: p.id)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: repo,
        builder: (context, _) {
          final places = _visible();
          return CustomScrollView(
            slivers: [
              _appBar(),
              SliverToBoxAdapter(child: _filterBar()),
              if (places.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _emptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 360,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 4 / 5,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => PlaceCard(
                        place: places[i],
                        onTap: () => _open(places[i]),
                      ),
                      childCount: places.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _appBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 132,
      backgroundColor: AppColors.bg,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
        title: _searching
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Miejscownik',
                      style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: AppColors.ink)),
                ],
              ),
        background: Container(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
          alignment: Alignment.topLeft,
          child: _searching
              ? null
              : Text('Miejsca do odkrycia',
                  style: TextStyle(color: AppColors.muted, fontSize: 14)),
        ),
      ),
      actions: [
        if (_searching)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Szukaj miejsca…',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
          ),
        IconButton(
          icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
          onPressed: () => setState(() {
            _searching = !_searching;
            if (!_searching) {
              _query = '';
              _searchCtrl.clear();
            }
          }),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _filterBar() {
    final topLevel = <String>[];
    for (final c in repo.categories) {
      if (c.length == 1 && !topLevel.contains(c.first)) topLevel.add(c.first);
    }
    topLevel.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _filterChip(
            label: 'Wszystkie',
            selected: _filter.isEmpty,
            onTap: () => setState(() => _filter = const []),
          ),
          for (final name in topLevel)
            _filterChip(
              label: name,
              selected: _filter.isNotEmpty && _filter.first == name,
              onTap: () => setState(() => _filter = [name]),
            ),
          // Aktywny głębszy filtr pokazany jako breadcrumb.
          if (_filter.length > 1)
            _filterChip(
              label: _filter.join(' › '),
              selected: true,
              onTap: _openFilter,
            ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, top: 5, bottom: 5),
            child: ActionChip(
              avatar: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Filtruj'),
              onPressed: _openFilter,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 5, bottom: 5),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.seed,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        side: BorderSide(
            color: selected
                ? AppColors.seed
                : Colors.black.withValues(alpha: 0.08)),
      ),
    );
  }

  Widget _emptyState() {
    final filtered = _filter.isNotEmpty || _query.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.seed.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                  filtered ? Icons.search_off_rounded : Icons.explore_rounded,
                  size: 46,
                  color: AppColors.seed),
            ),
            const SizedBox(height: 20),
            Text(
              filtered ? 'Brak miejsc dla tego filtra' : 'Zacznij odkrywać',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              filtered
                  ? 'Zmień kategorię lub wyczyść wyszukiwanie.'
                  : 'Dodaj pierwsze miejsce: zdjęcie, notatkę i pinezkę na mapie.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
