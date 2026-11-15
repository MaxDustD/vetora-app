import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Saudação da Home. Recebe os textos prontos: não sabe que horas são nem
/// onde o nome está guardado.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.greeting, this.name = ''});

  final String greeting;

  /// Nome do perfil. Vazio enquanto o perfil não foi preenchido: uma saudação
  /// genérica é melhor que um "Olá, usuário" artificial.
  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final salutation = trimmed.isEmpty ? greeting : '$greeting, $trimmed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(salutation.toUpperCase(), style: AppTextStyles.rotulo),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          header: true,
          child: const Text(
            'O que vamos aprender hoje?',
            style: AppTextStyles.titulo,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Explore conceitos, conecte ideias e avance no seu ritmo.',
          style: AppTextStyles.corpo,
        ),
      ],
    );
  }
}
