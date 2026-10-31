-- NYC recommendations: a public list anyone can read.
-- Only signed-in members can add one, and authors can delete their own.

create table public.recommendations (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  place text not null check (length(trim(place)) between 1 and 200),
  body text not null default '' check (length(body) <= 2000),
  created_at timestamptz not null default now()
);
alter table public.recommendations enable row level security;

-- Anyone, signed in or not, can read the list.
create policy "Anyone can read recommendations"
  on public.recommendations for select
  to anon, authenticated
  using (true);

-- Members can add recommendations, but only as themselves.
create policy "Members can add their own recommendations"
  on public.recommendations for insert
  to authenticated
  with check (author_id = (select auth.uid()));

create policy "Authors can delete their own recommendations"
  on public.recommendations for delete
  to authenticated
  using (author_id = (select auth.uid()));
