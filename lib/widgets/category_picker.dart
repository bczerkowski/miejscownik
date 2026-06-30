import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../theme.dart';
import '../utils/category_tree.dart';

/// Otwiera arkusz wyboru kategorii z hierarchią.
///
/// Zwraca wybraną ścieżkę (pusta lista = "Bez kategorii" / "Wszystkie"),
/// albo `null` jeśli anulowano.
Future<List<String>?> pickCategory(
  BuildContext context, {
  List<String> initial = const [],
  bool allowCreate = true,
  bool showCounts = false,
  String title = 'Wybierz kategorię',
  String rootLabel = 'Bez kategorii',
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _CategorySheet(
      initial: initial,
      allowCreate: allowCreate,
      showCounts: showCounts,
      title: title,
      rootLabel: rootLabel,
    ),
  );
}

class _CategorySheet extends StatefulWidget {
  const _CategorySheet({
    required this.initial,
    required this.allowCreate,
    required this.showCounts,
    required this.title,
    required this.rootLabel,
  });

  final List<String> initial;
  final bool allowCreate;
  final bool showCounts;
  final String title;
  final String rootLabel;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  final _newCtrl = TextEditingController();
  final _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    // Rozwiń ścieżkę do początkowo wybranej kategorii.
    for (var i = 1; i < widget.initial.length; i++) {
      _expanded.add(widget.initial.sublist(0, i).join('›'));
    }
  }

  @override
  void dispose() {
    _newCtrl.dispose();
    super.dispose();
  }

  void _addNew() {
    final raw = _newCtrl.text.trim();
    if (raw.isEmpty) return;
    final path = raw
        .split(RegExp(r'[>/›]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (path.isEmpty) return;
    repo.addCategory(path);
    Navigator.pop(context, path);
  }

  @override
  Widget build(BuildContext context) {
    final tree = buildCategoryTree(repo.categories);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.82),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(widget.title,
                            style: Theme.of(context).textTheme.titleLarge)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  children: [
                    _rootTile(),
                    for (final node in tree.children) ..._buildNode(node, 0),
                  ],
                ),
              ),
              if (widget.allowCreate)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newCtrl,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addNew(),
                          decoration: const InputDecoration(
                            hintText: 'Nowa, np. Polska › Wrocław',
                            prefixIcon: Icon(Icons.create_new_folder_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                          onPressed: _addNew, child: const Text('Dodaj')),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rootTile() {
    final selected = widget.initial.isEmpty;
    return _tile(
      label: widget.rootLabel,
      depth: 0,
      icon: Icons.all_inclusive_rounded,
      selected: selected,
      count: widget.showCounts ? repo.items.length : null,
      hasChildren: false,
      expanded: false,
      onTap: () => Navigator.pop(context, <String>[]),
      onToggle: null,
    );
  }

  List<Widget> _buildNode(CategoryNode node, int depth) {
    final key = node.path.join('›');
    final isOpen = _expanded.contains(key);
    final selected = _pathEquals(node.path, widget.initial);
    final widgets = <Widget>[
      _tile(
        label: node.name,
        depth: depth,
        icon: node.children.isEmpty
            ? Icons.place_outlined
            : (isOpen ? Icons.folder_open_rounded : Icons.folder_rounded),
        selected: selected,
        count: widget.showCounts ? repo.countIn(node.path) : null,
        hasChildren: node.children.isNotEmpty,
        expanded: isOpen,
        onTap: () => Navigator.pop(context, node.path),
        onToggle: node.children.isEmpty
            ? null
            : () => setState(() {
                  isOpen ? _expanded.remove(key) : _expanded.add(key);
                }),
      ),
    ];
    if (isOpen) {
      for (final c in node.children) {
        widgets.addAll(_buildNode(c, depth + 1));
      }
    }
    return widgets;
  }

  Widget _tile({
    required String label,
    required int depth,
    required IconData icon,
    required bool selected,
    required int? count,
    required bool hasChildren,
    required bool expanded,
    required VoidCallback onTap,
    required VoidCallback? onToggle,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: 8.0 + depth * 18, right: 8, bottom: 4),
      child: Material(
        color: selected ? AppColors.seed.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: selected ? AppColors.seed : AppColors.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? AppColors.seed : AppColors.ink,
                      )),
                ),
                if (count != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text('$count',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12.5)),
                  ),
                if (onToggle != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onToggle,
                    icon: Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppColors.muted),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool _pathEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
