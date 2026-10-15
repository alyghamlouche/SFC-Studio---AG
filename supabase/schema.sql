-- Run in Supabase SQL Editor. Create client auth users in Supabase Authentication,
-- then link their user IDs in client_members. Promote your own profile to admin.
create extension if not exists pgcrypto;
create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null default '',
 role text not null default 'client' check(role in ('admin','client')),
 created_at timestamptz not null default now()
);
create table public.clients (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 created_at timestamptz not null default now()
);
create table public.client_members (
 client_id uuid not null references public.clients(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,
 primary key(client_id,user_id)
);
create table public.videos (
 id uuid primary key default gen_random_uuid(),
 client_id uuid not null references public.clients(id) on delete cascade,
 title text not null check(length(title) between 1 and 180),
 status text not null default 'to_edit' check(status in ('to_edit','editing','review','changes','approved','delivered')),
 brief text not null default '',
 raw_url text,
 edited_url text,
 due_date date,
 version integer not null default 0 check(version>=0),
 created_by uuid references public.profiles(id) on delete set null,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table public.comments (
 id uuid primary key default gen_random_uuid(),
 video_id uuid not null references public.videos(id) on delete cascade,
 author_id uuid not null references public.profiles(id) on delete cascade,
 body text not null check(length(body) between 1 and 4000),
 created_at timestamptz not null default now()
);
create index on public.videos(client_id);
create index on public.comments(video_id,created_at);
create index on public.client_members(user_id);
create function public.is_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles where id=(select auth.uid()) and role='admin');
$$;
create function public.is_client_member(target uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.client_members where client_id=target and user_id=(select auth.uid()));
$$;
create function public.handle_new_user() returns trigger language plpgsql security definer set search_path='' as $$
begin insert into public.profiles(id,full_name) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''));return new;end;
$$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();
create function public.guard_video_updates() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if not public.is_admin() then
   if not public.is_client_member(old.client_id) then raise exception 'Unauthorized'; end if;
   if old.status <> 'review' or new.status <> 'approved' then raise exception 'Only review approval is allowed'; end if;
   if (to_jsonb(new) - 'status' - 'updated_at') is distinct from (to_jsonb(old) - 'status' - 'updated_at') then
     raise exception 'Clients cannot modify video details';
   end if;
 end if;
 new.updated_at=now();return new;
end;
$$;
create trigger video_update_guard before update on public.videos for each row execute function public.guard_video_updates();
alter table public.profiles enable row level security;
alter table public.clients enable row level security;
alter table public.client_members enable row level security;
alter table public.videos enable row level security;
alter table public.comments enable row level security;
create policy "profile read" on public.profiles for select to authenticated using (id=(select auth.uid()) or public.is_admin());
create policy "clients read" on public.clients for select to authenticated using(public.is_admin() or public.is_client_member(id));
create policy "clients admin insert" on public.clients for insert to authenticated with check(public.is_admin());
create policy "clients admin update" on public.clients for update to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "members read" on public.client_members for select to authenticated using(public.is_admin() or user_id=(select auth.uid()));
create policy "members admin insert" on public.client_members for insert to authenticated with check(public.is_admin());
create policy "members admin delete" on public.client_members for delete to authenticated using(public.is_admin());
create policy "videos read" on public.videos for select to authenticated using(public.is_admin() or public.is_client_member(client_id));
create policy "videos admin insert" on public.videos for insert to authenticated with check(public.is_admin());
create policy "videos update" on public.videos for update to authenticated using(public.is_admin() or public.is_client_member(client_id)) with check(public.is_admin() or public.is_client_member(client_id));
create policy "videos admin delete" on public.videos for delete to authenticated using(public.is_admin());
create policy "comments read" on public.comments for select to authenticated using(exists(select 1 from public.videos v where v.id=video_id and (public.is_admin() or public.is_client_member(v.client_id))));
create policy "comments insert" on public.comments for insert to authenticated with check(author_id=(select auth.uid()) and exists(select 1 from public.videos v where v.id=video_id and (public.is_admin() or public.is_client_member(v.client_id))));
-- For an existing auth user created before running this SQL:
-- insert into public.profiles(id,full_name) values ('USER_UUID','Studio Owner') on conflict(id) do nothing;
-- update public.profiles set role='admin' where id='USER_UUID';
-- insert into public.clients(name) values ('Cedar Properties') returning id;
-- insert into public.client_members(client_id,user_id) values ('CLIENT_UUID','CLIENT_AUTH_USER_UUID');
