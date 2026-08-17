-- finance_app — Supabase schema for cloud sync (Phase 4, step 4).
--
-- Run this once in your Supabase project → SQL Editor. It creates the three
-- syncable tables mirroring the local Drift schema, keyed by (user_id, uuid)
-- so the app's upserts (onConflict: 'user_id,uuid') work, and locks every row
-- to its owner via Row Level Security.
--
-- Notes:
--  * `uuid` is the app-generated cross-device row identity (text, not a db uuid).
--  * `updated_at` is client millis-since-epoch, used for last-write-wins.
--  * `deleted` is a tombstone flag so deletions propagate to other devices.
--  * Currencies are NOT synced — they're deterministic seed data matched by
--    `code`; accounts/transactions carry `currency_code`.

-- ============================================================ categories ====
create table if not exists public.categories (
  user_id         uuid    not null default auth.uid() references auth.users (id) on delete cascade,
  uuid            text    not null,
  name            text,
  color           bigint,
  icon_color      bigint,
  icon_code_point bigint,
  -- 'expense' | 'income' — the category's hard type.
  kind            text    not null default 'expense',
  updated_at      bigint  not null default 0,
  deleted         boolean not null default false,
  primary key (user_id, uuid)
);
-- Idempotent for deployments created before category typing was added.
alter table public.categories add column if not exists kind text not null default 'expense';

-- ============================================================== accounts ====
create table if not exists public.accounts (
  user_id         uuid    not null default auth.uid() references auth.users (id) on delete cascade,
  uuid            text    not null,
  name            text,
  currency_code   text,
  icon_code_point bigint,
  updated_at      bigint  not null default 0,
  deleted         boolean not null default false,
  primary key (user_id, uuid)
);

-- ========================================================== transactions ====
create table if not exists public.transactions (
  user_id                  uuid    not null default auth.uid() references auth.users (id) on delete cascade,
  uuid                     text    not null,
  account_uuid             text,
  account_destination_uuid text,
  category_uuid            text,
  currency_code            text,
  amount                   double precision,
  date                     text,
  note                     text,
  type                     text,
  is_canceled              boolean not null default false,
  updated_at               bigint  not null default 0,
  deleted                  boolean not null default false,
  primary key (user_id, uuid)
);

-- ============================================================== settings ====
-- App preferences (theme, language, week start, privacy, base currency, …) as
-- a per-user key/value store. Keyed by (user_id, key); LWW on updated_at.
create table if not exists public.settings (
  user_id    uuid   not null default auth.uid() references auth.users (id) on delete cascade,
  key        text   not null,
  value      text,
  updated_at bigint not null default 0,
  primary key (user_id, key)
);

-- ========================================================== entitlements ====
-- The user's premium entitlement. Purchases happen on the website; the billing
-- webhook writes this row server-side (service role, which bypasses RLS). The
-- app only READS its own row (see the select-only policy below) to mirror
-- premium status locally, so a client can never grant itself premium.
create table if not exists public.entitlements (
  user_id    uuid        not null default auth.uid() references auth.users (id) on delete cascade,
  is_premium boolean     not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id)
);

-- To grant premium to a test account by hand, run (in the SQL editor, which is
-- service role, so RLS doesn't block the write):
--   insert into public.entitlements (user_id, is_premium)
--   values ('<the auth.users id>', true)
--   on conflict (user_id) do update set is_premium = excluded.is_premium,
--                                        updated_at = now();

-- ================================================== Row Level Security ======
-- Each user can only see and touch their own rows.
alter table public.categories   enable row level security;
alter table public.accounts     enable row level security;
alter table public.transactions enable row level security;
alter table public.settings     enable row level security;

do $$
declare t text;
begin
  foreach t in array array['categories', 'accounts', 'transactions', 'settings'] loop
    execute format($f$
      drop policy if exists "own rows" on public.%1$I;
      create policy "own rows" on public.%1$I
        for all
        using (user_id = auth.uid())
        with check (user_id = auth.uid());
    $f$, t);
  end loop;
end $$;

-- Entitlement is READ-ONLY for clients: a user may see their own row but never
-- insert or update it (that's the billing webhook's job, via the service role).
alter table public.entitlements enable row level security;
drop policy if exists "read own entitlement" on public.entitlements;
create policy "read own entitlement" on public.entitlements
  for select
  using (user_id = auth.uid());
