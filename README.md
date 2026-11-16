# AZIM STYLE

Мобильное приложение персонального стилиста: каталог с наличием и ценами,
готовые образы, анкета-подбор с AI-стилистом, чат со стилистом, корзина и
оформление заказа. Платформы: Android, iOS, Windows (и web для превью).

## Быстрый старт (демо, без бэкенда)

```bash
flutter pub get
flutter run            # демо-данные, вход: любой e-mail и любые 6 цифр
flutter test           # 22 теста
```

## Подключение Supabase

1. Создайте проект на supabase.com, установите Supabase CLI.
2. `supabase link --project-ref <ref>`
3. `supabase db push` — применит `supabase/migrations`.
   Демо-товары: выполните `supabase/seed.sql` в SQL Editor (по желанию).
4. Auth → Providers → Email: включить, в шаблоне письма использовать
   `{{ .Token }}` (6-значный код вместо ссылки).
5. Назначьте аккаунт стилиста (после его первого входа):
   `update profiles set role = 'stylist' where id = '<uuid>';`
6. AI-стилист:
   ```bash
   supabase secrets set ANTHROPIC_API_KEY=...
   supabase functions deploy ai-stylist
   ```
7. Запуск с бэкендом:
   ```bash
   flutter run --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
               --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable key>
   ```

## Как устроено

| Часть | Где |
|---|---|
| Бренд, контакты, валюта | `lib/core/config/brand.dart` |
| Тема (светлая/тёмная) | `lib/core/theme/` |
| Навигация (5 вкладок, rail на широких экранах) | `lib/core/router/` |
| Каталог, карточка товара | `lib/features/catalog/` |
| Готовые образы | `lib/features/outfits/` |
| Анкета + офлайн-подбор образов | `lib/features/quiz/` |
| Чат (realtime) | `lib/features/chat/` |
| Корзина, оформление | `lib/features/cart/` |
| Заказы | `lib/features/orders/` |
| Вход по коду из письма | `lib/features/auth/` |
| Схема БД + RLS + `place_order` | `supabase/migrations/` |
| AI-стилист (Claude) | `supabase/functions/ai-stylist/` |

**Безопасность.** Цены и остатки пересчитываются на сервере в `place_order`
(атомарное списание остатков). Клиент видит только свои заказы и чат, не может
сменить себе роль и писать от имени стилиста. Ключ Claude хранится только в
секретах Edge Function; ответы модели фильтруются (только реальные товары,
бюджет, обязательные категории). Лимит — 20 AI-запросов на клиента в сутки.
Если AI недоступен, приложение собирает образы локально.

## Проверка RLS

Без Supabase — на любом Postgres 15+ (заглушки `auth` и ролей в
`supabase/tests/supabase_stub.sql`):

```bash
createdb t
cat supabase/tests/supabase_stub.sql supabase/migrations/*.sql supabase/seed.sql | psql -d t
psql -d t -f supabase/tests/rls_test.sql   # → ALL RLS CHECKS PASSED
```

## Что дальше
- Админ-режим стилиста в приложении (заказы, ответы в чате, товары); пока —
  через Supabase Dashboard.
- Push-уведомления о новых сообщениях и статусах заказа (FCM / APNs).
- Онлайн-оплата (Kaspi / Stripe — по стране клиента).
- Реальные фото товаров (Supabase Storage) и иконка/сплэш бренда.
- Сборка в сторы: Codemagic для iOS, Play Console, Microsoft Store (MSIX).
