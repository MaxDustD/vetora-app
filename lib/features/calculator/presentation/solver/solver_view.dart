import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/calculator_engine.dart';
import 'calculation_result_card.dart';

/// Modo "Cálculos" da calculadora: escolhe a operação, digita a expressão e
/// vê o resultado com o passo a passo.
///
/// Hierarquia: 1. o que fazer (operação) → 2. com o quê (expressão e
/// parâmetros) → 3. ação (Calcular) → 4. resposta.
class SolverView extends StatefulWidget {
  const SolverView({super.key, this.engine = const CalculatorEngine()});

  final CalculatorEngine engine;

  @override
  State<SolverView> createState() => _SolverViewState();
}

class _SolverViewState extends State<SolverView> {
  var _operation = CalculatorOperation.evaluate;
  var _side = LimitSide.both;
  var _order = 1;
  var _taylorOrder = 5;

  final _expression = TextEditingController();
  final _expressionFocus = FocusNode();

  /// Campo extra: ponto (derivada, limite, Taylor) ou limite inferior.
  final _point = TextEditingController();
  final _pointFocus = FocusNode();

  /// Limite superior da integral.
  final _upper = TextEditingController();
  final _upperFocus = FocusNode();

  /// Último campo de texto focado: recebe os atalhos de símbolos.
  TextEditingController? _target;

  CalculationResult? _result;
  String? _error;
  String? _pointError;

  @override
  void initState() {
    super.initState();
    _target = _expression;
    for (final (focus, controller) in [
      (_expressionFocus, _expression),
      (_pointFocus, _point),
      (_upperFocus, _upper),
    ]) {
      focus.addListener(() {
        if (focus.hasFocus) _target = controller;
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_expression, _point, _upper]) {
      c.dispose();
    }
    for (final f in [_expressionFocus, _pointFocus, _upperFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  void _selectOperation(CalculatorOperation operation) {
    setState(() {
      _operation = operation;
      _result = null;
      _error = null;
      _pointError = null;
      _point.text = switch (operation) {
        CalculatorOperation.limit => '0',
        CalculatorOperation.taylor => '0',
        _ => '',
      };
      _upper.clear();
    });
  }

  String? _optional(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  void _calculate() {
    final source = _expression.text;
    final engine = widget.engine;
    setState(() {
      _error = null;
      _pointError = null;
    });
    try {
      final result = switch (_operation) {
        CalculatorOperation.evaluate => engine.evaluate(source),
        CalculatorOperation.simplify => engine.simplify(source),
        CalculatorOperation.expand => engine.expand(source),
        CalculatorOperation.derivative => engine.derivative(
          source,
          order: _order,
          at: _optional(_point),
        ),
        CalculatorOperation.integral => engine.integral(
          source,
          lower: _optional(_point),
          upper: _optional(_upper),
        ),
        CalculatorOperation.limit => engine.limit(
          source,
          point: _point.text,
          side: _side,
        ),
        CalculatorOperation.solve => engine.solve(source),
        CalculatorOperation.taylor => engine.taylor(
          source,
          point: _optional(_point) ?? '0',
          order: _taylorOrder,
        ),
      };
      setState(() => _result = result);
    } on CalculationException catch (e) {
      setState(() {
        _result = null;
        // Mensagens sobre o ponto ou os limites vão para o campo deles.
        final aboutPoint =
            e.message.startsWith('O ponto') ||
            e.message.startsWith('O limite') ||
            e.message.startsWith('Informe os dois');
        if (aboutPoint && _operation != CalculatorOperation.evaluate) {
          _pointError = e.message;
        } else {
          _error = e.message;
          final p = e.position;
          if (p != null && p <= source.length) {
            // Leva o cursor ao caractere com problema.
            _expression.selection = TextSelection.collapsed(offset: p);
            _expressionFocus.requestFocus();
          }
        }
      });
    }
  }

  /// Insere [template] na posição do cursor; `|` marca onde o cursor fica
  /// (`sen(|)` deixa o cursor dentro dos parênteses).
  void _insert(String template) {
    final c = _target ?? _expression;
    final caret = template.indexOf('|');
    final text = template.replaceAll('|', '');
    final selection = c.selection;
    final start = selection.isValid ? selection.start : c.text.length;
    final end = selection.isValid ? selection.end : c.text.length;
    c.value = TextEditingValue(
      text: c.text.replaceRange(start, end, text),
      selection: TextSelection.collapsed(
        offset: start + (caret < 0 ? text.length : caret),
      ),
    );
    (c == _expression
            ? _expressionFocus
            : c == _point
            ? _pointFocus
            : _upperFocus)
        .requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final padding = AppLayout.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );
    final result = _result;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        padding,
        AppSpacing.md,
        padding,
        AppSpacing.xl,
      ),
      children: [
        _OperationPicker(selected: _operation, onSelected: _selectOperation),
        const SizedBox(height: AppSpacing.lg),
        _MathField(
          controller: _expression,
          focusNode: _expressionFocus,
          label: _operation == CalculatorOperation.solve
              ? 'Equação'
              : (_operation == CalculatorOperation.evaluate
                    ? 'Expressão'
                    : 'f(x)'),
          hint: _operation.hint,
          error: _error,
          onSubmitted: _calculate,
        ),
        ..._parameters(),
        const SizedBox(height: AppSpacing.sm),
        _SymbolBar(
          onInsert: _insert,
          showInfinity:
              _operation == CalculatorOperation.limit ||
              _operation == CalculatorOperation.integral,
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(onPressed: _calculate, child: Text(_operation.label)),
        if (result != null) ...[
          const SizedBox(height: AppSpacing.lg),
          CalculationResultCard(result: result),
        ],
      ],
    );
  }

  /// Campos que dependem da operação.
  List<Widget> _parameters() {
    const gap = SizedBox(height: AppSpacing.md);
    switch (_operation) {
      case CalculatorOperation.derivative:
        return [
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Stepper(
                label: 'Ordem',
                value: _order,
                min: 1,
                max: 5,
                onChanged: (v) => setState(() => _order = v),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MathField(
                  controller: _point,
                  focusNode: _pointFocus,
                  label: 'No ponto x = (opcional)',
                  hint: 'ex.: 2',
                  error: _pointError,
                  onSubmitted: _calculate,
                ),
              ),
            ],
          ),
        ];
      case CalculatorOperation.integral:
        return [
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MathField(
                  controller: _point,
                  focusNode: _pointFocus,
                  label: 'De',
                  hint: 'ex.: 0',
                  error: _pointError,
                  onSubmitted: _calculate,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MathField(
                  controller: _upper,
                  focusNode: _upperFocus,
                  label: 'Até',
                  hint: 'ex.: π',
                  onSubmitted: _calculate,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Sem limites, a integral é indefinida (+ C).',
            style: AppTextStyles.apoio,
          ),
        ];
      case CalculatorOperation.limit:
        return [
          gap,
          _MathField(
            controller: _point,
            focusNode: _pointFocus,
            label: 'x tende a',
            hint: 'ex.: 0, π/2 ou ∞',
            error: _pointError,
            onSubmitted: _calculate,
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<LimitSide>(
            showSelectedIcon: false,
            segments: [
              for (final side in LimitSide.values)
                ButtonSegment(
                  value: side,
                  tooltip: side.label,
                  // Rótulos curtos: os três cabem lado a lado em 360 dp.
                  label: Text(switch (side) {
                    LimitSide.both => 'Bilateral',
                    LimitSide.left => 'x → a⁻',
                    LimitSide.right => 'x → a⁺',
                  }),
                ),
            ],
            selected: {_side},
            onSelectionChanged: (s) => setState(() => _side = s.single),
          ),
        ];
      case CalculatorOperation.taylor:
        return [
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Stepper(
                label: 'Ordem',
                value: _taylorOrder,
                min: 1,
                max: 10,
                onChanged: (v) => setState(() => _taylorOrder = v),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MathField(
                  controller: _point,
                  focusNode: _pointFocus,
                  label: 'Em torno de x =',
                  hint: 'ex.: 0',
                  error: _pointError,
                  onSubmitted: _calculate,
                ),
              ),
            ],
          ),
        ];
      default:
        return const [];
    }
  }
}

/// Operações em chips: todas visíveis de uma vez, quebrando linha se
/// preciso (com fonte ampliada, os chips descem em vez de cortar).
class _OperationPicker extends StatelessWidget {
  const _OperationPicker({required this.selected, required this.onSelected});

  final CalculatorOperation selected;
  final ValueChanged<CalculatorOperation> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final op in CalculatorOperation.values)
          ChoiceChip(
            label: Text(op.label),
            selected: op == selected,
            onSelected: (_) => onSelected(op),
            showCheckmark: false,
            labelStyle: TextStyle(
              fontFamily: AppTheme.fontText,
              fontWeight: FontWeight.w600,
              color: op == selected
                  ? AppColors.grafite
                  : AppColors.brancoTecnico,
            ),
            selectedColor: AppColors.ciano,
            backgroundColor: AppColors.superficie,
            side: BorderSide(
              color: op == selected ? AppColors.ciano : AppColors.borda,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
      ],
    );
  }
}

class _MathField extends StatelessWidget {
  const _MathField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.onSubmitted,
    this.error,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final String? error;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: const BorderSide(color: AppColors.borda),
    );
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autocorrect: false,
      enableSuggestions: false,
      // Teclado sem autocorreção nem maiúscula automática.
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmitted(),
      style: const TextStyle(
        fontFamily: AppTheme.fontMono,
        fontSize: 16,
        color: AppColors.brancoTecnico,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
        errorMaxLines: 4,
        filled: true,
        fillColor: AppColors.superficie,
        border: border,
        enabledBorder: border,
      ),
    );
  }
}

/// Atalhos para símbolos difíceis de digitar no teclado do celular.
class _SymbolBar extends StatelessWidget {
  const _SymbolBar({required this.onInsert, required this.showInfinity});

  final ValueChanged<String> onInsert;
  final bool showInfinity;

  @override
  Widget build(BuildContext context) {
    final symbols = <(String, String, String)>[
      ('x', 'x', 'variável x'),
      ('^', '^', 'potência'),
      ('√', '√(|)', 'raiz quadrada'),
      ('π', 'π', 'pi'),
      ('e', 'e', 'número de Euler'),
      ('sen', 'sen(|)', 'seno'),
      ('cos', 'cos(|)', 'cosseno'),
      ('ln', 'ln(|)', 'logaritmo natural'),
      ('( )', '(|)', 'parênteses'),
      if (showInfinity) ('∞', '∞', 'infinito'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (label, text, name) in symbols)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Semantics(
                button: true,
                label: 'Inserir $name',
                excludeSemantics: true,
                child: ActionChip(
                  label: Text(label),
                  onPressed: () => onInsert(text),
                  labelStyle: const TextStyle(
                    fontFamily: AppTheme.fontMono,
                    fontSize: 15,
                    color: AppColors.ciano,
                  ),
                  backgroundColor: AppColors.superficieElevada,
                  side: const BorderSide(color: AppColors.borda),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Seletor numérico compacto (− valor +), com 48 dp de área de toque.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.rotulo),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: AppColors.superficie,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.borda),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Diminuir ${label.toLowerCase()}',
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Semantics(
                label: '$label $value',
                excludeSemantics: true,
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontMono,
                    fontSize: 16,
                    color: AppColors.brancoTecnico,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Aumentar ${label.toLowerCase()}',
                onPressed: value < max ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
