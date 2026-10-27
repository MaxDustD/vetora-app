import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/storage/onboarding_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/vetora_header.dart';
import 'widgets/onboarding_illustrations.dart';
import 'widgets/onboarding_step_layout.dart';

class _OnboardingStep {
  const _OnboardingStep({
    required this.title,
    required this.message,
    required this.illustration,
  });

  final String title;
  final String message;
  final Widget illustration;
}

/// Onboarding com exatamente três etapas (Trabalho 1, seção 07):
/// o que é → por que é relevante → o que esperar.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.storage = const OnboardingStorage()});

  final OnboardingStorage storage;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _steps = [
    _OnboardingStep(
      title: 'Engenharia começa com boas ideias.',
      message: 'Aprenda os conceitos de Física que ajudam a explicar como o mundo funciona.',
      illustration: BodyDiagramIllustration(),
    ),
    _OnboardingStep(
      title: 'Conecte a teoria à prática.',
      message: 'Explore matérias de Engenharia Civil, Elétrica e Mecânica em um só lugar.',
      illustration: SolvedExerciseIllustration(),
    ),
    _OnboardingStep(
      title: 'Estude no seu ritmo.',
      message: 'Descubra novos assuntos, retome seus temas favoritos e construa seu conhecimento etapa por etapa.',
      illustration: CalculatorPreviewIllustration(),
    ),
  ];

  final _controller = PageController();
  int _currentPage = 0;
  bool _finishing = false;

  bool get _isLastPage => _currentPage == _steps.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// "Pular" e "Começar" concluem o onboarding: grava a chave (aguardando a
  /// gravação) e abre a Home removendo as rotas anteriores da pilha.
  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    await widget.storage.markCompleted();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Voltar do Android: nas páginas 2 e 3 volta uma página; na 1 fecha o app.
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goToPage(_currentPage - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _steps.length,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return OnboardingStepLayout(
                      index: index,
                      total: _steps.length,
                      title: step.title,
                      message: step.message,
                      illustration: step.illustration,
                    );
                  },
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 12, 8),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            const VetoraHeader(),
            const Spacer(),
            // Na última página não há o que pular: o contador ocupa o lugar.
            if (_isLastPage)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text('03 / 03', style: AppTextStyles.rotulo),
              )
            else
              TextButton(
                onPressed: _finishing ? null : _finish,
                child: const Text('Pular'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SizedBox(
        height: 56,
        child: _isLastPage
            ? FilledButton(
                onPressed: _finishing ? null : _finish,
                child: const Text('Começar →'),
              )
            : Row(
                children: [
                  const Text(
                    'Deslize para continuar',
                    style: AppTextStyles.rotulo,
                  ),
                  const Spacer(),
                  // Botão para avançar (exigência do Trabalho 2, item 4.4),
                  // complementar ao gesto de deslizar previsto no Trabalho 1.
                  IconButton.filled(
                    tooltip: 'Próxima etapa',
                    onPressed: () => _goToPage(_currentPage + 1),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.cianoProfundo,
                      foregroundColor: AppColors.ciano,
                      fixedSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
      ),
    );
  }
}
