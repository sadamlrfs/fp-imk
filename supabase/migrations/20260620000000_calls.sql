-- ============================================================
-- IMK Prototype - Call history log
-- ============================================================
-- Each row is one call from the perspective of its owner (user_id).
-- Caller and callee each insert their own row when the call ends, so
-- direction is stored per-owner ('incoming' / 'outgoing' / 'missed').

create table if not exists public.calls (
  id               uuid default gen_random_uuid() primary key,
  user_id          uuid references public.profiles(id) on delete cascade,
  contact_id       uuid references public.profiles(id) on delete set null,
  type             text not null check (type in ('voice', 'video')),
  direction        text not null check (direction in ('incoming', 'outgoing', 'missed')),
  duration_seconds integer not null default 0,
  created_at       timestamptz default now()
);

create index if not exists calls_user_id_created_at_idx
  on public.calls (user_id, created_at desc);

alter table public.calls enable row level security;

create policy "Users can read own call log"
  on calls for select using (user_id = auth.uid());

create policy "Users can insert own call log"
  on calls for insert with check (user_id = auth.uid());

create policy "Users can delete own call log"
  on calls for delete using (user_id = auth.uid());

-- Live updates for the Calls tab.
alter publication supabase_realtime add table public.calls;
