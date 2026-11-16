-- AZIM STYLE: initial schema.
-- Roles: every signed-up user is a 'client'; the stylist account gets
-- role = 'stylist' (set manually once in the dashboard / SQL editor).

-- ───────────────────────── profiles ─────────────────────────
create table public.profiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  full_name  text,
  phone      text,
  role       text not null default 'client' check (role in ('client', 'stylist')),
  created_at timestamptz not null default now()
);

create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data ->> 'full_name');
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create function public.is_stylist() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'stylist');
$$;

-- ───────────────────────── catalog ─────────────────────────
create table public.products (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  brand       text not null default '',
  price       integer not null check (price >= 0),
  category    text not null check (category in ('outerwear','tops','bottoms','shoes','accessories')),
  sizes       text[] not null default '{}',
  stock       integer not null default 0 check (stock >= 0),
  description text not null default '',
  image_url   text,
  style_tags  text[] not null default '{}',
  colors      text[] not null default '{}',
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index products_category_idx on public.products (category) where is_active;

create table public.outfits (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  occasion     text not null default '',
  note         text not null default '',
  cover_url    text,
  is_published boolean not null default true,
  created_at   timestamptz not null default now()
);

create table public.outfit_items (
  outfit_id  uuid not null references public.outfits (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  position   smallint not null default 0,
  primary key (outfit_id, product_id)
);

-- ───────────────────────── orders ─────────────────────────
create table public.orders (
  id         uuid primary key default gen_random_uuid(),
  client_id  uuid not null references public.profiles (id) on delete cascade,
  status     text not null default 'pending'
             check (status in ('pending','confirmed','shipped','delivered','cancelled')),
  total      integer not null check (total >= 0),
  name       text not null,
  phone      text not null,
  address    text not null,
  comment    text not null default '',
  created_at timestamptz not null default now()
);
create index orders_client_idx on public.orders (client_id, created_at desc);

create table public.order_items (
  id         bigint generated always as identity primary key,
  order_id   uuid not null references public.orders (id) on delete cascade,
  product_id uuid references public.products (id) on delete set null,
  title      text not null,   -- snapshot: survives product edits
  size       text not null,
  quantity   integer not null check (quantity between 1 and 10),
  unit_price integer not null check (unit_price >= 0)
);
create index order_items_order_idx on public.order_items (order_id);

-- ───────────────────────── chat & AI ─────────────────────────
create table public.messages (
  id         uuid primary key default gen_random_uuid(),
  client_id  uuid not null references public.profiles (id) on delete cascade,
  sender     text not null check (sender in ('client','stylist','assistant')),
  text       text not null check (length(text) between 1 and 4000),
  created_at timestamptz not null default now(),
  read_at    timestamptz
);
create index messages_client_idx on public.messages (client_id, created_at);

create table public.style_profiles (
  client_id  uuid primary key references public.profiles (id) on delete cascade,
  answers    jsonb not null,
  updated_at timestamptz not null default now()
);

create table public.ai_requests (
  id         bigint generated always as identity primary key,
  client_id  uuid not null references public.profiles (id) on delete cascade,
  profile    jsonb not null,
  result     jsonb,
  created_at timestamptz not null default now()
);
create index ai_requests_client_idx on public.ai_requests (client_id, created_at);

-- ───────────────────────── place_order ─────────────────────────
-- The only way to create an order. Prices and stock come from the DB, never
-- from the app, and stock is decremented atomically.
create function public.place_order(
  p_items   jsonb,
  p_name    text,
  p_phone   text,
  p_address text,
  p_comment text default ''
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid   uuid := auth.uid();
  v_order uuid;
  v_total integer := 0;
  v_item  jsonb;
  v_prod  public.products%rowtype;
  v_qty   integer;
  v_size  text;
begin
  if v_uid is null then raise exception 'not_authenticated'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) not between 1 and 50 then
    raise exception 'invalid_items';
  end if;
  if coalesce(trim(p_name), '') = '' or coalesce(trim(p_phone), '') = ''
     or coalesce(trim(p_address), '') = '' then
    raise exception 'missing_contact';
  end if;

  insert into public.orders (client_id, total, name, phone, address, comment)
  values (v_uid, 0, trim(p_name), trim(p_phone), trim(p_address), coalesce(trim(p_comment), ''))
  returning id into v_order;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty  := (v_item ->> 'quantity')::integer;
    v_size := v_item ->> 'size';

    select * into v_prod from public.products
     where id = (v_item ->> 'product_id')::uuid and is_active
     for update;

    if not found then raise exception 'product_not_found'; end if;
    if v_qty is null or v_qty not between 1 and 10 then raise exception 'invalid_quantity'; end if;
    if not (v_size = any (v_prod.sizes)) then raise exception 'invalid_size'; end if;
    if v_prod.stock < v_qty then raise exception 'out_of_stock'; end if;

    update public.products set stock = stock - v_qty, updated_at = now() where id = v_prod.id;
    insert into public.order_items (order_id, product_id, title, size, quantity, unit_price)
    values (v_order, v_prod.id, v_prod.title, v_size, v_qty, v_prod.price);
    v_total := v_total + v_prod.price * v_qty;
  end loop;

  update public.orders set total = v_total where id = v_order;
  return v_order;
end $$;

revoke all on function public.place_order(jsonb, text, text, text, text) from public, anon;
grant execute on function public.place_order(jsonb, text, text, text, text) to authenticated;

-- ───────────────────────── Row Level Security ─────────────────────────
alter table public.profiles       enable row level security;
alter table public.products       enable row level security;
alter table public.outfits        enable row level security;
alter table public.outfit_items   enable row level security;
alter table public.orders         enable row level security;
alter table public.order_items    enable row level security;
alter table public.messages       enable row level security;
alter table public.style_profiles enable row level security;
alter table public.ai_requests    enable row level security; -- service role only

-- profiles: own row; stylist sees all. Clients can't change their role.
create policy "profiles: read own or stylist" on public.profiles
  for select using (id = auth.uid() or public.is_stylist());
create policy "profiles: update own" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());
revoke update on public.profiles from authenticated, anon;
grant update (full_name, phone) on public.profiles to authenticated;

-- catalog: public read of live items; stylist manages everything.
create policy "products: public read" on public.products
  for select using (is_active or public.is_stylist());
create policy "products: stylist write" on public.products
  for all using (public.is_stylist()) with check (public.is_stylist());

create policy "outfits: public read" on public.outfits
  for select using (is_published or public.is_stylist());
create policy "outfits: stylist write" on public.outfits
  for all using (public.is_stylist()) with check (public.is_stylist());

create policy "outfit_items: public read" on public.outfit_items
  for select using (exists (
    select 1 from public.outfits o
     where o.id = outfit_id and (o.is_published or public.is_stylist())));
create policy "outfit_items: stylist write" on public.outfit_items
  for all using (public.is_stylist()) with check (public.is_stylist());

-- orders: created only via place_order(); clients read their own,
-- stylist reads all and changes status.
create policy "orders: read own or stylist" on public.orders
  for select using (client_id = auth.uid() or public.is_stylist());
create policy "orders: stylist update" on public.orders
  for update using (public.is_stylist()) with check (public.is_stylist());

create policy "order_items: read via order" on public.order_items
  for select using (exists (
    select 1 from public.orders o
     where o.id = order_id and (o.client_id = auth.uid() or public.is_stylist())));

-- messages: one thread per client with the stylist.
create policy "messages: read own thread or stylist" on public.messages
  for select using (client_id = auth.uid() or public.is_stylist());
create policy "messages: client writes as client" on public.messages
  for insert with check (client_id = auth.uid() and sender = 'client');
create policy "messages: stylist writes as stylist" on public.messages
  for insert with check (public.is_stylist() and sender = 'stylist');
create policy "messages: stylist marks read" on public.messages
  for update using (public.is_stylist()) with check (public.is_stylist());

create policy "style_profiles: own or stylist" on public.style_profiles
  for select using (client_id = auth.uid() or public.is_stylist());

-- Realtime for chat and order status updates.
alter publication supabase_realtime add table public.messages, public.orders;
