-- =============================================================================
-- Vetora — 02_seed.sql
-- Massa de dados do catálogo: 6 módulos, seus detalhes, seções e blocos.
--
-- ARQUIVO GERADO por tool/generate_supabase_seed.dart a partir dos mesmos
-- dados que o app grava no SQLite local. Para mudar o conteúdo, edite
-- lib/features/modules/data/ e rode:
--   dart run tool/generate_supabase_seed.dart > supabase/02_seed.sql
--
-- UUIDs determinísticos (prefixo = tabela):
--   a0000000-… study_modules      d0000000-… study_module_details
--   b0000000-… module_sections    c0000000-… content_blocks
--
-- Idempotente: "on conflict (id) do nothing" permite rodar de novo.
-- Execute DEPOIS do 01_schema.sql (no SQL Editor, que usa a service_role).
-- =============================================================================

begin;

-- 1. Módulos (entidade principal)
insert into public.study_modules
  (id, slug, title, subtitle, area, topic_count, duration_in_minutes, resources, average_rating, popularity_rank, cover_image_path)
values
  ('a0000000-0000-4000-8000-000000000001', 'calculo-1', 'Cálculo 1', 'Funções, limites e derivadas', 'mathematics', 3, 150, array['theory', 'solved_exercises']::text[], 4.8, 1, 'calculo-1/capa.png'),
  ('a0000000-0000-4000-8000-000000000002', 'mecanica-classica', 'Mecânica clássica', 'Física 1', 'physics', 4, 180, array['theory', 'solved_exercises', 'calculator']::text[], 4.7, 2, 'mecanica-classica/capa.png'),
  ('a0000000-0000-4000-8000-000000000003', 'circuitos-eletricos', 'Circuitos elétricos', '', 'electrical', 9, 75, array['theory', 'calculator']::text[], 4.5, 3, 'circuitos-eletricos/capa.png'),
  ('a0000000-0000-4000-8000-000000000004', 'resistencia-dos-materiais', 'Resistência dos materiais', '', 'civil', 10, 120, array['theory', 'solved_exercises']::text[], 4.3, 4, 'resistencia-dos-materiais/capa.png'),
  ('a0000000-0000-4000-8000-000000000005', 'termodinamica', 'Termodinâmica', '', 'mechanical', 8, 60, array['theory', 'solved_exercises']::text[], 4.1, 5, 'termodinamica/capa.png'),
  ('a0000000-0000-4000-8000-000000000006', 'eletromagnetismo', 'Eletromagnetismo e ondas eletromagnéticas', '', 'physics', 1, 45, array['theory']::text[], 3.9, 6, 'eletromagnetismo/capa.png')
on conflict (id) do nothing;

-- 2. Detalhes 1:1 (só os módulos que já têm apresentação)
insert into public.study_module_details (id, module_id, description)
values
  ('d0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001',
   'A base matemática da engenharia: o que é uma função, como ela se comporta perto de um ponto e como medir a sua taxa de variação.'),
  ('d0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000002',
   'Equivalente a Física 1: unidades de medida, descrição do movimento em uma dimensão, a linguagem dos vetores e as leis de Newton.')
on conflict (id) do nothing;

-- 3. Seções (filhas 1:N dos módulos)
insert into public.module_sections (id, module_id, slug, position, title, summary)
values
  ('b0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'definicao-de-funcao', 0, 'Definição de função',
   'Domínio, contradomínio, imagem e composição de funções.'),
  ('b0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000001', 'limite-e-continuidade', 1, 'Limite e continuidade',
   'O comportamento de f(x) perto de um ponto e quando o gráfico não tem "saltos".'),
  ('b0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000001', 'derivadas', 2, 'Derivadas',
   'Taxa de variação instantânea, regras de derivação e reta tangente.'),
  ('b0000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000002', 'unidades-de-medida', 0, 'Unidades de medida',
   'Sistema Internacional, prefixos, conversões e análise dimensional.'),
  ('b0000000-0000-4000-8000-000000000005', 'a0000000-0000-4000-8000-000000000002', 'movimento', 1, 'Movimento',
   'Deslocamento, velocidade, aceleração, MRU, MRUV e queda livre.'),
  ('b0000000-0000-4000-8000-000000000006', 'a0000000-0000-4000-8000-000000000002', 'vetores', 2, 'Vetores',
   'Grandezas vetoriais, componentes, soma e produto escalar.'),
  ('b0000000-0000-4000-8000-000000000007', 'a0000000-0000-4000-8000-000000000002', 'leis-de-newton', 3, 'Leis de Newton',
   'Inércia, F = m·a, ação e reação, peso, normal e atrito.')
on conflict (id) do nothing;

-- 4. Blocos de conteúdo (filhos 1:N das seções)
insert into public.content_blocks (id, section_id, position, kind, payload)
values
  ('c0000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000001', 0, 'paragraph',
   '{"text":"Uma função f de um conjunto A em um conjunto B é uma regra que associa a cada elemento x de A exatamente um elemento y = f(x) de B. O conjunto A é o domínio, B é o contradomínio, e o conjunto dos valores que f realmente assume é a imagem."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000001', 1, 'formula',
   '{"expression":"f : A → B,  x ↦ f(x)","caption":"Notação de função"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000003', 'b0000000-0000-4000-8000-000000000001', 2, 'paragraph',
   '{"text":"A palavra-chave é \"exatamente um\": um mesmo x não pode ter duas imagens. Em um gráfico, isso se verifica com o teste da reta vertical: se alguma reta vertical corta a curva em mais de um ponto, a curva não é o gráfico de uma função de x."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000004', 'b0000000-0000-4000-8000-000000000001', 3, 'key_points',
   '{"title":"Vocabulário","items":["Domínio D(f): os valores de entrada permitidos.","Contradomínio: onde as saídas podem estar.","Imagem Im(f): as saídas que de fato ocorrem (Im(f) ⊆ B).","Variável independente: x. Variável dependente: y = f(x)."]}'::jsonb),
  ('c0000000-0000-4000-8000-000000000005', 'b0000000-0000-4000-8000-000000000001', 4, 'paragraph',
   '{"text":"Quando só a expressão é dada, o domínio é o maior conjunto de números reais para os quais ela faz sentido. As restrições mais comuns: denominador diferente de zero, radicando de raiz de índice par maior ou igual a zero e logaritmando maior que zero."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000006', 'b0000000-0000-4000-8000-000000000001', 5, 'example',
   '{"statement":"Determine o domínio de f(x) = √(x − 2) / (x − 5).","steps":["Raiz quadrada: x − 2 ≥ 0, logo x ≥ 2.","Denominador: x − 5 ≠ 0, logo x ≠ 5.","O domínio é a interseção das duas condições."],"answer":"D(f) = [2, 5) ∪ (5, +∞)"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000007', 'b0000000-0000-4000-8000-000000000001', 6, 'paragraph',
   '{"text":"Funções podem ser encadeadas: a saída de uma vira a entrada da outra. Essa operação é a composição, e aparece o tempo todo em derivadas (regra da cadeia)."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000008', 'b0000000-0000-4000-8000-000000000001', 7, 'formula',
   '{"expression":"(g ∘ f)(x) = g(f(x))","caption":"Função composta"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000009', 'b0000000-0000-4000-8000-000000000001', 8, 'example',
   '{"statement":"Sendo f(x) = 2x + 1 e g(x) = x², calcule g ∘ f e f ∘ g.","steps":["(g ∘ f)(x) = g(2x + 1) = (2x + 1)² = 4x² + 4x + 1.","(f ∘ g)(x) = f(x²) = 2x² + 1."],"answer":"Os resultados são diferentes: a composição não é comutativa."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000010', 'b0000000-0000-4000-8000-000000000002', 0, 'paragraph',
   '{"text":"Dizemos que o limite de f(x) quando x tende a a é L se f(x) fica tão próximo de L quanto quisermos sempre que x estiver suficientemente próximo de a, com x ≠ a. O valor de f no próprio ponto a não importa para o limite; f nem precisa estar definida ali."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000011', 'b0000000-0000-4000-8000-000000000002', 1, 'formula',
   '{"expression":"lim (x→a) f(x) = L"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000012', 'b0000000-0000-4000-8000-000000000002', 2, 'paragraph',
   '{"text":"Podemos nos aproximar de a pela esquerda (valores menores) ou pela direita (valores maiores). O limite existe quando os dois limites laterais existem e são iguais."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000013', 'b0000000-0000-4000-8000-000000000002', 3, 'formula',
   '{"expression":"lim (x→a⁻) f(x) = lim (x→a⁺) f(x) = L","caption":"Condição de existência do limite"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000014', 'b0000000-0000-4000-8000-000000000002', 4, 'key_points',
   '{"title":"Propriedades (se os limites de f e g existem)","items":["lim [f(x) ± g(x)] = lim f(x) ± lim g(x)","lim [c·f(x)] = c·lim f(x)","lim [f(x)·g(x)] = lim f(x) · lim g(x)","lim [f(x)/g(x)] = lim f(x) / lim g(x), se lim g(x) ≠ 0"]}'::jsonb),
  ('c0000000-0000-4000-8000-000000000015', 'b0000000-0000-4000-8000-000000000002', 5, 'example',
   '{"statement":"Calcule lim (x→2) (x² − 4) / (x − 2).","steps":["Substituindo x = 2 obtemos 0/0: uma indeterminação, não uma resposta.","Fatorando: x² − 4 = (x − 2)(x + 2).","Para x ≠ 2: (x − 2)(x + 2) / (x − 2) = x + 2.","lim (x→2) (x + 2) = 4."],"answer":"O limite vale 4."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000016', 'b0000000-0000-4000-8000-000000000002', 6, 'formula',
   '{"expression":"lim (x→0) sen(x) / x = 1","caption":"Limite trigonométrico fundamental (x em radianos)"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000017', 'b0000000-0000-4000-8000-000000000002', 7, 'paragraph',
   '{"text":"Intuitivamente, uma função é contínua quando seu gráfico pode ser traçado sem tirar o lápis do papel. Formalmente, f é contínua em x = a quando três condições valem ao mesmo tempo."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000018', 'b0000000-0000-4000-8000-000000000002', 8, 'key_points',
   '{"title":"f é contínua em a se","items":["1. f(a) está definida;","2. lim (x→a) f(x) existe;","3. lim (x→a) f(x) = f(a)."]}'::jsonb),
  ('c0000000-0000-4000-8000-000000000019', 'b0000000-0000-4000-8000-000000000002', 9, 'example',
   '{"statement":"Seja f(x) = (x² − 4)/(x − 2) para x ≠ 2 e f(2) = 3. f é contínua em x = 2?","steps":["f(2) = 3 está definida.","Pelo exemplo anterior, lim (x→2) f(x) = 4.","Como 4 ≠ 3, a terceira condição falha."],"answer":"Não. É uma descontinuidade removível: basta redefinir f(2) = 4."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000020', 'b0000000-0000-4000-8000-000000000003', 0, 'paragraph',
   '{"text":"A derivada de f em x mede a taxa de variação instantânea de f: quanto f(x) muda por unidade de x, naquele exato ponto. Geometricamente, é a inclinação da reta tangente ao gráfico. Ela nasce como o limite das taxas médias em intervalos cada vez menores."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000021', 'b0000000-0000-4000-8000-000000000003', 1, 'formula',
   '{"expression":"f''(x) = lim (h→0) [f(x + h) − f(x)] / h","caption":"Definição de derivada"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000022', 'b0000000-0000-4000-8000-000000000003', 2, 'example',
   '{"statement":"Use a definição para derivar f(x) = x².","steps":["f(x + h) − f(x) = (x + h)² − x² = 2xh + h².","Dividindo por h: (2xh + h²) / h = 2x + h.","Quando h → 0: 2x + h → 2x."],"answer":"f''(x) = 2x"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000023', 'b0000000-0000-4000-8000-000000000003', 3, 'key_points',
   '{"title":"Regras de derivação","items":["Constante: (c)'' = 0","Potência: (xⁿ)'' = n·xⁿ⁻¹","Múltiplo: (c·f)'' = c·f''","Soma: (f + g)'' = f'' + g''","Produto: (f·g)'' = f''·g + f·g''","Quociente: (f/g)'' = (f''·g − f·g'') / g²","Cadeia: [f(g(x))]'' = f''(g(x))·g''(x)"]}'::jsonb),
  ('c0000000-0000-4000-8000-000000000024', 'b0000000-0000-4000-8000-000000000003', 4, 'key_points',
   '{"title":"Derivadas que vale saber de cor","items":["(sen x)'' = cos x","(cos x)'' = −sen x","(eˣ)'' = eˣ","(ln x)'' = 1/x, para x > 0"]}'::jsonb),
  ('c0000000-0000-4000-8000-000000000025', 'b0000000-0000-4000-8000-000000000003', 5, 'formula',
   '{"expression":"y − f(a) = f''(a)·(x − a)","caption":"Reta tangente ao gráfico no ponto (a, f(a))"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000026', 'b0000000-0000-4000-8000-000000000003', 6, 'example',
   '{"statement":"Encontre a reta tangente a y = x³ − 2x no ponto x = 1.","steps":["Ponto: f(1) = 1 − 2 = −1, logo (1, −1).","Derivada: f''(x) = 3x² − 2, então f''(1) = 1.","y − (−1) = 1·(x − 1)."],"answer":"y = x − 2"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000027', 'b0000000-0000-4000-8000-000000000003', 7, 'paragraph',
   '{"text":"Toda função derivável em um ponto é contínua nele, mas a recíproca é falsa: f(x) = |x| é contínua em x = 0 e não é derivável ali, porque o gráfico tem um \"bico\" e as inclinações pela esquerda (−1) e pela direita (+1) são diferentes."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000028', 'b0000000-0000-4000-8000-000000000004', 0, 'paragraph',
   '{"text":"Uma grandeza física é tudo aquilo que pode ser medido, e toda medida tem duas partes: um número e uma unidade. \"5\" não diz nada; \"5 m\" e \"5 s\" dizem coisas completamente diferentes. No Brasil, o sistema legal é o Sistema Internacional de Unidades (SI)."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000029', 'b0000000-0000-4000-8000-000000000004', 1, 'key_points',
   '{"title":"As sete grandezas de base do SI","items":["Comprimento: metro (m)","Massa: quilograma (kg)","Tempo: segundo (s)","Corrente elétrica: ampere (A)","Temperatura termodinâmica: kelvin (K)","Quantidade de substância: mol (mol)","Intensidade luminosa: candela (cd)"]}'::jsonb),
  ('c0000000-0000-4000-8000-000000000030', 'b0000000-0000-4000-8000-000000000004', 2, 'paragraph',
   '{"text":"As demais unidades são derivadas, formadas pela combinação das de base: velocidade em m/s, aceleração em m/s², e força em newton."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000031', 'b0000000-0000-4000-8000-000000000004', 3, 'formula',
   '{"expression":"1 N = 1 kg·m/s²","caption":"Newton, unidade de força"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000032', 'b0000000-0000-4000-8000-000000000004', 4, 'key_points',
   '{"title":"Prefixos mais usados","items":["giga (G) = 10⁹","mega (M) = 10⁶","quilo (k) = 10³","centi (c) = 10⁻²","mili (m) = 10⁻³","micro (µ) = 10⁻⁶","nano (n) = 10⁻⁹"]}'::jsonb),
  ('c0000000-0000-4000-8000-000000000033', 'b0000000-0000-4000-8000-000000000004', 5, 'example',
   '{"statement":"Converta 72 km/h para m/s.","steps":["Multiplique por frações iguais a 1, que cancelam as unidades:","72 km/h × (1000 m / 1 km) × (1 h / 3600 s)","= 72 000 m / 3600 s"],"answer":"20 m/s. Atalho: de km/h para m/s, divida por 3,6."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000034', 'b0000000-0000-4000-8000-000000000004', 6, 'paragraph',
   '{"text":"Análise dimensional: em uma equação física, os dois lados (e cada parcela de uma soma) precisam ter a mesma dimensão. Usamos L para comprimento, M para massa e T para tempo. É um jeito rápido de encontrar erros em contas e fórmulas."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000035', 'b0000000-0000-4000-8000-000000000004', 7, 'example',
   '{"statement":"A equação s = s₀ + v·t é dimensionalmente consistente?","steps":["[s] = [s₀] = L.","[v·t] = (L·T⁻¹)·T = L.","Todas as parcelas têm dimensão de comprimento."],"answer":"Sim. (Consistência é necessária, mas não prova que a fórmula está certa.)"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000036', 'b0000000-0000-4000-8000-000000000005', 0, 'paragraph',
   '{"text":"Para descrever um movimento, escolhemos um referencial e uma origem. A posição s indica onde o corpo está; o deslocamento Δs = s − s₀ é a variação da posição e pode ser negativo (o corpo voltou). Já a distância percorrida soma todo o caminho e nunca é negativa."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000037', 'b0000000-0000-4000-8000-000000000005', 1, 'formula',
   '{"expression":"v_m = Δs / Δt","caption":"Velocidade média"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000038', 'b0000000-0000-4000-8000-000000000005', 2, 'formula',
   '{"expression":"a_m = Δv / Δt","caption":"Aceleração média"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000039', 'b0000000-0000-4000-8000-000000000005', 3, 'paragraph',
   '{"text":"No movimento retilíneo uniforme (MRU) a velocidade é constante e a aceleração é nula: o corpo percorre distâncias iguais em tempos iguais."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000040', 'b0000000-0000-4000-8000-000000000005', 4, 'formula',
   '{"expression":"s = s₀ + v·t","caption":"Função horária do MRU"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000041', 'b0000000-0000-4000-8000-000000000005', 5, 'paragraph',
   '{"text":"No movimento retilíneo uniformemente variado (MRUV) a aceleração é constante. A velocidade muda de forma linear com o tempo e a posição, de forma quadrática."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000042', 'b0000000-0000-4000-8000-000000000005', 6, 'key_points',
   '{"title":"Equações do MRUV","items":["v = v₀ + a·t","s = s₀ + v₀·t + a·t²/2","v² = v₀² + 2·a·Δs  (Torricelli: não depende do tempo)"]}'::jsonb),
  ('c0000000-0000-4000-8000-000000000043', 'b0000000-0000-4000-8000-000000000005', 7, 'example',
   '{"statement":"Um carro a 20 m/s freia com aceleração constante de −4 m/s². Quanto tempo leva e quanto anda até parar?","steps":["Tempo: 0 = 20 + (−4)·t, logo t = 5 s.","Distância (Torricelli): 0² = 20² + 2·(−4)·Δs.","0 = 400 − 8·Δs, logo Δs = 50 m."],"answer":"Para em 5 s, depois de percorrer 50 m."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000044', 'b0000000-0000-4000-8000-000000000005', 8, 'paragraph',
   '{"text":"Queda livre é um MRUV vertical em que a única aceleração é a da gravidade, g ≈ 9,8 m/s² (é comum usar 10 m/s² em exercícios), desprezando a resistência do ar. Todos os corpos caem com a mesma aceleração, independentemente da massa."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000045', 'b0000000-0000-4000-8000-000000000005', 9, 'example',
   '{"statement":"Uma pedra é solta do alto de um prédio de 20 m. Use g = 10 m/s². Em quanto tempo e com que velocidade ela chega ao chão?","steps":["Partindo do repouso: h = g·t²/2, então 20 = 5·t².","t² = 4, logo t = 2 s.","v = g·t = 10 · 2 = 20 m/s."],"answer":"Chega em 2 s, a 20 m/s (72 km/h)."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000046', 'b0000000-0000-4000-8000-000000000006', 0, 'paragraph',
   '{"text":"Algumas grandezas ficam definidas por um número e uma unidade: são as escalares, como massa, tempo e temperatura. Outras também precisam de direção e sentido: são as vetoriais, como deslocamento, velocidade, aceleração e força. \"Andei 3 km\" é incompleto; \"andei 3 km para o norte\" é um vetor."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000047', 'b0000000-0000-4000-8000-000000000006', 1, 'key_points',
   '{"title":"Todo vetor tem","items":["Módulo (intensidade): o \"tamanho\", sempre ≥ 0.","Direção: a reta em que atua (horizontal, 30° com o eixo x…).","Sentido: para qual lado dessa reta aponta."]}'::jsonb),
  ('c0000000-0000-4000-8000-000000000048', 'b0000000-0000-4000-8000-000000000006', 2, 'formula',
   '{"expression":"v = (vx, vy) = vx·î + vy·ĵ","caption":"Vetor no plano pelas suas componentes"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000049', 'b0000000-0000-4000-8000-000000000006', 3, 'formula',
   '{"expression":"|v| = √(vx² + vy²)","caption":"Módulo"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000050', 'b0000000-0000-4000-8000-000000000006', 4, 'key_points',
   '{"title":"Decomposição (θ medido a partir do eixo x)","items":["vx = |v|·cos θ","vy = |v|·sen θ","tg θ = vy / vx  (atenção ao quadrante ao calcular θ)"]}'::jsonb),
  ('c0000000-0000-4000-8000-000000000051', 'b0000000-0000-4000-8000-000000000006', 5, 'example',
   '{"statement":"Um projétil é lançado a 20 m/s, formando 30° com a horizontal. Quais são as componentes da velocidade inicial?","steps":["vx = 20·cos 30° ≈ 20 · 0,866 ≈ 17,3 m/s.","vy = 20·sen 30° = 20 · 0,5 = 10 m/s."],"answer":"v₀ ≈ (17,3; 10) m/s"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000052', 'b0000000-0000-4000-8000-000000000006', 6, 'paragraph',
   '{"text":"Para somar vetores, somamos componente a componente. Graficamente, isso equivale a colocar um vetor na ponta do outro (ou à regra do paralelogramo). Vetores não se somam pelos módulos: 3 + 4 só dá 7 se os dois apontarem no mesmo sentido."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000053', 'b0000000-0000-4000-8000-000000000006', 7, 'formula',
   '{"expression":"a + b = (ax + bx, ay + by)","caption":"Soma de vetores"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000054', 'b0000000-0000-4000-8000-000000000006', 8, 'example',
   '{"statement":"Dados a = (3, 4) e b = (1, −2), calcule a + b e |a|.","steps":["a + b = (3 + 1, 4 + (−2)) = (4, 2).","|a| = √(3² + 4²) = √25 = 5."],"answer":"a + b = (4, 2) e |a| = 5"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000055', 'b0000000-0000-4000-8000-000000000006', 9, 'formula',
   '{"expression":"a · b = ax·bx + ay·by = |a|·|b|·cos θ","caption":"Produto escalar (o resultado é um número)"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000056', 'b0000000-0000-4000-8000-000000000006', 10, 'paragraph',
   '{"text":"O produto escalar mede o quanto dois vetores apontam na mesma direção. Se for zero, os vetores são perpendiculares. Na física, aparece no trabalho de uma força: W = F · d. Para a e b acima, a · b = 3·1 + 4·(−2) = −5: o ângulo entre eles é maior que 90°."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000057', 'b0000000-0000-4000-8000-000000000007', 0, 'paragraph',
   '{"text":"A cinemática descreve o movimento; a dinâmica explica por que ele muda. A causa é a força: uma interação entre corpos, medida em newtons. Força é um vetor, então o que importa é a força resultante, a soma vetorial de todas as forças sobre o corpo."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000058', 'b0000000-0000-4000-8000-000000000007', 1, 'formula',
   '{"expression":"F_R = F₁ + F₂ + … + Fₙ","caption":"Força resultante (soma vetorial)"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000059', 'b0000000-0000-4000-8000-000000000007', 2, 'paragraph',
   '{"text":"1ª lei (inércia): se a força resultante sobre um corpo é nula, ele permanece em repouso ou em MRU. Não é preciso força para manter um movimento, só para mudá-lo. É por isso que o passageiro é jogado para a frente quando o ônibus freia."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000060', 'b0000000-0000-4000-8000-000000000007', 3, 'paragraph',
   '{"text":"2ª lei (princípio fundamental): a força resultante produz uma aceleração na mesma direção e sentido dela, proporcional à força e inversamente proporcional à massa. A massa mede a inércia: quanto maior, mais difícil mudar a velocidade."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000061', 'b0000000-0000-4000-8000-000000000007', 4, 'formula',
   '{"expression":"F_R = m·a","caption":"2ª lei de Newton"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000062', 'b0000000-0000-4000-8000-000000000007', 5, 'paragraph',
   '{"text":"3ª lei (ação e reação): se A exerce uma força sobre B, B exerce sobre A uma força de mesmo módulo e direção e sentido oposto. As duas atuam em corpos diferentes e, por isso, nunca se anulam."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000063', 'b0000000-0000-4000-8000-000000000007', 6, 'key_points',
   '{"title":"Forças que aparecem em quase todo exercício","items":["Peso: P = m·g, vertical e para baixo (atração da Terra).","Normal (N): perpendicular à superfície de apoio, empurrando o corpo para fora dela.","Tração (T): ao longo do fio, sempre puxando.","Atrito: paralelo à superfície, contrário ao deslizamento (ou à tendência de deslizar)."]}'::jsonb),
  ('c0000000-0000-4000-8000-000000000064', 'b0000000-0000-4000-8000-000000000007', 7, 'formula',
   '{"expression":"f_at = µ·N","caption":"Atrito cinético (µ: coeficiente de atrito)"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000065', 'b0000000-0000-4000-8000-000000000007', 8, 'key_points',
   '{"title":"Roteiro para resolver","items":["1. Isole o corpo e desenhe todas as forças sobre ele (diagrama de corpo livre).","2. Escolha os eixos, um deles no sentido da aceleração.","3. Decomponha as forças inclinadas (seção Vetores).","4. Aplique F_R = m·a em cada eixo."]}'::jsonb),
  ('c0000000-0000-4000-8000-000000000066', 'b0000000-0000-4000-8000-000000000007', 9, 'example',
   '{"statement":"Uma caixa de 10 kg é puxada por uma força horizontal de 50 N sobre um piso com µ = 0,2. Use g = 10 m/s². Qual é a aceleração?","steps":["Vertical: não há aceleração, então N = P = 10 · 10 = 100 N.","Atrito: f_at = 0,2 · 100 = 20 N, contra o movimento.","Horizontal: F_R = 50 − 20 = 30 N.","a = F_R / m = 30 / 10."],"answer":"a = 3 m/s²"}'::jsonb),
  ('c0000000-0000-4000-8000-000000000067', 'b0000000-0000-4000-8000-000000000007', 10, 'paragraph',
   '{"text":"Cuidado com uma confusão comum: peso e normal não são par de ação e reação. Os dois atuam no mesmo corpo. A reação do peso é a força com que o corpo atrai a Terra; a reação da normal é a força com que o corpo comprime o piso."}'::jsonb),
  ('c0000000-0000-4000-8000-000000000068', 'b0000000-0000-4000-8000-000000000007', 11, 'example',
   '{"statement":"Uma pessoa de 60 kg está sobre uma balança dentro de um elevador que sobe acelerando a 2 m/s². Use g = 10 m/s². Quanto a balança marca?","steps":["A balança mede a normal N que ela faz na pessoa.","Eixo para cima (sentido da aceleração): N − P = m·a.","N = m·(g + a) = 60 · (10 + 2) = 720 N."],"answer":"720 N, mais que o peso de 600 N: a pessoa se sente \"mais pesada\"."}'::jsonb)
on conflict (id) do nothing;

commit;

-- =============================================================================
-- Conferência: a coluna "ok" deve ser true em todas as linhas.
-- =============================================================================
select 'study_modules' as tabela, count(*) as total, 6 as esperado,
       count(*) = 6 as ok
  from public.study_modules
union all
select 'study_module_details', count(*), 2, count(*) = 2
  from public.study_module_details
union all
select 'module_sections', count(*), 7, count(*) = 7
  from public.module_sections
union all
select 'content_blocks', count(*), 68, count(*) = 68
  from public.content_blocks;
