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
  updated_at      bigint  not null default 0,
  deleted         boolean not null default false,
  primary key (user_id, uuid)
);

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

-- ================================================== Row Level Security ======
-- Each user can only see and touch their own rows.
alter table public.categories   enable row level security;
alter table public.accounts     enable row level security;
alter table public.transactions enable row level security;

do $$
declare t text;
begin
  foreach t in array array['categories', 'accounts', 'transactions'] loop
    execute format($f$
      drop policy if exists "own rows" on public.%1$I;
      create policy "own rows" on public.%1$I
        for all
        using (user_id = auth.uid())
        with check (user_id = auth.uid());
    $f$, t);
  end loop;
end $$;
