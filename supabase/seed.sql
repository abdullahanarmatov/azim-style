-- Demo catalog (same items as the in-app demo mode). Replace with real stock.
insert into public.products (title, brand, price, category, sizes, stock, style_tags, colors, description) values
 ('Пальто из шерсти','Atelier',89900,'outerwear','{S,M,L,XL}',4,'{classic,minimal,smart}','{camel,beige}','Прямой силуэт, 80% шерсть.'),
 ('Бомбер нейлоновый','Urban Line',42900,'outerwear','{S,M,L,XL}',6,'{street,casual}','{black}','Лёгкий утеплитель, трикотажные манжеты.'),
 ('Оксфорд-рубашка','Atelier',18900,'tops','{S,M,L,XL}',12,'{classic,smart,casual}','{white,blue}','Плотный хлопок.'),
 ('Водолазка тонкая','Merino Co',22900,'tops','{S,M,L,XL}',8,'{minimal,smart,classic}','{black,beige}','Мериносовая шерсть.'),
 ('Футболка оверсайз','Urban Line',9900,'tops','{S,M,L,XL}',20,'{street,casual,minimal}','{white,black}','Хлопок 240 г/м².'),
 ('Брюки со стрелками','Atelier',27900,'bottoms','{46,48,50,52}',7,'{classic,smart,minimal}','{grey,black}','Шерстяная смесь.'),
 ('Джинсы прямые','Denim Lab',25900,'bottoms','{30,31,32,33,34}',10,'{casual,street,classic}','{blue}','Деним 13 oz.'),
 ('Карго-брюки','Urban Line',21900,'bottoms','{S,M,L,XL}',5,'{street,casual}','{black,khaki}','Свободный крой.'),
 ('Лоферы кожаные','Atelier',45900,'shoes','{40,41,42,43,44}',3,'{classic,smart,minimal}','{black,brown}','Гладкая кожа.'),
 ('Кеды белые','Court',29900,'shoes','{40,41,42,43,44}',9,'{casual,minimal,street}','{white}','Минималистичные кеды.'),
 ('Кожаный ремень','Atelier',12900,'accessories','{One size}',15,'{classic,smart,minimal}','{black,brown}','Ширина 3 см.');

with o as (
  insert into public.outfits (title, occasion, note) values
   ('Офис без галстука','Работа','Собранно, но не формально.'),
   ('Город на выходных','Повседневно','База, которая сочетается со всем гардеробом.')
  returning id, title
)
insert into public.outfit_items (outfit_id, product_id, position)
select o.id, p.id, x.pos
from (values
  ('Офис без галстука','Водолазка тонкая',0), ('Офис без галстука','Брюки со стрелками',1),
  ('Офис без галстука','Лоферы кожаные',2),   ('Офис без галстука','Кожаный ремень',3),
  ('Город на выходных','Оксфорд-рубашка',0),  ('Город на выходных','Джинсы прямые',1),
  ('Город на выходных','Кеды белые',2)
) as x(outfit, product, pos)
join o on o.title = x.outfit
join public.products p on p.title = x.product;
