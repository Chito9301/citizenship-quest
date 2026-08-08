-- =====================================================================
-- Citizenship Quest — Schema de base de datos (Supabase / PostgreSQL)
-- =====================================================================
-- El quiz sigue siendo 100% local (assets/data/preguntas.json). Este
-- backend NUNCA almacena ni envía preguntas: solo recibe resultados de
-- partidas ya jugadas, perfiles, rankings, invitaciones, logros,
-- notificaciones, chat y eventos de analítica.
--
-- Convenciones:
--   - Toda tabla tiene RLS habilitado (ver policies.sql).
--   - Los ids de usuario son uuid y apuntan a auth.users vía profiles.id.
--   - Los timestamps son timestamptz (UTC) salvo donde se indica.
-- =====================================================================

create extension if not exists pgcrypto;   -- gen_random_uuid()
create extension if not exists pg_cron;    -- tareas programadas (rankings semanales)

-- ---------------------------------------------------------------------
-- profiles: 1 fila por usuario autenticado (incluye usuarios anónimos).
-- ---------------------------------------------------------------------
create table public.profiles (
  id                   uuid primary key references auth.users (id) on delete cascade,
  display_name         text not null default 'Guest',
  country_code         text,                          -- ISO 3166-1 alpha-2 (ej. 'CU')
  language_code        text not null default 'en',     -- 'en' | 'es'
  registered_at        timestamptz not null default now(),
  last_active_at       timestamptz not null default now(),
  current_streak_days  integer not null default 0,
  longest_streak_days  integer not null default 0,
  total_points         integer not null default 0,
  is_premium           boolean not null default false,
  premium_since        timestamptz,
  device_id            text,                          -- último dispositivo visto (denormalizado)
  app_version          text,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  constraint profiles_points_non_negative check (total_points >= 0)
);

comment on table public.profiles is
  'Un perfil por usuario de auth.users. Se crea automáticamente vía trigger handle_new_user.';

-- ---------------------------------------------------------------------
-- quiz_sessions: resultado de cada partida, validado por Edge Function.
-- El cliente NUNCA inserta aquí directamente (ver policies.sql).
-- ---------------------------------------------------------------------
create table public.quiz_sessions (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references public.profiles (id) on delete cascade,
  client_session_id   uuid not null,          -- generado en el dispositivo; dedup key
  category            text not null,
  language_code       text not null,
  question_count      integer not null,
  correct_answers     integer not null,
  score               integer not null,       -- recalculado en el servidor, nunca el del cliente
  avg_answer_seconds  numeric(6, 2) not null,
  duration_seconds    integer not null,
  device_id           text,
  app_version         text,
  played_at           timestamptz not null,
  synced_at           timestamptz not null default now(),
  constraint quiz_sessions_client_unique unique (user_id, client_session_id),
  constraint quiz_sessions_question_count_bounds check (question_count between 1 and 50),
  constraint quiz_sessions_correct_bounds check (correct_answers between 0 and question_count),
  constraint quiz_sessions_score_non_negative check (score >= 0),
  constraint quiz_sessions_duration_positive check (duration_seconds > 0)
);

create index quiz_sessions_user_idx on public.quiz_sessions (user_id, played_at desc);
create index quiz_sessions_played_at_idx on public.quiz_sessions (played_at);

comment on table public.quiz_sessions is
  'Resultados de partidas. Solo la Edge Function validate-quiz-session escribe aquí (service_role).';

-- ---------------------------------------------------------------------
-- daily_activity: 1 fila por usuario por día. Base para DAU/WAU/MAU y
-- retención. Se mantiene con un trigger sobre quiz_sessions.
-- ---------------------------------------------------------------------
create table public.daily_activity (
  user_id          uuid not null references public.profiles (id) on delete cascade,
  activity_date    date not null,
  sessions_played  integer not null default 0,
  points_earned    integer not null default 0,
  minutes_active   numeric(6, 2) not null default 0,
  primary key (user_id, activity_date)
);

create index daily_activity_date_idx on public.daily_activity (activity_date);

comment on table public.daily_activity is
  'Agregado diario por usuario. Alimenta DAU/WAU/MAU y retención (ver metrics_views.sql).';

-- ---------------------------------------------------------------------
-- weekly_rankings: snapshot de ranking semanal, recalculado por cron.
-- ---------------------------------------------------------------------
create table public.weekly_rankings (
  id           uuid primary key default gen_random_uuid(),
  iso_year     integer not null,
  iso_week     integer not null,
  user_id      uuid not null references public.profiles (id) on delete cascade,
  total_score  integer not null,
  rank         integer not null,
  computed_at  timestamptz not null default now(),
  unique (iso_year, iso_week, user_id)
);

create index weekly_rankings_week_idx on public.weekly_rankings (iso_year, iso_week, rank);

-- ---------------------------------------------------------------------
-- invite_codes / friend_referrals
-- ---------------------------------------------------------------------
create table public.invite_codes (
  code        text primary key,               -- ej. 'CQ-7F3K9A'
  owner_id    uuid not null references public.profiles (id) on delete cascade,
  max_uses    integer not null default 10,
  uses_count  integer not null default 0,
  created_at  timestamptz not null default now(),
  expires_at  timestamptz,
  constraint invite_codes_uses_non_negative check (uses_count >= 0 and uses_count <= max_uses)
);

create index invite_codes_owner_idx on public.invite_codes (owner_id);

create table public.friend_referrals (
  id              uuid primary key default gen_random_uuid(),
  code            text not null references public.invite_codes (code) on delete cascade,
  referrer_id     uuid not null references public.profiles (id) on delete cascade,
  referred_id     uuid not null references public.profiles (id) on delete cascade,
  points_awarded  integer not null default 0,
  created_at      timestamptz not null default now(),
  unique (referred_id),                        -- un usuario solo puede ser referido una vez
  constraint friend_referrals_no_self_referral check (referrer_id <> referred_id)
);

create index friend_referrals_referrer_idx on public.friend_referrals (referrer_id);

-- ---------------------------------------------------------------------
-- achievements (catálogo) + user_achievements (desbloqueos)
-- ---------------------------------------------------------------------
create table public.achievements (
  id                text primary key,          -- ej. 'streak_7', 'first_quiz'
  title_en          text not null,
  title_es          text not null,
  description_en    text not null,
  description_es    text not null,
  points_reward     integer not null default 0,
  icon              text
);

create table public.user_achievements (
  user_id         uuid not null references public.profiles (id) on delete cascade,
  achievement_id  text not null references public.achievements (id) on delete cascade,
  unlocked_at     timestamptz not null default now(),
  primary key (user_id, achievement_id)
);

-- ---------------------------------------------------------------------
-- notifications
-- ---------------------------------------------------------------------
create table public.notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  type        text not null,                   -- 'system' | 'achievement' | 'friend_referral' | 'ranking'
  title       text not null,
  body        text,
  data        jsonb not null default '{}'::jsonb,
  is_read     boolean not null default false,
  created_at  timestamptz not null default now()
);

create index notifications_user_idx on public.notifications (user_id, is_read, created_at desc);

-- ---------------------------------------------------------------------
-- chat_rooms / chat_room_members / chat_messages
-- (chat_room_members se agrega porque es indispensable para poder
-- filtrar por RLS quién puede ver qué sala; no rompe el mínimo pedido).
-- ---------------------------------------------------------------------
create table public.chat_rooms (
  id          uuid primary key default gen_random_uuid(),
  type        text not null check (type in ('direct', 'group')),
  title       text,
  created_by  uuid references public.profiles (id) on delete set null,
  created_at  timestamptz not null default now()
);

create table public.chat_room_members (
  room_id   uuid not null references public.chat_rooms (id) on delete cascade,
  user_id   uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create table public.chat_messages (
  id          uuid primary key default gen_random_uuid(),
  room_id     uuid not null references public.chat_rooms (id) on delete cascade,
  sender_id   uuid not null references public.profiles (id) on delete cascade,
  body        text not null check (char_length(body) between 1 and 2000),
  created_at  timestamptz not null default now()
);

create index chat_messages_room_idx on public.chat_messages (room_id, created_at);

-- ---------------------------------------------------------------------
-- user_devices: para métricas de dispositivos y push notifications.
-- ---------------------------------------------------------------------
create table public.user_devices (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles (id) on delete cascade,
  device_id      text not null,
  platform       text not null,               -- 'android' | 'ios'
  os_version     text,
  app_version    text,
  push_token     text,
  first_seen_at  timestamptz not null default now(),
  last_seen_at   timestamptz not null default now(),
  unique (user_id, device_id)
);

-- ---------------------------------------------------------------------
-- sync_queue: staging/auditoría server-side de todo lo que llega desde
-- la cola local de sincronización. No reemplaza la cola local (JSON en
-- el dispositivo); es el registro server-side para depurar conflictos,
-- detectar reintentos y auditar duplicados.
-- ---------------------------------------------------------------------
create table public.sync_queue (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references public.profiles (id) on delete cascade,
  operation_type     text not null,             -- 'quiz_completed' | 'profile_updated' | ...
  client_event_id    uuid not null,
  payload            jsonb not null,
  status             text not null default 'pending' check (status in ('pending', 'processed', 'rejected')),
  rejection_reason   text,
  received_at        timestamptz not null default now(),
  processed_at       timestamptz,
  unique (user_id, client_event_id)
);

create index sync_queue_status_idx on public.sync_queue (status, received_at);

-- ---------------------------------------------------------------------
-- events: tabla de analítica genérica y append-only. Permite agregar
-- métricas nuevas a futuro sin tocar el esquema.
-- ---------------------------------------------------------------------
create table public.events (
  id           bigint generated always as identity primary key,
  user_id      uuid references public.profiles (id) on delete set null,
  event_type   text not null,       -- 'app_open' | 'quiz_completed' | 'battle_won' |
                                     -- 'message_sent' | 'friend_invited' |
                                     -- 'premium_purchased' | 'achievement_unlocked' | ...
  payload      jsonb not null default '{}'::jsonb,
  device_id    text,
  app_version  text,
  occurred_at  timestamptz not null default now()
);

create index events_type_time_idx on public.events (event_type, occurred_at);
create index events_user_time_idx on public.events (user_id, occurred_at);

-- ---------------------------------------------------------------------
-- premium_purchases: agregada para poder calcular conversión Premium
-- e ingresos (pedidos explícitamente en el dashboard).
-- ---------------------------------------------------------------------
create table public.premium_purchases (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  store        text not null check (store in ('google_play', 'app_store', 'manual')),
  product_id   text not null,
  amount_usd   numeric(10, 2) not null,
  purchased_at timestamptz not null default now(),
  raw_receipt  jsonb
);

create index premium_purchases_user_idx on public.premium_purchases (user_id);

-- ---------------------------------------------------------------------
-- Auto-provisión de profiles al crearse un usuario en auth.users.
-- ---------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, language_code)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', 'Guest'),
    coalesce(new.raw_user_meta_data ->> 'language_code', 'en')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
