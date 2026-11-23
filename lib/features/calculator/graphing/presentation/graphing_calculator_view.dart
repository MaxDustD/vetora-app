import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/calculation_exception.dart';
import '../../domain/compiled_function.dart';
import '../domain/graph_viewport.dart';
import 'graph_painter.dart';

/// Calculadora gráfica: até [maxFunctions] funções de x no mesmo plano.
///
/// - arrastar move o plano; pinça (ou a roda do mouse) dá zoom no ponto
///   tocado; os botões fazem o mesmo para quem não consegue fazer o gesto;
/// - tocar no gráfico mostra o valor de cada função naquele x (traço).
///
/// Precisa de altura limitada (ex.: dentro de um `Expanded`): o gráfico ocupa
/// o espaço que sobra acima do editor de funções.
class GraphingCalculatorView extends StatefulWidget {
  const GraphingCalculatorView({super.key, this.initialExpressions});

  /// Funções iniciais; sem elas, o gráfico começa com `sen(x)`.
  final List<String>? initialExpressions;

  static const maxFunctions = 4;

  /// Nomes e cores, na ordem em que as funções são adicionadas. As cores
  /// têm contraste ≥ 3:1 sobre a superfície do gráfico (objetos gráficos).
  static const names = ['f', 'g', 'h', 'p'];
  static const colors = [
    AppColors.ciano,
    Color(0xFFFFC857),
    Color(0xFF9BC7A4),
    Color(0xFFE58F8F),
  ];

  @override
  State<GraphingCalculatorView> createState() => _GraphingCalculatorViewState();
}

/// Uma linha do editor: o texto digitado e o resultado da leitura dele.
class _FunctionEntry {
  _FunctionEntry({required this.slot, String text = ''})
    : controller = TextEditingController(text: text),
      focusNode = FocusNode();

  /// Posição fixa em [GraphingCalculatorView.names]/colors: o nome e a cor
  /// não mudam quando outra função é removida.
  final int slot;
  final TextEditingController controller;
  final FocusNode focusNode;

  /// Função lida do texto; `null` se o campo está vazio ou inválido.
  CompiledFunction? function;
  String? error;

  String get name => GraphingCalculatorView.names[slot];
  Color get color => GraphingCalculatorView.colors[slot];

  /// Lê o texto uma vez; o gráfico avalia a função compilada a cada pixel.
  /// Vazio não é erro: só não desenha nada.
  void parse() {
    final source = controller.text.trim();
    function = null;
    error = null;
    if (source.isEmpty) return;
    try {
      // Já recusa outras variáveis além de x, com mensagem em português.
      function = compileFunction(source);
    } on CalculationException catch (e) {
      error = e.message;
    }
  }

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

class _GraphingCalculatorViewState extends State<GraphingCalculatorView> {
  final _entries = <_FunctionEntry>[];

  /// Janela "lógica". A janela desenhada é esta com a altura ajustada à
  /// proporção da tela ([GraphViewport.withAspectRatio]).
  GraphViewport _viewport = GraphViewport.initial;
  Size _graphSize = Size.zero;
  double? _traceX;

  /// Linha que recebe os atalhos de inserção (x, π, sen…).
  int _activeEntry = 0;

  // Estado do gesto de pinça em andamento.
  Offset? _lastFocalPoint;
  double _lastScale = 1;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialExpressions ?? const ['sen(x)'];
    for (final text in initial.take(GraphingCalculatorView.maxFunctions)) {
      _addEntry(text);
    }
    if (_entries.isEmpty) _addEntry('');
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  GraphViewport get _shown => _graphSize.isEmpty
      ? _viewport
      : _viewport.withAspectRatio(_graphSize.width, _graphSize.height);

  List<_FunctionEntry> get _plotted => [
    for (final entry in _entries)
      if (entry.function != null) entry,
  ];

  // ─── Funções ───

  void _addEntry([String text = '']) {
    final used = {for (final e in _entries) e.slot};
    final slot = List.generate(
      GraphingCalculatorView.maxFunctions,
      (i) => i,
    ).firstWhere((i) => !used.contains(i));
    final entry = _FunctionEntry(slot: slot, text: text)..parse();
    final index = _entries.length;
    entry.focusNode.addListener(() {
      if (entry.focusNode.hasFocus) {
        _activeEntry = _entries.indexOf(entry);
      }
    });
    _entries.add(entry);
    _activeEntry = index;
  }

  void _onAdd() {
    setState(() => _addEntry());
    _entries.last.focusNode.requestFocus();
  }

  void _onRemove(_FunctionEntry entry) {
    setState(() {
      if (_entries.length == 1) {
        entry.controller.clear();
        entry.parse();
        return;
      }
      _entries.remove(entry);
      entry.dispose();
      _activeEntry = _activeEntry.clamp(0, _entries.length - 1);
    });
  }

  void _onChanged(_FunctionEntry entry) {
    setState(entry.parse);
  }

  /// Insere [text] no cursor da linha ativa. Se o texto termina em "(",
  /// fecha o parêntese e deixa o cursor dentro dele.
  void _insert(String text) {
    final entry = _entries[_activeEntry];
    final controller = entry.controller;
    final value = controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final insertion = text.endsWith('(') ? '$text)' : text;
    final newText = value.text.replaceRange(
      selection.start,
      selection.end,
      insertion,
    );
    final cursor =
        selection.start + insertion.length - (text.endsWith('(') ? 1 : 0);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor),
    );
    entry.focusNode.requestFocus();
    _onChanged(entry);
  }

  // ─── Navegação no plano ───

  void _zoomBy(double factor, {Offset? focus}) {
    final shown = _shown;
    final f = focus;
    setState(() {
      _viewport = shown.zoom(
        factor,
        focusX: f == null ? null : shown.toWorldX(f.dx, _graphSize.width),
        focusY: f == null ? null : shown.toWorldY(f.dy, _graphSize.height),
      );
    });
  }

  void _panByPixels(Offset delta) {
    final shown = _shown;
    setState(() {
      _viewport = shown.panBy(
        -delta.dx / _graphSize.width * shown.width,
        delta.dy / _graphSize.height * shown.height,
      );
    });
  }

  void _reset() {
    setState(() {
      _viewport = GraphViewport.initial;
      _traceX = null;
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.localFocalPoint;
    _lastScale = 1;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final last = _lastFocalPoint;
    if (last == null || _graphSize.isEmpty) return;
    // Pinça: zoom no ponto entre os dedos; arrastar: desloca o plano. Os
    // dois podem acontecer no mesmo gesto.
    final factor = details.scale / _lastScale;
    if ((factor - 1).abs() > 0.001) {
      _zoomBy(factor, focus: details.localFocalPoint);
    }
    _panByPixels(details.localFocalPoint - last);
    _lastFocalPoint = details.localFocalPoint;
    _lastScale = details.scale;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // Roda do mouse (desktop/web): rolar para cima aproxima.
      _zoomBy(
        event.scrollDelta.dy < 0 ? 1.15 : 1 / 1.15,
        focus: event.localPosition,
      );
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _traceX = _shown.toWorldX(details.localPosition.dx, _graphSize.width);
    });
  }

  // ─── Construção ───

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          Expanded(child: _buildGraph(context)),
          // Leitura e editor dividem no máximo metade da altura e rolam
          // juntos: com fonte ampliada ou teclado aberto, o gráfico continua
          // com pelo menos a outra metade.
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight / 2),
            child: SingleChildScrollView(
              child: Column(children: [_buildReadout(), _buildEditor()]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraph(BuildContext context) {
    final plotted = _plotted;
    final shown = _shown;
    final description = plotted.isEmpty
        ? 'Gráfico vazio. Digite uma função abaixo.'
        : 'Gráfico de ${plotted.map((e) => '${e.name}(x) = ${e.function!.input}').join('; ')}. '
              'x de ${formatTraceValue(shown.xMin)} a ${formatTraceValue(shown.xMax)}.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borda),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _graphSize = constraints.biggest;
                    return Semantics(
                      label: description,
                      image: true,
                      child: Listener(
                        onPointerSignal: _onPointerSignal,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onScaleStart: _onScaleStart,
                          onScaleUpdate: _onScaleUpdate,
                          onTapUp: _onTapUp,
                          child: CustomPaint(
                            size: constraints.biggest,
                            painter: GraphPainter(
                              viewport: _shown,
                              curves: [
                                for (final e in plotted)
                                  PlottedCurve(
                                    function: e.function!.call,
                                    color: e.color,
                                  ),
                              ],
                              traceX: _traceX,
                              textScaler: MediaQuery.textScalerOf(context),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Column(
                  children: [
                    _GraphButton(
                      tooltip: 'Aproximar',
                      icon: Icons.add_rounded,
                      onPressed: () => _zoomBy(1.5),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _GraphButton(
                      tooltip: 'Afastar',
                      icon: Icons.remove_rounded,
                      onPressed: () => _zoomBy(1 / 1.5),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _GraphButton(
                      tooltip: 'Centralizar',
                      icon: Icons.center_focus_strong_outlined,
                      onPressed: _reset,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Leitura do traço, ou a dica de uso enquanto não há traço.
  Widget _buildReadout() {
    final x = _traceX;
    final plotted = _plotted;

    final Widget content;
    if (x == null || plotted.isEmpty) {
      content = const Text(
        'Toque no gráfico para ler os valores. Arraste para mover e use a '
        'pinça para o zoom.',
        style: AppTextStyles.apoio,
      );
    } else {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                Text('x = ${formatTraceValue(x)}', style: _mono()),
                for (final e in plotted)
                  Text(
                    '${e.name}(x) = ${formatTraceValue(e.function!(x))}',
                    style: _mono(color: e.color),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              tooltip: 'Remover leitura',
              onPressed: () => setState(() => _traceX = null),
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.textoSecundario,
            ),
          ),
        ],
      );
    }

    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          0,
        ),
        child: SizedBox(width: double.infinity, child: content),
      ),
    );
  }

  Widget _buildEditor() {
    final canAdd = _entries.length < GraphingCalculatorView.maxFunctions;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (label, insert) in _shortcuts) ...[
                  ActionChip(
                    label: Text(label, style: _mono(size: 13)),
                    tooltip: 'Inserir $label',
                    onPressed: () => _insert(insert),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in _entries) ...[
            _FunctionField(
              key: ObjectKey(entry),
              entry: entry,
              onChanged: () => _onChanged(entry),
              onRemove: () => _onRemove(entry),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (canAdd)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _onAdd,
                style: TextButton.styleFrom(foregroundColor: AppColors.ciano),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Adicionar função'),
              ),
            ),
        ],
      ),
    );
  }

  static const _shortcuts = [
    ('x', 'x'),
    ('x²', 'x^2'),
    ('^', '^'),
    ('π', 'π'),
    ('√', 'raiz('),
    ('sen', 'sen('),
    ('cos', 'cos('),
    ('tg', 'tg('),
    ('ln', 'ln('),
    ('|x|', 'abs('),
  ];

  static TextStyle _mono({Color? color, double size = 14}) => TextStyle(
    fontFamily: AppTheme.fontMono,
    fontSize: size,
    color: color ?? AppColors.brancoTecnico,
  );
}

class _FunctionField extends StatelessWidget {
  const _FunctionField({
    super.key,
    required this.entry,
    required this.onChanged,
    required this.onRemove,
  });

  final _FunctionEntry entry;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: entry.controller,
      focusNode: entry.focusNode,
      onChanged: (_) => onChanged(),
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        fontFamily: AppTheme.fontMono,
        fontSize: 16,
        color: AppColors.brancoTecnico,
      ),
      decoration: InputDecoration(
        // A cor identifica a curva; o nome também, para não depender dela.
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: entry.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${entry.name}(x) =',
                style: TextStyle(
                  fontFamily: AppTheme.fontMono,
                  fontSize: 16,
                  color: entry.color,
                ),
              ),
            ],
          ),
        ),
        hintText: 'ex.: x^2 − 2x + 1',
        errorText: entry.error,
        errorMaxLines: 3,
        filled: true,
        fillColor: AppColors.superficie,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.borda),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.borda),
        ),
        suffixIcon: IconButton(
          tooltip: 'Remover ${entry.name}(x)',
          onPressed: onRemove,
          icon: const Icon(Icons.close_rounded),
          color: AppColors.textoSecundario,
        ),
      ),
    );
  }
}

class _GraphButton extends StatelessWidget {
  const _GraphButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.superficieElevada.withValues(alpha: 0.92),
        foregroundColor: AppColors.brancoTecnico,
        minimumSize: const Size(48, 48),
      ),
    );
  }
}
