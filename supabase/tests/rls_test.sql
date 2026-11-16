-- Security checks for RLS and place_order(). Run against a scratch DB after
-- the migration + seed (see README). Any failed assert aborts with an error.
\set ON_ERROR_STOP 1
begin;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b'),
  ('00000000-0000-0000-0000-0000000000ff');
update public.profiles set role = 'stylist' where id = '00000000-0000-0000-0000-0000000000ff';

create temp table ids as select id, title from public.products;
grant select on ids to authenticated, anon;

-- ── client A ──
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';

do $$ begin
  -- cannot promote self to stylist
  begin
    update public.profiles set role = 'stylist' where id = auth.uid();
    raise exception 'FAIL: role escalation allowed';
  exception when insufficient_privilege then null; end;

  -- cannot edit catalog
  update public.products set price = 1;
  if exists (select 1 from public.products where price = 1) then
    raise exception 'FAIL: client changed prices'; end if;

  -- cannot insert orders directly
  begin
    insert into public.orders (client_id, total, name, phone, address)
    values (auth.uid(), 1, 'x', 'x', 'x');
    raise exception 'FAIL: direct order insert allowed';
  exception when insufficient_privilege then null; end;

  -- cannot speak as stylist
  begin
    insert into public.messages (client_id, sender, text) values (auth.uid(), 'stylist', 'fake');
    raise exception 'FAIL: client posted as stylist';
  exception when insufficient_privilege then null; end;
  insert into public.messages (client_id, sender, text) values (auth.uid(), 'client', 'Привет');
end $$;

-- price/stock come from DB; app-sent price is ignored
select public.place_order(
  jsonb_build_array(jsonb_build_object(
    'product_id', (select id from ids where title = 'Оксфорд-рубашка'),
    'size', 'M', 'quantity', 2, 'unit_price', 1)),
  'Алия', '+77010000000', 'Алматы', '') as order_a \gset

do $$ begin
  if (select total from public.orders) <> 37800 then raise exception 'FAIL: total'; end if;
  -- out of stock is rejected
  begin
    perform public.place_order(jsonb_build_array(jsonb_build_object(
      'product_id', (select id from ids where title = 'Лоферы кожаные'),
      'size', '42', 'quantity', 4)), 'A', '1', 'x', '');
    raise exception 'FAIL: oversold';
  exception when raise_exception then
    if sqlerrm <> 'out_of_stock' then raise; end if;
  end;
  -- wrong size is rejected
  begin
    perform public.place_order(jsonb_build_array(jsonb_build_object(
      'product_id', (select id from ids where title = 'Лоферы кожаные'),
      'size', 'XXL', 'quantity', 1)), 'A', '1', 'x', '');
    raise exception 'FAIL: bad size accepted';
  exception when raise_exception then
    if sqlerrm <> 'invalid_size' then raise; end if;
  end;
end $$;

-- ── client B sees nothing of A ──
set local request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000b';
do $$ begin
  if exists (select 1 from public.orders) then raise exception 'FAIL: B sees A orders'; end if;
  if exists (select 1 from public.order_items) then raise exception 'FAIL: B sees A items'; end if;
  if exists (select 1 from public.messages) then raise exception 'FAIL: B sees A chat'; end if;
  if (select count(*) from public.profiles) <> 1 then raise exception 'FAIL: B sees profiles'; end if;
end $$;

-- ── anonymous visitor can browse the catalog ──
set local role anon;
set local request.jwt.claim.sub = '';
do $$ begin
  if (select count(*) from public.products) <> 11 then raise exception 'FAIL: anon catalog'; end if;
  if (select count(*) from public.outfit_items) <> 7 then raise exception 'FAIL: anon looks'; end if;
  if exists (select 1 from public.orders) then raise exception 'FAIL: anon sees orders'; end if;
end $$;

-- ── stylist sees everything and answers ──
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000ff';
do $$ begin
  if (select count(*) from public.orders) <> 1 then raise exception 'FAIL: stylist orders'; end if;
  update public.orders set status = 'confirmed';
  insert into public.messages (client_id, sender, text)
  values ('00000000-0000-0000-0000-00000000000a', 'stylist', 'Есть в наличии!');
  if (select stock from public.products where title = 'Оксфорд-рубашка') <> 10 then
    raise exception 'FAIL: stock not decremented'; end if;
end $$;

select 'ALL RLS CHECKS PASSED' as result;
rollback;
