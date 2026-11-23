import 'package:flutter/foundation.dart';

import '../domain/module_search.dart';
import '../domain/engineering_area.dart';
import '../domain/study_module.dart';
import '../domain/study_module_repository.dart';

enum ModuleSearchStatus { loading, ready, failure }

class ModuleSearchController extends ChangeNotifier {
  ModuleSearchController({required this.repository});

  final StudyModuleRepository repository;

  ModuleSearchFilters _filters = const ModuleSearchFilters();
  List<StudyModule> _catalog = const [];
  ModuleSearchStatus _status = ModuleSearchStatus.loading;
  Future<void>? _loading;
  bool _disposed = false;

  ModuleSearchFilters get filters => _filters;
  List<StudyModule> get catalog => _catalog;
  ModuleSearchStatus get status => _status;

  Future<void> load() {
    final loading = _loading;
    if (loading != null) return loading;

    _status = ModuleSearchStatus.loading;
    _notify();
    _loading = _loadCatalog();
    return _loading!;
  }

  Future<void> _loadCatalog() async {
    try {
      final catalog = await repository.fetchAll();
      _catalog = List.unmodifiable(catalog);
      _status = ModuleSearchStatus.ready;
    } catch (_) {
      _status = ModuleSearchStatus.failure;
    } finally {
      _loading = null;
      _notify();
    }
  }

  void updateFilters(ModuleSearchFilters next) {
    if (next == _filters) return;
    _filters = next;
    _notify();
  }

  void toggleArea(EngineeringArea area) {
    final next = Set<EngineeringArea>.of(_filters.areas);
    if (!next.add(area)) next.remove(area);
    updateFilters(_filters.copyWith(areas: next));
  }

  void clearFilters() => updateFilters(_filters.cleared());

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
