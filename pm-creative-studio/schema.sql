-- PM Creative Studio — run in Supabase SQL Editor
create table profiles(id uuid primary key references auth.users on delete cascade, full_name text, role text not null default 'client' check(role in('client','admin')));
create table services(id uuid primary key default gen_random_uuid(), name text not null, category text, description text,
  pricing_model text not null default 'quote' check(pricing_model in('fixed','from','quote')), price numeric(12,2), published bool default true, created_at timestamptz default now());
create table orders(id uuid primary key default gen_random_uuid(), ref text default 'PM-'||upper(substr(md5(random()::text),1,6)),
  user_id uuid references auth.users, customer_email text, service_id uuid references services, service_name text, title text not null, details text,
  price numeric(12,2), status text default 'pending' check(status in('pending','under_review','quoted','approved','in_progress','completed','cancelled')),
  deliverable_path text, created_at timestamptz default now());

create function is_admin() returns bool language sql security definer stable set search_path=public as $$ select exists(select 1 from profiles where id=auth.uid() and role='admin') $$;
create function new_user() returns trigger language plpgsql security definer set search_path=public as $$ begin
  insert into public.profiles(id,full_name) values(new.id,new.raw_user_meta_data->>'full_name'); return new; end $$;
create trigger on_signup after insert on auth.users for each row execute function new_user();

-- server decides price/status/owner: the browser cannot set them
create function order_guard() returns trigger language plpgsql security definer set search_path=public as $$
declare s services; begin
  select * into s from services where id=new.service_id and published;
  if s.id is null then raise exception 'Unknown service'; end if;
  new.user_id:=auth.uid(); new.service_name:=s.name; new.status:='pending'; new.deliverable_path:=null;
  new.price:=case when s.pricing_model='fixed' then s.price end;
  new.customer_email:=(select email from auth.users where id=auth.uid()); return new; end $$;
create trigger order_guard before insert on orders for each row execute function order_guard();

alter table profiles enable row level security; alter table services enable row level security; alter table orders enable row level security;
create policy p_sel on profiles for select using(id=auth.uid() or is_admin());
create policy s_sel on services for select using(published or is_admin());
create policy s_all on services for all using(is_admin()) with check(is_admin());
create policy o_sel on orders for select using(user_id=auth.uid() or is_admin());
create policy o_ins on orders for insert with check(user_id=auth.uid());
create policy o_upd on orders for update using(is_admin()) with check(is_admin());

-- private bucket: path = <order_id>/<file>
insert into storage.buckets(id,name,public) values('deliverables','deliverables',false) on conflict do nothing;
create policy d_admin on storage.objects for all using(bucket_id='deliverables' and is_admin()) with check(bucket_id='deliverables' and is_admin());
create policy d_owner on storage.objects for select using(bucket_id='deliverables' and exists(
  select 1 from orders o where o.id::text=split_part(name,'/',1) and o.user_id=auth.uid()));

-- starter services: NO prices invented — set real ones in the admin dashboard
insert into services(name,category,description) values
('Graphic Design','Design','Flyers, posters, church & event graphics, marketing materials.'),
('Branding & Visual Identity','Branding','Logos and complete brand identities.'),
('Website Design & Development','Web','Business websites built to professional standards.'),
('Website Maintenance','Web','Updates, fixes and hosting support.'),
('Digital Business Solutions','Digital','Booking, ordering and management systems.');

-- FIRST ADMIN: sign up on the site, then run with your email:
-- update profiles set role='admin' where id=(select id from auth.users where email='prenonmpanga023@gmail.com');
