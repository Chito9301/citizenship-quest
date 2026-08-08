-- =====================================================================
-- Citizenship Quest — Métricas para el dashboard administrativo
-- =====================================================================
-- IMPORTANTE: nada de esto se expone al cliente Flutter. Son vistas y
-- funciones pensadas para consultarse desde un panel interno (Supabase
-- Studio, Metabase, Retool, o una pantalla admin propia) usando la
-- service_role key, que ignora RLS. Por eso, al final del archivo, se
-- revocan explícitamente los permisos de 'anon' y 'authenticated'.
-- =====================================================================

-- ---------------------------------------------------------------------
-- DAU / WAU / MAU
-- ---------------------------------------------------------------------
create or replace view public.metric_dau as
select activity_date, count(distinct user_id) as dau
from public.daily_activity
group by activity_date
order by activity_date desc;

create or replace function public.metric_wau(as_of date default current_date)
returns integer language sql stable as $$
  select count(distinct user_id) from public.daily_activity
  where activity_date between as_of - 6 and as_of;
$$;

create or replace function public.metric_mau(as_of date default current_date)
returns integer language sql stable as $$
  select count(distinct user_id) from public.daily_activity
  where activity_date between as_of - 29 and as_of;
$$;

-- ---------------------------------------------------------------------
-- Retención D1 / D7 / D30, por cohorte de fecha de registro.
-- Uso: select * from metric_retention(1);  -- D1
--      select * from metric_retention(7);  -- D7
--      select * from metric_retention(30); -- D30
-- ---------------------------------------------------------------------
create or replace function public.metric_retention(days_after integer)
returns table (cohort_date date, cohort_size bigint, retained bigint, retention_rate numeric)
language sql stable as $$
  with cohorts as (
    select id as user_id, (registered_at at time zone 'utc')::date as reg_date
    from public.profiles
  )
  select
    c.reg_date as cohort_date,
    count(distinct c.user_id) as cohort_size,
    count(distinct a.user_id) filter (where a.activity_date = c.reg_date + days_after) as retained,
    round(
      count(distinct a.user_id) filter (where a.activity_date = c.reg_date + days_after)::numeric
        / nullif(count(distinct c.user_id), 0),
      4
    ) as retention_rate
  from cohorts c
  left join public.daily_activity a on a.user_id = c.user_id
  group by c.reg_date
  order by c.reg_date desc;
$$;

-- ---------------------------------------------------------------------
-- Usuarios activos / inactivos / recuperados
-- ---------------------------------------------------------------------
create or replace view public.metric_active_users as
select p.id, p.display_name
from public.profiles p
where exists (
  select 1 from public.daily_activity d
  where d.user_id = p.id and d.activity_date >= current_date - 7
);

create or replace view public.metric_inactive_users as
select id, display_name, last_active_at
from public.profiles
where last_active_at < now() - interval '14 days';

-- "Recuperado" = jugó hoy pero su última actividad previa fue hace 14+
-- días. Se calcula sobre daily_activity (no sobre profiles.last_active_at)
-- para evitar la condición de carrera de comparar contra un valor que
-- el propio trigger ya actualizó.
create or replace function public.metric_recovered_users(as_of date default current_date)
returns table (user_id uuid) language sql stable as $$
  with last_before as (
    select user_id, max(activity_date) as prev_active
    from public.daily_activity
    where activity_date < as_of
    group by user_id
  )
  select d.user_id
  from public.daily_activity d
  join last_before lb on lb.user_id = d.user_id
  where d.activity_date = as_of
    and lb.prev_active <= as_of - 14;
$$;

-- ---------------------------------------------------------------------
-- Registros nuevos / usuarios perdidos
-- ---------------------------------------------------------------------
create or replace view public.metric_new_registrations as
select (registered_at at time zone 'utc')::date as day, count(*) as new_users
from public.profiles
group by 1
order by 1 desc;

create or replace view public.metric_lost_users as
select id, display_name, last_active_at
from public.profiles
where last_active_at < now() - interval '30 days';

-- ---------------------------------------------------------------------
-- Actividad promedio
-- ---------------------------------------------------------------------
create or replace view public.metric_avg_sessions_per_user as
select round(count(*)::numeric / nullif(count(distinct user_id), 0), 2) as avg_sessions_per_user
from public.quiz_sessions;

create or replace view public.metric_avg_study_minutes as
select round(avg(duration_seconds) / 60.0, 2) as avg_minutes_per_session
from public.quiz_sessions;

-- ---------------------------------------------------------------------
-- Invitaciones, Premium, ingresos
-- ---------------------------------------------------------------------
create or replace view public.metric_successful_invites as
select count(*) as successful_referrals from public.friend_referrals;

create or replace view public.metric_premium_conversion as
select
  count(*) filter (where is_premium) as premium_users,
  count(*) as total_users,
  round(count(*) filter (where is_premium)::numeric / nullif(count(*), 0), 4) as conversion_rate
from public.profiles;

create or replace view public.metric_revenue as
select date_trunc('month', purchased_at)::date as month, count(*) as purchases, sum(amount_usd) as revenue_usd
from public.premium_purchases
group by 1
order by 1 desc;

-- ---------------------------------------------------------------------
-- Rankings y segmentación
-- ---------------------------------------------------------------------
create or replace view public.metric_top_players as
select id, display_name, total_points, current_streak_days
from public.profiles
order by total_points desc
limit 100;

create or replace view public.metric_top_referrers as
select referrer_id as user_id, count(*) as successful_referrals, sum(points_awarded) as points_from_referrals
from public.friend_referrals
group by referrer_id
order by successful_referrals desc
limit 100;

create or replace view public.metric_countries as
select country_code, count(*) as users
from public.profiles
group by country_code
order by users desc;

create or replace view public.metric_languages as
select language_code, count(*) as users
from public.profiles
group by language_code
order by users desc;

create or replace view public.metric_app_versions as
select app_version, count(*) as sessions
from public.quiz_sessions
group by app_version
order by sessions desc;

create or replace view public.metric_devices as
select platform, count(*) as devices
from public.user_devices
group by platform
order by devices desc;

-- ---------------------------------------------------------------------
-- Endurecimiento: estas vistas/funciones son SOLO para el dashboard
-- admin (service_role). Se revoca explícitamente el acceso público.
-- ---------------------------------------------------------------------
revoke all on
  public.metric_dau, public.metric_active_users, public.metric_inactive_users,
  public.metric_new_registrations, public.metric_lost_users,
  public.metric_avg_sessions_per_user, public.metric_avg_study_minutes,
  public.metric_successful_invites, public.metric_premium_conversion,
  public.metric_revenue, public.metric_top_players, public.metric_top_referrers,
  public.metric_countries, public.metric_languages, public.metric_app_versions,
  public.metric_devices
from anon, authenticated;

revoke execute on function
  public.metric_wau(date), public.metric_mau(date),
  public.metric_retention(integer), public.metric_recovered_users(date)
from anon, authenticated;
