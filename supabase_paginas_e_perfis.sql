-- ============================================================
-- Ecossistema — páginas de vendas + perfil online
-- Rode no SQL Editor do Supabase (projeto cawvxladfbkabvvtouag)
-- ============================================================

-- 1) Colunas de perfil público (se ainda não existirem)
alter table if exists perfis add column if not exists handle text;
alter table if exists perfis add column if not exists nome_exibicao text;
alter table if exists perfis add column if not exists bio text;
alter table if exists perfis add column if not exists vitrine_publica boolean default false;
alter table if exists perfis add column if not exists email text;

-- handle único quando preenchido (opcional; ignore erro se já existir índice)
create unique index if not exists perfis_handle_unique
  on perfis (handle)
  where handle is not null and handle <> '';

-- Policies de perfil (ajuste se já existirem com outro nome)
alter table perfis enable row level security;

drop policy if exists "dono gerencia perfil" on perfis;
create policy "dono gerencia perfil"
  on perfis for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "autenticados leem perfis" on perfis;
create policy "autenticados leem perfis"
  on perfis for select
  using (auth.role() = 'authenticated');

drop policy if exists "vitrine perfil publica legivel" on perfis;
create policy "vitrine perfil publica legivel"
  on perfis for select
  using (vitrine_publica = true);

-- 2) Páginas de vendas (landing compartilável)
create table if not exists paginas_vendas (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  titulo text,
  headline text,
  sub text,
  cta_texto text,
  cta_url text,
  btn2_texto text,
  btn2_url text,
  publico boolean default false,
  criado_em timestamptz default now(),
  atualizado_em timestamptz default now()
);

create index if not exists paginas_vendas_user_id_idx on paginas_vendas (user_id);
create index if not exists paginas_vendas_publico_idx on paginas_vendas (publico) where publico = true;

alter table paginas_vendas enable row level security;

drop policy if exists "dono gerencia paginas vendas" on paginas_vendas;
create policy "dono gerencia paginas vendas"
  on paginas_vendas for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Leitura pública: link ?v= funciona sem login (anon + authenticated)
drop policy if exists "paginas vendas publicas legiveis" on paginas_vendas;
create policy "paginas vendas publicas legiveis"
  on paginas_vendas for select
  using (publico = true);

-- 3) Projetos / vitrines (reforço, se ainda faltar)
create table if not exists projetos (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  titulo text not null,
  resumo text,
  video_url text,
  pdf_url text,
  acesso_url text,
  capa_url text,
  publico boolean default false,
  criado_em timestamptz default now(),
  atualizado_em timestamptz default now()
);
alter table projetos add column if not exists capa_url text;
alter table projetos enable row level security;

drop policy if exists "dono gerencia seus projetos" on projetos;
create policy "dono gerencia seus projetos"
  on projetos for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "vitrines publicas legiveis" on projetos;
create policy "vitrines publicas legiveis"
  on projetos for select
  using (publico = true);

-- Fim. Depois: no app, Interior → Guardar perfil / Guardar página pública e testar ?u= e ?v=
