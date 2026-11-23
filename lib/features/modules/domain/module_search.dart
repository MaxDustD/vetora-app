import 'engineering_area.dart';
import 'study_module.dart';

enum ModuleSearchSort { title, duration }

class ModuleSearchFilters {
  const ModuleSearchFilters({
    this.query = '',
    this.areas = const {},
    this.onlyFavorites = false,
    this.sort = ModuleSearchSort.title,
  });

  final String query;
  final Set<EngineeringArea> areas;
  final bool onlyFavorites;
  final ModuleSearchSort sort;

  int get activeCount =>
      (query.trim().isNotEmpty ? 1 : 0) +
      (areas.isNotEmpty ? 1 : 0) +
      (onlyFavorites ? 1 : 0);

  ModuleSearchFilters copyWith({
    String? query,
    Set<EngineeringArea>? areas,
    bool? onlyFavorites,
    ModuleSearchSort? sort,
  }) {
    return ModuleSearchFilters(
      query: query ?? this.query,
      areas: areas == null
          ? Set.unmodifiable(this.areas)
          : Set.unmodifiable(areas),
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      sort: sort ?? this.sort,
    );
  }

  ModuleSearchFilters cleared() => ModuleSearchFilters(sort: sort);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModuleSearchFilters &&
        query == other.query &&
        onlyFavorites == other.onlyFavorites &&
        sort == other.sort &&
        _setEquals(areas, other.areas);
  }

  @override
  int get hashCode =>
      Object.hash(query, Object.hashAllUnordered(areas), onlyFavorites, sort);
}

String normalizeSearchText(String value) {
  var normalized = value.trim().toLowerCase();
  const from = 'áàãâäéèêëíìîïóòõôöúùûüç';
  const to = 'aaaaaeeeeiiiiooooouuuuc';
  for (var i = 0; i < from.length; i++) {
    normalized = normalized.replaceAll(from[i], to[i]);
  }
  return normalized;
}

List<StudyModule> applyModuleSearch(
  List<StudyModule> catalog,
  ModuleSearchFilters filters, {
  Set<String> favoriteIds = const {},
}) {
  final words = normalizeSearchText(filters.query)
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  final results = <StudyModule>[];

  for (final module in catalog) {
    if (filters.areas.isNotEmpty && !filters.areas.contains(module.area)) {
      continue;
    }
    if (filters.onlyFavorites && !favoriteIds.contains(module.id)) {
      continue;
    }
    if (words.isNotEmpty) {
      final searchable = normalizeSearchText(
        '${module.title} ${module.subtitle} ${module.area.label} ${module.area.shortLabel} ${module.description}',
      );
      if (!words.every(searchable.contains)) continue;
    }
    results.add(module);
  }

  results.sort((a, b) {
    final primary = filters.sort == ModuleSearchSort.duration
        ? a.durationInMinutes.compareTo(b.durationInMinutes)
        : a.title.toLowerCase().compareTo(b.title.toLowerCase());
    return primary == 0 ? a.title.compareTo(b.title) : primary;
  });
  return results;
}

bool _setEquals<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);
