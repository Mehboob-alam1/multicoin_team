-- Solana Mining Tycoon — run once in the Supabase SQL editor.
-- Firebase stays for Auth, FCM, Remote Config, Analytics.
-- This schema replaces Realtime Database + Firestore.
--
-- Dashboard setup:
-- 1. Authentication → Third-party Auth → enable Firebase
--    (Firebase project ID from google-services.json)
-- 2. Paste project URL + anon key into lib/config/supabase_config.dart
--
-- RLS keys rows by Firebase uid: auth.jwt()->>'sub'

create table if not exists public.players (
  uid text primary key,
  display_name text,
  player_data jsonb not null default '{}'::jsonb,
  premium_expiry_ms bigint,
  boost_expiry_ms bigint,
  one_time_products text[] not null default '{}',
  updated_at timestamptz not null default now()
);

create table if not exists public.leaderboard (
  uid text primary key,
  display_name text not null default 'Miner',
  btc_balance double precision not null default 0,
  total_btc_per_min double precision not null default 0,
  farm_size int not null default 0,
  region text not null default 'all',
  flag text not null default '',
  updated_at timestamptz not null default now()
);

create table if not exists public.purchases (
  id uuid primary key default gen_random_uuid(),
  uid text not null,
  product_id text not null,
  category text,
  source text,
  is_subscription boolean not null default false,
  is_consumable boolean not null default false,
  order_id text,
  purchase_token text,
  rig_id text,
  expiry_ms bigint,
  created_at timestamptz not null default now()
);

create index if not exists purchases_uid_idx on public.purchases (uid);

create table if not exists public.referrals (
  uid text primary key,
  code text not null,
  display_name text,
  friends int not null default 0,
  pending_join_bonuses int not null default 0,
  referred_by text,
  referred_by_code text,
  is_guest boolean not null default false,
  created_at timestamptz not null default now()
);

create unique index if not exists referrals_code_idx on public.referrals (code);

create table if not exists public.referral_codes (
  code text primary key,
  uid text not null
);

create table if not exists public.referral_invites (
  inviter_uid text not null,
  invitee_uid text not null,
  display_name text,
  code_used text,
  joined_at timestamptz not null default now(),
  primary key (inviter_uid, invitee_uid)
);

create table if not exists public.events (
  id text primary key,
  type text,
  mining_multiplier double precision not null default 1,
  rig_discount double precision not null default 0,
  updated_at timestamptz not null default now()
);

insert into public.events (id, type, mining_multiplier, rig_discount)
values ('active', null, 1, 0)
on conflict (id) do nothing;

create table if not exists public.fcm_tokens (
  uid text primary key,
  token text not null,
  region text,
  platform text,
  updated_at timestamptz not null default now()
);

alter table public.players enable row level security;
alter table public.leaderboard enable row level security;
alter table public.purchases enable row level security;
alter table public.referrals enable row level security;
alter table public.referral_codes enable row level security;
alter table public.referral_invites enable row level security;
alter table public.events enable row level security;
alter table public.fcm_tokens enable row level security;

drop policy if exists "players_own" on public.players;
drop policy if exists "leaderboard_read" on public.leaderboard;
drop policy if exists "leaderboard_own_write" on public.leaderboard;
drop policy if exists "leaderboard_own_update" on public.leaderboard;
drop policy if exists "purchases_own" on public.purchases;
drop policy if exists "referrals_own" on public.referrals;
drop policy if exists "referral_codes_read" on public.referral_codes;
drop policy if exists "referral_codes_own_write" on public.referral_codes;
drop policy if exists "invites_as_inviter" on public.referral_invites;
drop policy if exists "events_read" on public.events;
drop policy if exists "fcm_own" on public.fcm_tokens;

create policy "players_own" on public.players
  for all using (uid = (auth.jwt()->>'sub'))
  with check (uid = (auth.jwt()->>'sub'));

create policy "leaderboard_read" on public.leaderboard
  for select using (true);

create policy "leaderboard_own_write" on public.leaderboard
  for insert with check (uid = (auth.jwt()->>'sub'));

create policy "leaderboard_own_update" on public.leaderboard
  for update using (uid = (auth.jwt()->>'sub'))
  with check (uid = (auth.jwt()->>'sub'));

create policy "purchases_own" on public.purchases
  for all using (uid = (auth.jwt()->>'sub'))
  with check (uid = (auth.jwt()->>'sub'));

create policy "referrals_own" on public.referrals
  for all using (uid = (auth.jwt()->>'sub'))
  with check (uid = (auth.jwt()->>'sub'));

create policy "referral_codes_read" on public.referral_codes
  for select using (true);

create policy "referral_codes_own_write" on public.referral_codes
  for insert with check (uid = (auth.jwt()->>'sub'));

create policy "invites_as_inviter" on public.referral_invites
  for select using (inviter_uid = (auth.jwt()->>'sub'));

create policy "events_read" on public.events
  for select using (true);

create policy "fcm_own" on public.fcm_tokens
  for all using (uid = (auth.jwt()->>'sub'))
  with check (uid = (auth.jwt()->>'sub'));

create or replace function public.apply_referral(p_code text, p_display_name text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  invitee text := auth.jwt()->>'sub';
  inviter text;
  already text;
  clean text := upper(trim(p_code));
begin
  if invitee is null or invitee = '' then
    return jsonb_build_object('status', 'error');
  end if;
  select uid into inviter from referral_codes where code = clean;
  if inviter is null then
    select uid into inviter from referrals where code = clean limit 1;
  end if;
  if inviter is null then
    return jsonb_build_object('status', 'invalid');
  end if;
  if inviter = invitee then
    return jsonb_build_object('status', 'self');
  end if;
  select referred_by into already from referrals where uid = invitee;
  if already is not null and already <> '' then
    return jsonb_build_object('status', 'already_used');
  end if;
  insert into referrals (uid, code, display_name, referred_by, referred_by_code)
  values (
    invitee,
    coalesce((select code from referrals where uid = invitee), upper(right(invitee, 6))),
    coalesce(p_display_name, 'Miner'),
    inviter,
    clean
  )
  on conflict (uid) do update set
    referred_by = excluded.referred_by,
    referred_by_code = excluded.referred_by_code,
    display_name = coalesce(excluded.display_name, referrals.display_name);
  insert into referrals (uid, code, friends, pending_join_bonuses)
  values (inviter, clean, 1, 1)
  on conflict (uid) do update set
    friends = referrals.friends + 1,
    pending_join_bonuses = referrals.pending_join_bonuses + 1;
  insert into referral_invites (inviter_uid, invitee_uid, display_name, code_used)
  values (inviter, invitee, coalesce(p_display_name, 'Miner'), clean)
  on conflict do nothing;
  return jsonb_build_object('status', 'success', 'inviter_uid', inviter);
end;
$$;

create or replace function public.consume_referral_bonuses()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  n int;
  me text := auth.jwt()->>'sub';
begin
  if me is null or me = '' then
    return 0;
  end if;
  select pending_join_bonuses into n from referrals where uid = me;
  if n is null or n <= 0 then
    return 0;
  end if;
  update referrals set pending_join_bonuses = 0 where uid = me;
  return n;
end;
$$;

grant execute on function public.apply_referral(text, text) to anon, authenticated;
grant execute on function public.consume_referral_bonuses() to anon, authenticated;
