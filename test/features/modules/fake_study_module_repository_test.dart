import 'package:flutter_test/flutter_test.dart';
import 'package:vetora/features/modules/data/fake_study_module_repository.dart';

void main() {
  const repo = FakeStudyModuleRepository(delay: Duration.zero);

  test('ids dos módulos são únicos', () async {
    final modules = await repo.fetchAll();
    final ids = modules.map((m) => m.id).toSet();
    expect(ids.length, modules.length);
  });

  test('Cálculo 1 e Mecânica clássica têm material', () async {
    expect(await repo.fetchSections('calculo-1'), isNotEmpty);
    expect(await repo.fetchSections('mecanica-classica'), isNotEmpty);
  });

  // O cartão mostra topicCount; se uma seção for adicionada ao material sem
  // atualizar o número, este teste avisa.
  test(
    'topicCount bate com o número de seções dos módulos com material',
    () async {
      for (final module in await repo.fetchAll()) {
        final sections = await repo.fetchSections(module.id);
        if (sections.isEmpty) continue;
        expect(sections.length, module.topicCount, reason: module.id);
      }
    },
  );

  test('ids das seções são únicos dentro de cada módulo', () async {
    for (final module in await repo.fetchAll()) {
      final sections = await repo.fetchSections(module.id);
      final ids = sections.map((s) => s.id).toSet();
      expect(ids.length, sections.length, reason: module.id);
    }
  });

  test('módulo sem material devolve lista vazia', () async {
    expect(await repo.fetchSections('nao-existe'), isEmpty);
  });
}
