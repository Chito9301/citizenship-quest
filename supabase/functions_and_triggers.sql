-- =====================================================================
-- Citizenship Quest — Funciones y triggers de servidor
-- =====================================================================
-- Toda esta lógica corre con SECURITY DEFINER (privilegios del dueño
-- de la función, no del usuario que dispara el trigger), por eso puede
-- escribir en tablas donde el cliente no tiene permiso directo.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Efectos de una partida validada: puntos, racha, daily_activity y el
-- evento correspondiente. Se dispara SOLO cuando la Edge Function
-- validate-quiz-session inserta en quiz_sessions (nunca por el cliente
-- directamente, ver policies.sql).
-- ---------------------------------------------------------------------
create or replace function public.apply_quiz_session_effects()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_last_active date;
  v_today       date := (new.played_at at time zone 'utc')::date;
  v_new_streak  integer;
begin
  select (last_active_at at time zone 'utc')::date into v_last_active
  from public.profiles
  where id = new.user_id;

  v_new_streak := case
    when v_last_active = v_today then (select current_streak_days from public.profiles where id = new.user_id)
    when v_last_active = v_today - 1 then (select current_streak_days from public.profiles where id = new.user_id) + 1
    else 1
  end;

  update public.profiles
  set total_points        = total_points + new.score,
      current_streak_days = v_new_streak,
      longest_streak_days = greatest(longest_streak_days, v_new_streak),
      last_active_at       = new.played_at,
      updated_at            = now()
  where id = new.user_id;

  insert into public.daily_activity (user_id, activity_date, sessions_played, points_earned, minutes_active)
  values (new.user_id, v_today, 1, new.score, round(new.duration_seconds / 60.0, 2))
  on conflict (user_id, activity_date) do update
    set sessions_played = daily_activity.sessions_played + 1,
        points_earned   = daily_activity.points_earned + excluded.points_earned,
        minutes_active  = daily_activity.minutes_active + excluded.minutes_active;

  insert into public.events (user_id, event_type, payload, device_id, app_version)
  values (
    new.user_id,
    'quiz_completed',
    jsonb_build_object('score', new.score, 'category', new.category, 'correct_answers', new.correct_answers),
    new.device_id,
    new.app_version
  );

  return new;
end;
$$;

create trigger trg_quiz_session_effects
  after insert on public.quiz_sessions
  for each row execute function public.apply_quiz_session_effects();

-- ---------------------------------------------------------------------
-- Incremento atómico de puntos (usado por Edge Functions, ej. al
-- canjear un código de invitación) para evitar condiciones de carrera
-- de tipo "leer-modificar-escribir" desde el cliente.
-- ---------------------------------------------------------------------
create or replace function public.increment_points(p_user_id uuid, p_points integer)
returns void
language sql
security definer
set search_path = public
as $$
  update public.profiles
  set total_points = total_points + p_points, updated_at = now()
  where id = p_user_id;
$$;

-- ---------------------------------------------------------------------
-- Ranking semanal. Se recalcula por cron (idempotente vía upsert).
-- ---------------------------------------------------------------------
create or replace function public.refresh_weekly_rankings()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.weekly_rankings (iso_year, iso_week, user_id, total_score, rank)
  select
    extract(isoyear from now())::int,
    extract(week from now())::int,
    user_id,
    sum(points_earned) as total_score,
    row_number() over (order by sum(points_earned) desc) as rank
  from public.daily_activity
  where activity_date >= date_trunc('week', now())::date
  group by user_id
  on conflict (iso_year, iso_week, user_id) do update
    set total_score = excluded.total_score,
        rank        = excluded.rank,
        computed_at = now();
end;
$$;

-- Se ejecuta cada hora. pg_cron debe estar habilitado en el proyecto
-- de Supabase (Database → Extensions → pg_cron).
select cron.schedule(
  'refresh-weekly-rankings',
  '0 * * * *',
  $$select public.refresh_weekly_rankings();$$
);

-- ---------------------------------------------------------------------
-- Leaderboard público seguro: expone SOLO columnas no sensibles de
-- profiles, sin importar las políticas RLS de la tabla base (por eso
-- es SECURITY DEFINER). Es la única forma en que un usuario puede ver
-- datos de otros usuarios.
-- ---------------------------------------------------------------------
create or replace function public.get_public_leaderboard(p_limit integer default 50)
returns table (display_name text, total_points integer, country_code text, is_premium boolean)
language sql
security definer
set search_path = public
as $$
  select display_name, total_points, country_code, is_premium
  from public.profiles
  order by total_points desc
  limit p_limit;
$$;

grant execute on function public.get_public_leaderboard(integer) to authenticated;

create or replace function public.get_weekly_leaderboard(p_iso_year integer, p_iso_week integer)
returns table (rank integer, display_name text, total_score integer)
language sql
security definer
set search_path = public
as $$
  select wr.rank, p.display_name, wr.total_score
  from public.weekly_rankings wr
  join public.profiles p on p.id = wr.user_id
  where wr.iso_year = p_iso_year and wr.iso_week = p_iso_week
  order by wr.rank
  limit 100;
$$;

grant execute on function public.get_weekly_leaderboard(integer, integer) to authenticated;
