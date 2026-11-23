import 'dart:math' as math;

import 'app_spacing.dart';

/// Regras de layout compartilhadas pelas telas roláveis.
abstract final class AppLayout {
  /// Largura máxima de leitura (limite da classe de janela "compact").
  static const double maxContentWidth = 600;

  /// Margem lateral que centraliza o conteúdo em até [maxContentWidth] dp,
  /// com no mínimo [AppSpacing.lg]. Calculada (em vez de um ConstrainedBox)
  /// para funcionar em SliverPadding, mantendo a rolagem na tela toda.
  static double horizontalPadding(double screenWidth) {
    return math.max(AppSpacing.lg, (screenWidth - maxContentWidth) / 2);
  }
}
