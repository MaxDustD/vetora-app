import '../domain/content_block.dart';
import '../domain/module_section.dart';

/// Material de demonstração dos módulos, por id do módulo.
///
/// Fica na camada `data`, como os módulos do [FakeStudyModuleRepository]:
/// quando houver uma API, este arquivo deixa de existir e a tela não muda.
/// Fórmulas são escritas em texto (Unicode), sem dependência de LaTeX.
const Map<String, List<ModuleSection>> fakeModuleContent = {
  'calculo-1': _calculo1,
  'mecanica-classica': _mecanicaClassica,
};

// ───────────────────────────── Cálculo 1 ─────────────────────────────

const _calculo1 = [
  ModuleSection(
    id: 'definicao-de-funcao',
    title: 'Definição de função',
    summary: 'Domínio, contradomínio, imagem e composição de funções.',
    blocks: [
      ParagraphBlock(
        'Uma função f de um conjunto A em um conjunto B é uma regra que '
        'associa a cada elemento x de A exatamente um elemento y = f(x) de '
        'B. O conjunto A é o domínio, B é o contradomínio, e o conjunto dos '
        'valores que f realmente assume é a imagem.',
      ),
      FormulaBlock('f : A → B,  x ↦ f(x)', caption: 'Notação de função'),
      ParagraphBlock(
        'A palavra-chave é "exatamente um": um mesmo x não pode ter duas '
        'imagens. Em um gráfico, isso se verifica com o teste da reta '
        'vertical: se alguma reta vertical corta a curva em mais de um '
        'ponto, a curva não é o gráfico de uma função de x.',
      ),
      KeyPointsBlock(
        title: 'Vocabulário',
        items: [
          'Domínio D(f): os valores de entrada permitidos.',
          'Contradomínio: onde as saídas podem estar.',
          'Imagem Im(f): as saídas que de fato ocorrem (Im(f) ⊆ B).',
          'Variável independente: x. Variável dependente: y = f(x).',
        ],
      ),
      ParagraphBlock(
        'Quando só a expressão é dada, o domínio é o maior conjunto de '
        'números reais para os quais ela faz sentido. As restrições mais '
        'comuns: denominador diferente de zero, radicando de raiz de índice '
        'par maior ou igual a zero e logaritmando maior que zero.',
      ),
      ExampleBlock(
        statement: 'Determine o domínio de f(x) = √(x − 2) / (x − 5).',
        steps: [
          'Raiz quadrada: x − 2 ≥ 0, logo x ≥ 2.',
          'Denominador: x − 5 ≠ 0, logo x ≠ 5.',
          'O domínio é a interseção das duas condições.',
        ],
        answer: 'D(f) = [2, 5) ∪ (5, +∞)',
      ),
      ParagraphBlock(
        'Funções podem ser encadeadas: a saída de uma vira a entrada da '
        'outra. Essa operação é a composição, e aparece o tempo todo em '
        'derivadas (regra da cadeia).',
      ),
      FormulaBlock('(g ∘ f)(x) = g(f(x))', caption: 'Função composta'),
      ExampleBlock(
        statement: 'Sendo f(x) = 2x + 1 e g(x) = x², calcule g ∘ f e f ∘ g.',
        steps: [
          '(g ∘ f)(x) = g(2x + 1) = (2x + 1)² = 4x² + 4x + 1.',
          '(f ∘ g)(x) = f(x²) = 2x² + 1.',
        ],
        answer: 'Os resultados são diferentes: a composição não é comutativa.',
      ),
    ],
  ),
  ModuleSection(
    id: 'limite-e-continuidade',
    title: 'Limite e continuidade',
    summary:
        'O comportamento de f(x) perto de um ponto e quando o gráfico '
        'não tem "saltos".',
    blocks: [
      ParagraphBlock(
        'Dizemos que o limite de f(x) quando x tende a a é L se f(x) fica '
        'tão próximo de L quanto quisermos sempre que x estiver '
        'suficientemente próximo de a, com x ≠ a. O valor de f no próprio '
        'ponto a não importa para o limite; f nem precisa estar definida '
        'ali.',
      ),
      FormulaBlock('lim (x→a) f(x) = L'),
      ParagraphBlock(
        'Podemos nos aproximar de a pela esquerda (valores menores) ou pela '
        'direita (valores maiores). O limite existe quando os dois limites '
        'laterais existem e são iguais.',
      ),
      FormulaBlock(
        'lim (x→a⁻) f(x) = lim (x→a⁺) f(x) = L',
        caption: 'Condição de existência do limite',
      ),
      KeyPointsBlock(
        title: 'Propriedades (se os limites de f e g existem)',
        items: [
          'lim [f(x) ± g(x)] = lim f(x) ± lim g(x)',
          'lim [c·f(x)] = c·lim f(x)',
          'lim [f(x)·g(x)] = lim f(x) · lim g(x)',
          'lim [f(x)/g(x)] = lim f(x) / lim g(x), se lim g(x) ≠ 0',
        ],
      ),
      ExampleBlock(
        statement: 'Calcule lim (x→2) (x² − 4) / (x − 2).',
        steps: [
          'Substituindo x = 2 obtemos 0/0: uma indeterminação, não uma '
              'resposta.',
          'Fatorando: x² − 4 = (x − 2)(x + 2).',
          'Para x ≠ 2: (x − 2)(x + 2) / (x − 2) = x + 2.',
          'lim (x→2) (x + 2) = 4.',
        ],
        answer: 'O limite vale 4.',
      ),
      FormulaBlock(
        'lim (x→0) sen(x) / x = 1',
        caption: 'Limite trigonométrico fundamental (x em radianos)',
      ),
      ParagraphBlock(
        'Intuitivamente, uma função é contínua quando seu gráfico pode ser '
        'traçado sem tirar o lápis do papel. Formalmente, f é contínua em '
        'x = a quando três condições valem ao mesmo tempo.',
      ),
      KeyPointsBlock(
        title: 'f é contínua em a se',
        items: [
          '1. f(a) está definida;',
          '2. lim (x→a) f(x) existe;',
          '3. lim (x→a) f(x) = f(a).',
        ],
      ),
      ExampleBlock(
        statement:
            'Seja f(x) = (x² − 4)/(x − 2) para x ≠ 2 e f(2) = 3. '
            'f é contínua em x = 2?',
        steps: [
          'f(2) = 3 está definida.',
          'Pelo exemplo anterior, lim (x→2) f(x) = 4.',
          'Como 4 ≠ 3, a terceira condição falha.',
        ],
        answer:
            'Não. É uma descontinuidade removível: basta redefinir '
            'f(2) = 4.',
      ),
    ],
  ),
  ModuleSection(
    id: 'derivadas',
    title: 'Derivadas',
    summary:
        'Taxa de variação instantânea, regras de derivação e reta '
        'tangente.',
    blocks: [
      ParagraphBlock(
        'A derivada de f em x mede a taxa de variação instantânea de f: '
        'quanto f(x) muda por unidade de x, naquele exato ponto. '
        'Geometricamente, é a inclinação da reta tangente ao gráfico. Ela '
        'nasce como o limite das taxas médias em intervalos cada vez '
        'menores.',
      ),
      FormulaBlock(
        "f'(x) = lim (h→0) [f(x + h) − f(x)] / h",
        caption: 'Definição de derivada',
      ),
      ExampleBlock(
        statement: 'Use a definição para derivar f(x) = x².',
        steps: [
          'f(x + h) − f(x) = (x + h)² − x² = 2xh + h².',
          'Dividindo por h: (2xh + h²) / h = 2x + h.',
          'Quando h → 0: 2x + h → 2x.',
        ],
        answer: "f'(x) = 2x",
      ),
      KeyPointsBlock(
        title: 'Regras de derivação',
        items: [
          "Constante: (c)' = 0",
          "Potência: (xⁿ)' = n·xⁿ⁻¹",
          "Múltiplo: (c·f)' = c·f'",
          "Soma: (f + g)' = f' + g'",
          "Produto: (f·g)' = f'·g + f·g'",
          "Quociente: (f/g)' = (f'·g − f·g') / g²",
          "Cadeia: [f(g(x))]' = f'(g(x))·g'(x)",
        ],
      ),
      KeyPointsBlock(
        title: 'Derivadas que vale saber de cor',
        items: [
          "(sen x)' = cos x",
          "(cos x)' = −sen x",
          "(eˣ)' = eˣ",
          "(ln x)' = 1/x, para x > 0",
        ],
      ),
      FormulaBlock(
        "y − f(a) = f'(a)·(x − a)",
        caption: 'Reta tangente ao gráfico no ponto (a, f(a))',
      ),
      ExampleBlock(
        statement: 'Encontre a reta tangente a y = x³ − 2x no ponto x = 1.',
        steps: [
          'Ponto: f(1) = 1 − 2 = −1, logo (1, −1).',
          "Derivada: f'(x) = 3x² − 2, então f'(1) = 1.",
          'y − (−1) = 1·(x − 1).',
        ],
        answer: 'y = x − 2',
      ),
      ParagraphBlock(
        'Toda função derivável em um ponto é contínua nele, mas a recíproca '
        'é falsa: f(x) = |x| é contínua em x = 0 e não é derivável ali, '
        'porque o gráfico tem um "bico" e as inclinações pela esquerda (−1) '
        'e pela direita (+1) são diferentes.',
      ),
    ],
  ),
];

// ───────────────────────── Mecânica clássica ─────────────────────────

const _mecanicaClassica = [
  ModuleSection(
    id: 'unidades-de-medida',
    title: 'Unidades de medida',
    summary:
        'Sistema Internacional, prefixos, conversões e análise '
        'dimensional.',
    blocks: [
      ParagraphBlock(
        'Uma grandeza física é tudo aquilo que pode ser medido, e toda '
        'medida tem duas partes: um número e uma unidade. "5" não diz '
        'nada; "5 m" e "5 s" dizem coisas completamente diferentes. No '
        'Brasil, o sistema legal é o Sistema Internacional de Unidades (SI).',
      ),
      KeyPointsBlock(
        title: 'As sete grandezas de base do SI',
        items: [
          'Comprimento: metro (m)',
          'Massa: quilograma (kg)',
          'Tempo: segundo (s)',
          'Corrente elétrica: ampere (A)',
          'Temperatura termodinâmica: kelvin (K)',
          'Quantidade de substância: mol (mol)',
          'Intensidade luminosa: candela (cd)',
        ],
      ),
      ParagraphBlock(
        'As demais unidades são derivadas, formadas pela combinação das de '
        'base: velocidade em m/s, aceleração em m/s², e força em newton.',
      ),
      FormulaBlock('1 N = 1 kg·m/s²', caption: 'Newton, unidade de força'),
      KeyPointsBlock(
        title: 'Prefixos mais usados',
        items: [
          'giga (G) = 10⁹',
          'mega (M) = 10⁶',
          'quilo (k) = 10³',
          'centi (c) = 10⁻²',
          'mili (m) = 10⁻³',
          'micro (µ) = 10⁻⁶',
          'nano (n) = 10⁻⁹',
        ],
      ),
      ExampleBlock(
        statement: 'Converta 72 km/h para m/s.',
        steps: [
          'Multiplique por frações iguais a 1, que cancelam as unidades:',
          '72 km/h × (1000 m / 1 km) × (1 h / 3600 s)',
          '= 72 000 m / 3600 s',
        ],
        answer: '20 m/s. Atalho: de km/h para m/s, divida por 3,6.',
      ),
      ParagraphBlock(
        'Análise dimensional: em uma equação física, os dois lados (e cada '
        'parcela de uma soma) precisam ter a mesma dimensão. Usamos L para '
        'comprimento, M para massa e T para tempo. É um jeito rápido de '
        'encontrar erros em contas e fórmulas.',
      ),
      ExampleBlock(
        statement: 'A equação s = s₀ + v·t é dimensionalmente consistente?',
        steps: [
          '[s] = [s₀] = L.',
          '[v·t] = (L·T⁻¹)·T = L.',
          'Todas as parcelas têm dimensão de comprimento.',
        ],
        answer:
            'Sim. (Consistência é necessária, mas não prova que a '
            'fórmula está certa.)',
      ),
    ],
  ),
  ModuleSection(
    id: 'movimento',
    title: 'Movimento',
    summary: 'Deslocamento, velocidade, aceleração, MRU, MRUV e queda livre.',
    blocks: [
      ParagraphBlock(
        'Para descrever um movimento, escolhemos um referencial e uma '
        'origem. A posição s indica onde o corpo está; o deslocamento '
        'Δs = s − s₀ é a variação da posição e pode ser negativo (o corpo '
        'voltou). Já a distância percorrida soma todo o caminho e nunca é '
        'negativa.',
      ),
      FormulaBlock('v_m = Δs / Δt', caption: 'Velocidade média'),
      FormulaBlock('a_m = Δv / Δt', caption: 'Aceleração média'),
      ParagraphBlock(
        'No movimento retilíneo uniforme (MRU) a velocidade é constante e '
        'a aceleração é nula: o corpo percorre distâncias iguais em tempos '
        'iguais.',
      ),
      FormulaBlock('s = s₀ + v·t', caption: 'Função horária do MRU'),
      ParagraphBlock(
        'No movimento retilíneo uniformemente variado (MRUV) a aceleração '
        'é constante. A velocidade muda de forma linear com o tempo e a '
        'posição, de forma quadrática.',
      ),
      KeyPointsBlock(
        title: 'Equações do MRUV',
        items: [
          'v = v₀ + a·t',
          's = s₀ + v₀·t + a·t²/2',
          'v² = v₀² + 2·a·Δs  (Torricelli: não depende do tempo)',
        ],
      ),
      ExampleBlock(
        statement:
            'Um carro a 20 m/s freia com aceleração constante de '
            '−4 m/s². Quanto tempo leva e quanto anda até parar?',
        steps: [
          'Tempo: 0 = 20 + (−4)·t, logo t = 5 s.',
          'Distância (Torricelli): 0² = 20² + 2·(−4)·Δs.',
          '0 = 400 − 8·Δs, logo Δs = 50 m.',
        ],
        answer: 'Para em 5 s, depois de percorrer 50 m.',
      ),
      ParagraphBlock(
        'Queda livre é um MRUV vertical em que a única aceleração é a da '
        'gravidade, g ≈ 9,8 m/s² (é comum usar 10 m/s² em exercícios), '
        'desprezando a resistência do ar. Todos os corpos caem com a mesma '
        'aceleração, independentemente da massa.',
      ),
      ExampleBlock(
        statement:
            'Uma pedra é solta do alto de um prédio de 20 m. Use '
            'g = 10 m/s². Em quanto tempo e com que velocidade ela chega ao '
            'chão?',
        steps: [
          'Partindo do repouso: h = g·t²/2, então 20 = 5·t².',
          't² = 4, logo t = 2 s.',
          'v = g·t = 10 · 2 = 20 m/s.',
        ],
        answer: 'Chega em 2 s, a 20 m/s (72 km/h).',
      ),
    ],
  ),
  ModuleSection(
    id: 'vetores',
    title: 'Vetores',
    summary: 'Grandezas vetoriais, componentes, soma e produto escalar.',
    blocks: [
      ParagraphBlock(
        'Algumas grandezas ficam definidas por um número e uma unidade: são '
        'as escalares, como massa, tempo e temperatura. Outras também '
        'precisam de direção e sentido: são as vetoriais, como '
        'deslocamento, velocidade, aceleração e força. "Andei 3 km" é '
        'incompleto; "andei 3 km para o norte" é um vetor.',
      ),
      KeyPointsBlock(
        title: 'Todo vetor tem',
        items: [
          'Módulo (intensidade): o "tamanho", sempre ≥ 0.',
          'Direção: a reta em que atua (horizontal, 30° com o eixo x…).',
          'Sentido: para qual lado dessa reta aponta.',
        ],
      ),
      FormulaBlock(
        'v = (vx, vy) = vx·î + vy·ĵ',
        caption: 'Vetor no plano pelas suas componentes',
      ),
      FormulaBlock('|v| = √(vx² + vy²)', caption: 'Módulo'),
      KeyPointsBlock(
        title: 'Decomposição (θ medido a partir do eixo x)',
        items: [
          'vx = |v|·cos θ',
          'vy = |v|·sen θ',
          'tg θ = vy / vx  (atenção ao quadrante ao calcular θ)',
        ],
      ),
      ExampleBlock(
        statement:
            'Um projétil é lançado a 20 m/s, formando 30° com a '
            'horizontal. Quais são as componentes da velocidade inicial?',
        steps: [
          'vx = 20·cos 30° ≈ 20 · 0,866 ≈ 17,3 m/s.',
          'vy = 20·sen 30° = 20 · 0,5 = 10 m/s.',
        ],
        answer: 'v₀ ≈ (17,3; 10) m/s',
      ),
      ParagraphBlock(
        'Para somar vetores, somamos componente a componente. '
        'Graficamente, isso equivale a colocar um vetor na ponta do outro '
        '(ou à regra do paralelogramo). Vetores não se somam pelos '
        'módulos: 3 + 4 só dá 7 se os dois apontarem no mesmo sentido.',
      ),
      FormulaBlock('a + b = (ax + bx, ay + by)', caption: 'Soma de vetores'),
      ExampleBlock(
        statement: 'Dados a = (3, 4) e b = (1, −2), calcule a + b e |a|.',
        steps: [
          'a + b = (3 + 1, 4 + (−2)) = (4, 2).',
          '|a| = √(3² + 4²) = √25 = 5.',
        ],
        answer: 'a + b = (4, 2) e |a| = 5',
      ),
      FormulaBlock(
        'a · b = ax·bx + ay·by = |a|·|b|·cos θ',
        caption: 'Produto escalar (o resultado é um número)',
      ),
      ParagraphBlock(
        'O produto escalar mede o quanto dois vetores apontam na mesma '
        'direção. Se for zero, os vetores são perpendiculares. Na física, '
        'aparece no trabalho de uma força: W = F · d. Para a e b acima, '
        'a · b = 3·1 + 4·(−2) = −5: o ângulo entre eles é maior que 90°.',
      ),
    ],
  ),
  ModuleSection(
    id: 'leis-de-newton',
    title: 'Leis de Newton',
    summary: 'Inércia, F = m·a, ação e reação, peso, normal e atrito.',
    blocks: [
      ParagraphBlock(
        'A cinemática descreve o movimento; a dinâmica explica por que ele '
        'muda. A causa é a força: uma interação entre corpos, medida em '
        'newtons. Força é um vetor, então o que importa é a força '
        'resultante, a soma vetorial de todas as forças sobre o corpo.',
      ),
      FormulaBlock(
        'F_R = F₁ + F₂ + … + Fₙ',
        caption: 'Força resultante (soma vetorial)',
      ),
      ParagraphBlock(
        '1ª lei (inércia): se a força resultante sobre um corpo é nula, '
        'ele permanece em repouso ou em MRU. Não é preciso força para '
        'manter um movimento, só para mudá-lo. É por isso que o passageiro '
        'é jogado para a frente quando o ônibus freia.',
      ),
      ParagraphBlock(
        '2ª lei (princípio fundamental): a força resultante produz uma '
        'aceleração na mesma direção e sentido dela, proporcional à força '
        'e inversamente proporcional à massa. A massa mede a inércia: '
        'quanto maior, mais difícil mudar a velocidade.',
      ),
      FormulaBlock('F_R = m·a', caption: '2ª lei de Newton'),
      ParagraphBlock(
        '3ª lei (ação e reação): se A exerce uma força sobre B, B exerce '
        'sobre A uma força de mesmo módulo e direção e sentido oposto. As '
        'duas atuam em corpos diferentes e, por isso, nunca se anulam.',
      ),
      KeyPointsBlock(
        title: 'Forças que aparecem em quase todo exercício',
        items: [
          'Peso: P = m·g, vertical e para baixo (atração da Terra).',
          'Normal (N): perpendicular à superfície de apoio, empurrando o '
              'corpo para fora dela.',
          'Tração (T): ao longo do fio, sempre puxando.',
          'Atrito: paralelo à superfície, contrário ao deslizamento '
              '(ou à tendência de deslizar).',
        ],
      ),
      FormulaBlock(
        'f_at = µ·N',
        caption: 'Atrito cinético (µ: coeficiente de atrito)',
      ),
      KeyPointsBlock(
        title: 'Roteiro para resolver',
        items: [
          '1. Isole o corpo e desenhe todas as forças sobre ele '
              '(diagrama de corpo livre).',
          '2. Escolha os eixos, um deles no sentido da aceleração.',
          '3. Decomponha as forças inclinadas (seção Vetores).',
          '4. Aplique F_R = m·a em cada eixo.',
        ],
      ),
      ExampleBlock(
        statement:
            'Uma caixa de 10 kg é puxada por uma força horizontal de 50 N '
            'sobre um piso com µ = 0,2. Use g = 10 m/s². Qual é a '
            'aceleração?',
        steps: [
          'Vertical: não há aceleração, então N = P = 10 · 10 = 100 N.',
          'Atrito: f_at = 0,2 · 100 = 20 N, contra o movimento.',
          'Horizontal: F_R = 50 − 20 = 30 N.',
          'a = F_R / m = 30 / 10.',
        ],
        answer: 'a = 3 m/s²',
      ),
      ParagraphBlock(
        'Cuidado com uma confusão comum: peso e normal não são par de ação '
        'e reação. Os dois atuam no mesmo corpo. A reação do peso é a força '
        'com que o corpo atrai a Terra; a reação da normal é a força com '
        'que o corpo comprime o piso.',
      ),
      ExampleBlock(
        statement:
            'Uma pessoa de 60 kg está sobre uma balança dentro de um '
            'elevador que sobe acelerando a 2 m/s². Use g = 10 m/s². Quanto '
            'a balança marca?',
        steps: [
          'A balança mede a normal N que ela faz na pessoa.',
          'Eixo para cima (sentido da aceleração): N − P = m·a.',
          'N = m·(g + a) = 60 · (10 + 2) = 720 N.',
        ],
        answer:
            '720 N, mais que o peso de 600 N: a pessoa se sente '
            '"mais pesada".',
      ),
    ],
  ),
];
