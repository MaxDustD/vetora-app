import 'package:flutter_test/flutter_test.dart';
import 'package:vetora/features/home/presentation/greeting.dart';

void main() {
  DateTime at(int hour, [int minute = 0]) => DateTime(2026, 1, 1, hour, minute);

  test('retorna "Bom dia" das 5h às 11h59', () {
    expect(greetingFor(at(5)), 'Bom dia');
    expect(greetingFor(at(11, 59)), 'Bom dia');
  });

  test('retorna "Boa tarde" das 12h às 17h59', () {
    expect(greetingFor(at(12)), 'Boa tarde');
    expect(greetingFor(at(17, 59)), 'Boa tarde');
  });

  test('retorna "Boa noite" das 18h às 4h59', () {
    expect(greetingFor(at(18)), 'Boa noite');
    expect(greetingFor(at(0)), 'Boa noite');
    expect(greetingFor(at(4, 59)), 'Boa noite');
  });
}
