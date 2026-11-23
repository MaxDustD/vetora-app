-- =============================================================================
-- Vetora — 01_schema.sql
-- Esquema do catálogo de estudo no Supabase (PostgreSQL).
--
-- Mapeamento a partir do projeto de referência (CeliLac):
--   estabelecimento        → study_modules         (entidade principal)
--   detalhes do local      → study_module_details  (1:1 opcional)
--   itens/avaliações       → module_sections       (1:N do módulo)
--                          → content_blocks        (1:N da seção)
--   fotos do local         → bucket "module-covers" (só o caminho no banco)
--
-- Os valores das colunas com domínio fechado são os mesmos do app
-- (lib/features/modules/data/module_storage_keys.dart e content_block_codec.dart)
-- e do SQLite local (lib/app/database/vetora_database.dart).
--
-- O script pode ser executado mais de uma vez (if not exists / drop if exists).
-- =============================================================================

-- gen_random_uuid() é nativa no PostgreSQL 13+; a extensão garante a função
-- em versões anteriores e não faz nada quando já existe.
create extension if not exists pgcrypto;

-- -----------------------------------------------------------------------------
-- 1. Entidade principal: módulo de estudo
-- -----------------------------------------------------------------------------
create table if not exists public.study_modules (
  id                  uuid primary key default gen_random_uuid(),

  -- Identificador legível usado pelo app ("calculo-1"): minúsculo, com hífens.
  slug                text not null unique
                      check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),

  title               text not null check (length(btrim(title)) > 0),
  subtitle            text not null default '',

  -- enum EngineeringArea do app, em texto minúsculo.
  area                text not null
                      check (area in ('physics', 'mathematics', 'civil',
                                      'electrical', 'mechanical')),

  topic_count         integer not null check (topic_count >= 0),
  duration_in_minutes integer not null check (duration_in_minutes > 0),

  -- enum ModuleResource: lista curta, sem dados próprios → array de texto.
  -- "<@" garante que todo item pertence ao conjunto permitido.
  resources           text[] not null default '{}'
                      check (resources <@ array['theory', 'solved_exercises',
                                                'calculator']::text[]),

  -- Nota média dada pelos estudantes, de 0.0 a 5.0 (uma casa decimal).
  average_rating      numeric(2,1)
                      check (average_rating between 0 and 5),

  -- Posição no carrossel "Mais estudados" (1 = mais popular).
  popularity_rank     integer not null unique check (popularity_rank > 0),

  -- Caminho relativo dentro do bucket (ex.: "calculo-1/capa.png").
  -- Nunca uma URL absoluta: o domínio do projeto pode mudar.
  cover_image_path    text check (cover_image_path !~* '^https?://'),

  created_at          timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- 2. Detalhe 1:1 (opcional): texto longo, carregado só na tela do módulo
-- -----------------------------------------------------------------------------
create table if not exists public.study_module_details (
  id          uuid primary key default gen_random_uuid(),

  -- unique transforma a relação em 1:1 (no máximo um detalhe por módulo).
  module_id   uuid not null unique
              references public.study_modules (id) on delete cascade,

  description text not null default '',
  updated_at  timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- 3. Filha 1:N: seções do material de um módulo
-- -----------------------------------------------------------------------------
create table if not exists public.module_sections (
  id        uuid primary key default gen_random_uuid(),
  module_id uuid not null
            references public.study_modules (id) on delete cascade,
  slug      text not null check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  position  integer not null check (position >= 0),  -- ordem de estudo
  title     text not null check (length(btrim(title)) > 0),
  summary   text not null default '',

  unique (module_id, slug),
  unique (module_id, position)
);

-- -----------------------------------------------------------------------------
-- 4. Filha 1:N da seção: blocos de conteúdo
--    Os quatro tipos de bloco (sealed class ContentBlock no app) têm campos
--    diferentes; o tipo fica em "kind" e os campos num objeto JSON.
-- -----------------------------------------------------------------------------
create table if not exists public.content_blocks (
  id         uuid primary key default gen_random_uuid(),
  section_id uuid not null
             references public.module_sections (id) on delete cascade,
  position   integer not null check (position >= 0),
  kind       text not null
             check (kind in ('paragraph', 'formula', 'key_points', 'example')),
  payload    jsonb not null check (jsonb_typeof(payload) = 'object'),

  unique (section_id, position)
);

-- -----------------------------------------------------------------------------
-- 5. Índices das chaves estrangeiras
--    O PostgreSQL não indexa FKs sozinho; sem índice, cada ON DELETE CASCADE
--    e cada busca "seções do módulo X" varre a tabela inteira.
--    (Em study_module_details o UNIQUE já cria um índice; o explícito fica
--    para que a regra "toda FK tem índice" seja visível no script.)
-- -----------------------------------------------------------------------------
create index if not exists study_module_details_module_id_idx
  on public.study_module_details (module_id);
create index if not exists module_sections_module_id_idx
  on public.module_sections (module_id);
create index if not exists content_blocks_section_id_idx
  on public.content_blocks (section_id);

-- -----------------------------------------------------------------------------
-- 6. Segurança: Row Level Security
--    Com RLS ligado, nada passa sem uma política que permita. Só existe a
--    política de leitura, então INSERT/UPDATE/DELETE pela API pública
--    (chave anon ou usuário logado) são sempre negados. O conteúdo é
--    mantido pelo painel ou pela service_role, que ignora RLS.
-- -----------------------------------------------------------------------------
alter table public.study_modules        enable row level security;
alter table public.study_module_details enable row level security;
alter table public.module_sections      enable row level security;
alter table public.content_blocks       enable row level security;

drop policy if exists "leitura publica" on public.study_modules;
create policy "leitura publica" on public.study_modules
  for select to anon, authenticated using (true);

drop policy if exists "leitura publica" on public.study_module_details;
create policy "leitura publica" on public.study_module_details
  for select to anon, authenticated using (true);

drop policy if exists "leitura publica" on public.module_sections;
create policy "leitura publica" on public.module_sections
  for select to anon, authenticated using (true);

drop policy if exists "leitura publica" on public.content_blocks;
create policy "leitura publica" on public.content_blocks
  for select to anon, authenticated using (true);

-- Segunda barreira: mesmo que alguém crie uma política por engano, os papéis
-- públicos não têm privilégio de escrita nessas tabelas.
revoke insert, update, delete, truncate
  on public.study_modules, public.study_module_details,
     public.module_sections, public.content_blocks
  from anon, authenticated;

-- -----------------------------------------------------------------------------
-- 7. Storage: bucket público com as capas dos módulos
--    O app monta a URL com supabase.storage.from('module-covers')
--    .getPublicUrl(cover_image_path).
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('module-covers', 'module-covers', true)
on conflict (id) do nothing;
