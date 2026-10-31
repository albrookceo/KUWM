-- Public recommendations: anyone can post a recommendation with a name.
-- Newsletter sign-ups: anyone can subscribe, but emails are never public.

-- Anonymous posts have no account, so author_id can be empty and a name is stored instead.
alter table public.recommendations alter column author_id drop not null;

alter table public.recommendations
  add column author_name text
  check (author_name is null or length(trim(author_name)) between 1 and 100);

-- Anyone can add a post with a name and no account.
create policy "Anyone can post a recommendation with a name"
  on public.recommendations for insert
  to anon
  with check (
    author_id is null
    and author_name is not null
    and length(trim(author_name)) between 1 and 100
  );

-- Newsletter subscribers. Anyone can add an address, but no one can read the list
-- through the site. The list is only visible in the Supabase dashboard.
create table public.newsletter_subscribers (
  id uuid primary key default gen_random_uuid(),
  email text not null check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' and length(email) <= 254),
  name text,
  created_at timestamptz not null default now()
);
create unique index newsletter_subscribers_email_key on public.newsletter_subscribers (lower(email));
alter table public.newsletter_subscribers enable row level security;

create policy "Anyone can subscribe to the newsletter"
  on public.newsletter_subscribers for insert
  to anon, authenticated
  with check (true);

-- The place or title is optional for posts.
alter table public.recommendations alter column place drop not null;
