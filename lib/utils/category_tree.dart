/// Węzeł drzewa kategorii budowanego z płaskiej listy ścieżek.
class CategoryNode {
  CategoryNode(this.name, this.path);

  final String name;
  final List<String> path; // pełna ścieżka do tego węzła
  final List<CategoryNode> children = [];

  CategoryNode _child(String name) {
    final existing = children.where((c) => c.name == name);
    if (existing.isNotEmpty) return existing.first;
    final node = CategoryNode(name, [...path, name]);
    children.add(node);
    return node;
  }
}

/// Buduje drzewo z listy ścieżek, np. [["Polska","Wrocław"], ["Za granicą"]].
CategoryNode buildCategoryTree(List<List<String>> paths) {
  final root = CategoryNode('', const []);
  for (final p in paths) {
    var cursor = root;
    for (final segment in p) {
      cursor = cursor._child(segment);
    }
  }
  void sortRec(CategoryNode n) {
    n.children.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    for (final c in n.children) {
      sortRec(c);
    }
  }

  sortRec(root);
  return root;
}
