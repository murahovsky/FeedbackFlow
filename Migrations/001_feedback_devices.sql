-- FeedbackFlow: one email per device, asked once.
--
-- Votes and comments only carry device_id, so anyone who votes without ever
-- filing a request is unreachable. This table maps a device to an email the
-- user chose to give us, which makes every vote and comment from that device
-- (past ones included) traceable back to someone we can reply to.

create table if not exists public.feedback_devices (
    device_id   text primary key,
    email       text not null,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now()
);

create index if not exists feedback_devices_email_idx
    on public.feedback_devices (email);

-- Keep updated_at honest on upsert.
create or replace function public.feedback_devices_touch()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists feedback_devices_touch on public.feedback_devices;
create trigger feedback_devices_touch
    before update on public.feedback_devices
    for each row execute function public.feedback_devices_touch();

alter table public.feedback_devices enable row level security;

-- No policies at all: the anon key that ships inside the app gets neither read
-- nor write access to this table. Writes go through set_device_email() below.
--
-- Why a function instead of an insert policy: PostgREST upserts compile to
-- ON CONFLICT DO UPDATE, and under RLS that path also demands a SELECT policy
-- so Postgres can read the conflicting row. Any SELECT policy broad enough to
-- allow that would also let anyone dump the whole email list with the app's key.

create or replace function public.set_device_email(p_device_id text, p_email text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    if p_email is null or btrim(p_email) = '' then
        return;
    end if;

    insert into public.feedback_devices (device_id, email)
    values (p_device_id, btrim(p_email))
    on conflict (device_id) do update set email = excluded.email;
end;
$$;

grant execute on function public.set_device_email(text, text) to public;

-- Backfill from people who already left an email on a request.
insert into public.feedback_devices (device_id, email)
select distinct on (device_id) device_id, email
from public.feedback_requests
where device_id is not null
  and email is not null
  and email <> ''
order by device_id, created_at desc
on conflict (device_id) do nothing;

-- Reporting helpers: this is what turns "24 votes" into "24 people to email".
-- Query with the service role from the dashboard.
create or replace view public.feedback_votes_with_email as
select v.id,
       v.request_id,
       r.title as request_title,
       v.device_id,
       d.email,
       v.created_at
from public.feedback_votes v
join public.feedback_requests r on r.id = v.request_id
left join public.feedback_devices d on d.device_id = v.device_id;

create or replace view public.feedback_comments_with_email as
select c.id,
       c.request_id,
       r.title as request_title,
       c.body,
       c.device_id,
       d.email,
       c.created_at
from public.feedback_comments c
join public.feedback_requests r on r.id = c.request_id
left join public.feedback_devices d on d.device_id = c.device_id;

-- Views run with the owner's rights and would bypass RLS, so close them off
-- to the client-side roles explicitly.
revoke all on public.feedback_votes_with_email from anon, authenticated;
revoke all on public.feedback_comments_with_email from anon, authenticated;
