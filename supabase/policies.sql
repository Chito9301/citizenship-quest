-- =====================================================================
-- Citizenship Quest — Row Level Security
-- =====================================================================
-- Regla general: RLS habilitado en TODAS las tablas. Sin política =
-- acceso denegado por defecto para 'anon' y 'authenticated'. Las
-- escrituras sensibles (quiz_sessions, daily_activity, weekly_rankings,
-- user_achievements, sync_queue) NO tienen política de INSERT para
-- 'authenticated': solo se escriben desde Edge Functions o funciones
-- SECURITY DEFINER usando la service_role key, que ignora RLS.
-- =====================================================================

alter table public.profiles           enable row level security;
alter table public.quiz_sessions      enable row level security;
alter table public.daily_activity     enable row level security;
alter table public.weekly_rankings    enable row level security;
alter table public.invite_codes       enable row level security;
alter table public.friend_referrals   enable row level security;
alter table public.achievements       enable row level security;
alter table public.user_achievements  enable row level security;
alter table public.notifications      enable row level security;
alter table public.chat_rooms         enable row level security;
alter table public.chat_room_members  enable row level security;
alter table public.chat_messages      enable row level security;
alter table public.user_devices       enable row level security;
alter table public.sync_queue         enable row level security;
alter table public.events             enable row level security;
alter table public.premium_purchases  enable row level security;

-- ---------------------------------------------------------------------
-- profiles: cada usuario ve y edita solo su propia fila. El leaderboard
-- público se sirve vía get_public_leaderboard() / get_weekly_leaderboard()
-- (SECURITY DEFINER), no leyendo esta tabla directamente.
-- ---------------------------------------------------------------------
create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);

create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);
-- Sin política de insert/delete: el insert lo hace handle_new_user()
-- (trigger SECURITY DEFINER) al registrarse el usuario.

-- ---------------------------------------------------------------------
-- quiz_sessions: solo lectura de las partidas propias. La escritura es
-- exclusiva de la Edge Function validate-quiz-session (service_role).
-- ---------------------------------------------------------------------
create policy "quiz_sessions_select_own" on public.quiz_sessions
  for select using (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- daily_activity: sin políticas para 'authenticated' → acceso denegado.
-- Solo se lee desde el dashboard administrativo (service_role) y se
-- escribe desde el trigger apply_quiz_session_effects().
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- weekly_rankings: lectura pública para cualquier usuario autenticado
-- (no contiene PII, solo user_id/score/rank). Sin insert/update/delete
-- para el cliente: lo escribe refresh_weekly_rankings() por cron.
-- ---------------------------------------------------------------------
create policy "weekly_rankings_select_all" on public.weekly_rankings
  for select to authenticated using (true);

-- ---------------------------------------------------------------------
-- invite_codes: el dueño puede crear y ver sus propios códigos. El
-- canje (que afecta a OTRO usuario) pasa por la Edge Function
-- redeem-invite-code, nunca por escritura directa del cliente.
-- ---------------------------------------------------------------------
create policy "invite_codes_select_own" on public.invite_codes
  for select using (auth.uid() = owner_id);

create policy "invite_codes_insert_own" on public.invite_codes
  for insert with check (auth.uid() = owner_id);

-- ---------------------------------------------------------------------
-- friend_referrals: cada usuario ve las referencias donde participa
-- (como referidor o como referido). Insert solo vía Edge Function.
-- ---------------------------------------------------------------------
create policy "friend_referrals_select_own" on public.friend_referrals
  for select using (auth.uid() = referrer_id or auth.uid() = referred_id);

-- ---------------------------------------------------------------------
-- achievements: catálogo de lectura pública (no hay nada sensible).
-- ---------------------------------------------------------------------
create policy "achievements_select_all" on public.achievements
  for select to authenticated using (true);

-- ---------------------------------------------------------------------
-- user_achievements: cada usuario ve solo sus insignias desbloqueadas.
-- El insert lo hace lógica de servidor al cumplirse la condición.
-- ---------------------------------------------------------------------
create policy "user_achievements_select_own" on public.user_achievements
  for select using (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- notifications: cada usuario ve y marca como leídas solo las suyas.
-- El insert lo hace el servidor (logros, referidos, anuncios, etc.).
-- ---------------------------------------------------------------------
create policy "notifications_select_own" on public.notifications
  for select using (auth.uid() = user_id);

create policy "notifications_mark_read_own" on public.notifications
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- chat: solo miembros de una sala pueden ver/escribir en ella.
-- ---------------------------------------------------------------------
create policy "chat_rooms_select_member" on public.chat_rooms
  for select using (
    exists (
      select 1 from public.chat_room_members m
      where m.room_id = id and m.user_id = auth.uid()
    )
  );

create policy "chat_room_members_select_related" on public.chat_room_members
  for select using (
    user_id = auth.uid()
    or exists (
      select 1 from public.chat_room_members m2
      where m2.room_id = chat_room_members.room_id and m2.user_id = auth.uid()
    )
  );

create policy "chat_messages_select_member" on public.chat_messages
  for select using (
    exists (
      select 1 from public.chat_room_members m
      where m.room_id = chat_messages.room_id and m.user_id = auth.uid()
    )
  );

create policy "chat_messages_insert_member" on public.chat_messages
  for insert with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.chat_room_members m
      where m.room_id = chat_messages.room_id and m.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------
-- user_devices: cada usuario administra sus propios dispositivos.
-- ---------------------------------------------------------------------
create policy "user_devices_select_own" on public.user_devices
  for select using (auth.uid() = user_id);

create policy "user_devices_insert_own" on public.user_devices
  for insert with check (auth.uid() = user_id);

create policy "user_devices_update_own" on public.user_devices
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- sync_queue: el usuario puede ver el estado de sus propios envíos.
-- El insert/procesamiento real lo hacen las Edge Functions
-- (service_role), que además validan antes de aceptar nada.
-- ---------------------------------------------------------------------
create policy "sync_queue_select_own" on public.sync_queue
  for select using (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- events: append-only. Un usuario puede insertar y leer sus propios
-- eventos, pero nunca modificarlos ni borrarlos (sin política de
-- update/delete = denegado).
-- ---------------------------------------------------------------------
create policy "events_insert_own" on public.events
  for insert with check (auth.uid() = user_id);

create policy "events_select_own" on public.events
  for select using (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- premium_purchases: el usuario solo puede leer sus propias compras.
-- El insert queda reservado a la Edge Function que valide el recibo
-- de Google Play / App Store (Sprint futuro).
-- ---------------------------------------------------------------------
create policy "premium_purchases_select_own" on public.premium_purchases
  for select using (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- Endurecimiento extra: revocar los privilegios por defecto que
-- Supabase otorga a 'anon' sobre tablas nuevas del esquema public,
-- para que quede 100% explícito qué puede hacer un usuario NO logueado
-- (nada, salvo lo que RLS + policy permitan a 'authenticated').
-- ---------------------------------------------------------------------
revoke all on public.profiles, public.quiz_sessions, public.daily_activity,
  public.weekly_rankings, public.invite_codes, public.friend_referrals,
  public.achievements, public.user_achievements, public.notifications,
  public.chat_rooms, public.chat_room_members, public.chat_messages,
  public.user_devices, public.sync_queue, public.events, public.premium_purchases
from anon;
