import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/storage/onboarding_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Splash Screen Flutter (Trabalho 1, seção 06).
///
/// Primeira tela controlada pelo Flutter. Sua responsabilidade é real: ler se o
/// onboarding já foi concluído e decidir o destino do usuário. Não há atraso
/// fixo — a duração é a do trabalho feito.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key, this.storage = const OnboardingStorage()});

  final OnboardingStorage storage;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  /// Progresso real: iniciar → ler a chave → decidir o destino.
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _decideDestination();
  }

  Future<void> _decideDestination() async {
    var completed = false;
    try {
      completed = await widget.storage.isCompleted();
    } catch (_) {
      // Na dúvida, mostra o onboarding: o usuário nunca fica preso na Splash.
      completed = false;
    }
    if (!mounted) return;
    setState(() => _progress = 2 / 3);

    final destination = completed ? AppRoutes.home : AppRoutes.onboarding;
    setState(() => _progress = 1);

    // Substitui a Splash na pilha: o botão voltar nunca retorna para ela.
    Navigator.of(context).pushReplacementNamed(destination);
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progress * 100).round();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
          child: Column(
            children: [
              const Spacer(flex: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/images/icon/app_icon.png',
                  width: 112,
                  height: 112,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'VETORA',
                style: AppTextStyles.logotipo.copyWith(
                  fontSize: 28,
                  letterSpacing: 10,
                ),
              ),
              const SizedBox(height: 10),
              const Text('Física e Engenharia', style: AppTextStyles.corpo),
              const Spacer(flex: 4),
              Row(
                children: [
                  const Text('PREPARANDO MÓDULOS', style: AppTextStyles.rotulo),
                  const Spacer(),
                  Text(
                    '$percent%',
                    style: AppTextStyles.rotulo.copyWith(
                      color: AppColors.ciano,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 4,
                  color: AppColors.ciano,
                  backgroundColor: AppColors.trilhoProgresso,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}