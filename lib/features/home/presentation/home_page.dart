import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/storage/onboarding_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/vetora_header.dart';

/// Home provisória (Trabalho 1, seção 08): destino final do fluxo inicial.
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.storage = const OnboardingStorage()});

  final OnboardingStorage storage;

  Future<void> _resetFirstAccess(BuildContext context) async {
    await storage.reset();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Primeiro acesso redefinido. Reabra o app para ver o onboarding.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VetoraHeader(),
              const SizedBox(height: 48),
              const Text('INÍCIO', style: AppTextStyles.rotulo),
              const SizedBox(height: 12),
              const Text('Bem-vindo ao\nVetora.', style: AppTextStyles.titulo),
              const SizedBox(height: 12),
              const Text(
                'Seu espaço para cálculos de Física e Engenharia.',
                style: AppTextStyles.corpo,
              ),
              const SizedBox(height: 32),
              const _ModulesCard(),
              const Spacer(),
              // Apoio aos testes: só aparece em modo de depuração.
              if (kDebugMode)
                Center(
                  child: TextButton(
                    onPressed: () => _resetFirstAccess(context),
                    child: const Text('REDEFINIR PRIMEIRO ACESSO (DEBUG)'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModulesCard extends StatelessWidget {
  const _ModulesCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.superficieElevada,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.borda),
              ),
              child: const Text(
                'Mecânica',
                style: TextStyle(
                  fontFamily: AppTheme.fontMono,
                  fontSize: 13,
                  color: AppColors.ciano,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Módulos de cálculo em breve', style: AppTextStyles.corpo),
          ],
        ),
      ),
    );
  }
}
