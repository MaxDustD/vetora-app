import 'package:flutter_test/flutter_test.dart';
import 'package:vetora/features/home/presentation/module_ordering.dart';
import 'package:vetora/features/modules/domain/engineering_area.dart';
import 'package:vetora/features/modules/domain/module_resource.dart';
import 'package:vetora/features/modules/domain/study_module.dart';

StudyModule _module(String id, EngineeringArea area) => StudyModule(
  id: id,
  title: id,
  area: area,
  topicCount: 1,
  durationInMinutes: 30,
  resources: const {ModuleResource.theory},
);

void main() {
  final physics = _module('fisica', EngineeringArea.physics);
  final civil = _module('civil', EngineeringArea.civil);
  final electrical = _module('eletrica', EngineeringArea.electrical);
  final modules = [physics, civil, electrical];

  test('sem filtro nem interesses, mantém a ordem de popularidade', () {
    expect(arrangeModules(modules), modules);
  });

  test('com área, mostra só os módulos dela', () {
    expect(arrangeModules(modules, area: EngineeringArea.civil), [civil]);
    expect(arrangeModules(modules, area: EngineeringArea.mechanical), isEmpty);
  });

  test('coloca primeiro as áreas de interesse, preservando a ordem', () {
    final result = arrangeModules(
      modules,
      interests: ['Engenharia Elétrica', 'Engenharia Civil'],
    );
    expect(result, [civil, electrical, physics]);
  });

  test('ignora interesses que não são áreas (ex.: "Química")', () {
    expect(arrangeModules(modules, interests: ['Química']), modules);
  });
}
