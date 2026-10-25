-- Comments on posts. Only signed-in members can read or write them.
-- Authors can delete their own comment for 2 hours after posting.
-- There is no update policy, so comments cannot be edited.

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now()
);
alter table public.comments enable row level security;

create policy "Members can read comments"
  on public.comments for select
  to authenticated
  using (true);

create policy "Members can comment as themselves"
  on public.comments for insert
  to authenticated
  with check (author_id = (select auth.uid()));

-- The 2-hour window is enforced here, on the server.
-- A delete after the window matches no rows, so nothing is removed.
create policy "Authors can delete their own comments for 2 hours"
  on public.comments for delete
  to authenticated
  using (
    author_id = (select auth.uid())
    and created_at > now() - interval '2 hours'
  );
