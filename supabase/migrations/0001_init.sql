-- Keeping up with Marcus: initial schema, invite gate, and row level security.

-- Invite list. Only emails here can create an account.
-- No client policies: only the dashboard (or service role) can read or change it.
create table public.invites (
  email text primary key,
  invited_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.invites enable row level security;

-- One profile per account.
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  bio text,
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;

-- Posts: blog entries, hot takes, white papers, and photo posts.
-- visibility 'public' is readable by anyone; 'members' requires sign-in.
create table public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null default '',
  image_path text,
  visibility text not null default 'members' check (visibility in ('public', 'members')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.posts enable row level security;

-- Create a profile on sign-up, but only for invited emails.
-- Raising an exception here blocks the account from being created.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.invites where lower(email) = lower(new.email)) then
    raise exception 'This email has not been invited.';
  end if;

  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Profiles: members can read everyone's profile; you can only edit your own.
create policy "Members can read profiles"
  on public.profiles for select
  to authenticated
  using (true);

create policy "Users can update their own profile"
  on public.profiles for update
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Posts: anyone can read public posts; members can read everything.
create policy "Anyone can read public posts"
  on public.posts for select
  to anon
  using (visibility = 'public');

create policy "Members can read all posts"
  on public.posts for select
  to authenticated
  using (true);

-- You can only create posts as yourself.
create policy "Members can create their own posts"
  on public.posts for insert
  to authenticated
  with check (author_id = (select auth.uid()));

create policy "Authors can update their own posts"
  on public.posts for update
  to authenticated
  using (author_id = (select auth.uid()))
  with check (author_id = (select auth.uid()));

create policy "Authors can delete their own posts"
  on public.posts for delete
  to authenticated
  using (author_id = (select auth.uid()));
