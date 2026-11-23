import 'package:flutter_test/flutter_test.dart';
import 'package:vetora/core/common/formatters.dart';

void main() {
  group('formatDuration', () {
    test('mostra só minutos abaixo de 1 hora', () {
      expect(formatDuration(45), '45 min');
      expect(formatDuration(59), '59 min');
    });

    test('mostra horas exatas sem minutos', () {
      expect(formatDuration(60), '1 h');
      expect(formatDuration(120), '2 h');
    });

    test('combina horas e minutos', () {
      expect(formatDuration(90), '1 h 30 min');
    });
  });

  group('formatCount', () {
    test('usa o singular para 1 e o plural para os demais', () {
      expect(formatCount(1, 'tópico', 'tópicos'), '1 tópico');
      expect(formatCount(0, 'tópico', 'tópicos'), '0 tópicos');
      expect(formatCount(12, 'tópico', 'tópicos'), '12 tópicos');
    });
  });
}
