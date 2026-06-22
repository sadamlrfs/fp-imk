-- ============================================================
-- IMK Prototype - Initial Schema
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. PROFILES
-- ────────────────────────────────────────────────────────────
create table if not exists public.profiles (
  id             uuid references auth.users on delete cascade primary key,
  name           text not null default 'User',
  avatar_url     text,
  preferred_lang text not null default 'id',
  bio            text default '',
  phone          text default '',
  updated_at     timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "Profiles are publicly viewable"
  on profiles for select using (true);

create policy "Users can insert own profile"
  on profiles for insert with check (auth.uid() = id);

create policy "Users can update own profile"
  on profiles for update using (auth.uid() = id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, preferred_lang)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'lang', 'id')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ────────────────────────────────────────────────────────────
-- 2. CHATS (no RLS policies yet — chat_members doesn't exist)
-- ────────────────────────────────────────────────────────────
create table if not exists public.chats (
  id          uuid default gen_random_uuid() primary key,
  type        text not null check (type in ('direct', 'group')),
  name        text,
  avatar_url  text,
  created_by  uuid references public.profiles(id),
  created_at  timestamptz default now()
);

alter table public.chats enable row level security;

create policy "Authenticated users can create chats"
  on chats for insert with check (auth.uid() is not null);

create policy "Chat creator can update chat"
  on chats for update using (created_by = auth.uid());

-- ────────────────────────────────────────────────────────────
-- 3. CHAT MEMBERS
-- ────────────────────────────────────────────────────────────
create table if not exists public.chat_members (
  id        uuid default gen_random_uuid() primary key,
  chat_id   uuid references public.chats(id) on delete cascade,
  user_id   uuid references public.profiles(id) on delete cascade,
  joined_at timestamptz default now(),
  unique(chat_id, user_id)
);

alter table public.chat_members enable row level security;

create policy "Members can view chat membership"
  on chat_members for select using (
    exists (
      select 1 from public.chat_members cm
      where cm.chat_id = chat_members.chat_id and cm.user_id = auth.uid()
    )
  );

create policy "Authenticated users can add members"
  on chat_members for insert with check (auth.uid() is not null);

-- ────────────────────────────────────────────────────────────
-- 4. CHATS SELECT POLICY (now chat_members exists)
-- ────────────────────────────────────────────────────────────
create policy "Members can view their chats"
  on chats for select using (
    exists (
      select 1 from public.chat_members
      where chat_id = chats.id and user_id = auth.uid()
    )
  );

-- ────────────────────────────────────────────────────────────
-- 5. MESSAGES
-- ────────────────────────────────────────────────────────────
create table if not exists public.messages (
  id               uuid default gen_random_uuid() primary key,
  chat_id          uuid references public.chats(id) on delete cascade,
  sender_id        uuid references public.profiles(id),
  type             text not null check (type in ('text', 'voice', 'image', 'video', 'file')),
  text_en          text,
  text_id          text,
  file_url         text,
  file_name        text,
  duration_seconds integer,
  thumbnail_url    text,
  created_at       timestamptz default now()
);

alter table public.messages enable row level security;

create policy "Members can read messages"
  on messages for select using (
    exists (
      select 1 from public.chat_members
      where chat_id = messages.chat_id and user_id = auth.uid()
    )
  );

create policy "Members can send messages"
  on messages for insert with check (
    sender_id = auth.uid() and
    exists (
      select 1 from public.chat_members
      where chat_id = messages.chat_id and user_id = auth.uid()
    )
  );

-- ────────────────────────────────────────────────────────────
-- 6. CALL SIGNALS
-- ────────────────────────────────────────────────────────────
create table if not exists public.call_signals (
  id           uuid default gen_random_uuid() primary key,
  room_id      text not null,
  from_user    uuid references public.profiles(id),
  to_user      uuid references public.profiles(id),
  signal_type  text not null,
  payload      jsonb not null,
  created_at   timestamptz default now()
);

alter table public.call_signals enable row level security;

create policy "Call participants can read signals"
  on call_signals for select using (
    from_user = auth.uid() or to_user = auth.uid()
  );

create policy "Authenticated users can send signals"
  on call_signals for insert with check (from_user = auth.uid());

-- ────────────────────────────────────────────────────────────
-- 7. REALTIME
-- ────────────────────────────────────────────────────────────
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.call_signals;

-- ────────────────────────────────────────────────────────────
-- 8. STORAGE BUCKETS
-- ────────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('voice-notes', 'voice-notes', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('attachments', 'attachments', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy "Public read voice-notes"
  on storage.objects for select using (bucket_id = 'voice-notes');

create policy "Auth upload voice-notes"
  on storage.objects for insert with check (
    bucket_id = 'voice-notes' and auth.uid() is not null
  );

create policy "Public read attachments"
  on storage.objects for select using (bucket_id = 'attachments');

create policy "Auth upload attachments"
  on storage.objects for insert with check (
    bucket_id = 'attachments' and auth.uid() is not null
  );

create policy "Public read avatars"
  on storage.objects for select using (bucket_id = 'avatars');

create policy "Auth upload avatars"
  on storage.objects for insert with check (
    bucket_id = 'avatars' and auth.uid() is not null
  );

create policy "Auth update avatars"
  on storage.objects for update using (
    bucket_id = 'avatars' and auth.uid() is not null
  );
