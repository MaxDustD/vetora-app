import 'package:flutter/material.dart';

import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../graphing/presentation/graphing_calculator_view.dart';
import 'solver/solver_view.dart';

/// Aba "Calculadora": dois modos, cálculos (com passo a passo) e gráfico.
///
/// Sem Scaffold nem SafeArea: é o conteúdo de uma aba do AppShell, que
/// envolve a página na área segura.
class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

enum _Mode { solver, graph }

class _CalculatorPageState extends State<CalculatorPage> {
  var _mode = _Mode.solver;

  @override
  Widget build(BuildContext context) {
    final padding = AppLayout.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            padding,
            AppSpacing.md,
            padding,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Calculadora',
                  style: AppTextStyles.secao.copyWith(fontSize: 22),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<_Mode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: _Mode.solver,
                    icon: Icon(Icons.functions_rounded),
                    label: Text('Cálculos'),
                  ),
                  ButtonSegment(
                    value: _Mode.graph,
                    icon: Icon(Icons.show_chart_rounded),
                    label: Text('Gráfico'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.single),
              ),
            ],
          ),
        ),
        // IndexedStack mantém os dois modos vivos: trocar de modo não apaga
        // o que foi digitado. O Expanded dá ao gráfico a altura limitada
        // de que ele precisa.
        Expanded(
          child: IndexedStack(
            index: _mode.index,
            children: const [SolverView(), GraphingCalculatorView()],
          ),
        ),
      ],
    );
  }
}
