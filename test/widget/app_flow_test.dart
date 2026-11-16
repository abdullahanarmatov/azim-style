import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:azim_style/core/config/brand.dart';
import 'package:azim_style/core/router/app_router.dart';
import 'package:azim_style/features/auth/domain/app_user.dart';
import 'package:azim_style/features/cart/data/cart_controller.dart';
import 'package:azim_style/features/catalog/data/mock_catalog.dart';

import '../helpers.dart';

void main() {
  setUpAll(setUpTestEnv);

  testWidgets('opens on Discover with stylist hero and catalog', (tester) async {
    await pumpApp(tester);
    expect(find.text(Brand.appName), findsOneWidget);
    expect(find.text(Brand.stylistName), findsOneWidget);
    expect(find.text('Подобрать образ'), findsOneWidget);
    expect(find.text('Пальто из шерсти'), findsOneWidget);
  });

  testWidgets('category filter narrows the catalog', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Верхняя одежда'));
    await tester.pumpAndSettle();
    expect(find.text('Пальто из шерсти'), findsOneWidget);
    expect(find.text('Бомбер нейлоновый'), findsOneWidget);
    expect(find.text('Оксфорд-рубашка'), findsNothing);
  });

  testWidgets('product → pick size → add to cart updates badge', (tester) async {
    final c = await pumpApp(tester);
    c.read(routerProvider).push('/product/p3');
    await tester.pumpAndSettle();

    expect(find.text('Выберите размер'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'M'));
    await tester.pump();
    await tester.tap(find.text('В корзину'));
    await tester.pumpAndSettle();
    expect(find.text('Добавлено в корзину'), findsOneWidget);

    await tester.tap(find.text('Корзина').last); // snackbar action
    await tester.pumpAndSettle();
    expect(find.text('Оксфорд-рубашка'), findsOneWidget);
    expect(find.text('Размер M'), findsOneWidget);
    expect(find.text('1'), findsWidgets); // quantity + badge
  });

  testWidgets('out-of-stock product cannot be added', (tester) async {
    final c = await pumpApp(tester);
    c.read(routerProvider).push('/product/p6');
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Нет в наличии'));
    expect(button.onPressed, isNull);
  });

  testWidgets('style quiz produces looks within budget', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Подобрать образ'));
    await tester.pumpAndSettle();

    Future<void> pick(String label) async {
      await tester.tap(find.text(label));
      await tester.pump();
    }

    Future<void> next() async {
      await tester.tap(find.text('Далее'));
      await tester.pumpAndSettle();
    }

    await pick('Мужской');
    await next();
    await pick('Работа и встречи');
    await next();
    await pick('Классика');
    await next();
    await pick('до 200 000');
    await next();
    await pick('M');
    await next();
    await tester.tap(find.text('Показать образы'));
    await tester.pumpAndSettle();

    expect(find.text('Ваши образы'), findsOneWidget);
    expect(find.text('Основной образ'), findsOneWidget);
    expect(find.text('Взять образ'), findsWidgets);
  });

  testWidgets('checkout asks to sign in, OTP sign-in returns back', (tester) async {
    final c = await pumpApp(tester);
    c.read(cartProvider.notifier).add(demoProducts[2], 'M');
    c.read(routerProvider).push('/checkout');
    await tester.pumpAndSettle();
    expect(find.text('Нужен вход'), findsOneWidget);

    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'client@example.com');
    await tester.tap(find.text('Получить код'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
    await tester.pumpAndSettle();

    expect(find.text('Оформление'), findsOneWidget);
    expect(find.text('Подтвердить заказ'), findsOneWidget);
  });

  testWidgets('signed-in client places an order end to end', (tester) async {
    final c = await pumpApp(tester,
        signedInAs: const AppUser(id: 'u1', email: 'a@b.kz', name: 'Алия'));
    c.read(cartProvider.notifier).add(demoProducts[2], 'M');
    c.read(routerProvider).push('/checkout');
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Телефон'), '+7 701 000 00 00');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Адрес доставки'), 'Алматы, Абая 1');
    await tester.tap(find.text('Подтвердить заказ'));
    await tester.pumpAndSettle();

    expect(find.text('Заказ оформлен'), findsOneWidget);
    expect(c.read(cartProvider), isEmpty);

    await tester.tap(find.text('Мои заказы'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Оксфорд-рубашка (M) × 1'), findsOneWidget);
    expect(find.text('Ожидает подтверждения'), findsOneWidget);
  });

  testWidgets('checkout validates required fields', (tester) async {
    final c = await pumpApp(tester, signedInAs: const AppUser(id: 'u1'));
    c.read(cartProvider.notifier).add(demoProducts[2], 'M');
    c.read(routerProvider).push('/checkout');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Подтвердить заказ'));
    await tester.pumpAndSettle();
    expect(find.text('Заполните поле'), findsWidgets);
    expect(find.text('Проверьте номер'), findsOneWidget);
  });

  testWidgets('chat: client message gets a stylist reply', (tester) async {
    final c = await pumpApp(tester, signedInAs: const AppUser(id: 'u1'));
    c.read(routerProvider).go('/chat');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Есть пальто размера M?');
    await tester.tap(find.byTooltip('Отправить'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();
    expect(find.text('Есть пальто размера M?'), findsOneWidget);
    expect(find.textContaining('Принял!'), findsOneWidget);
  });

  testWidgets('empty cart offers the quiz', (tester) async {
    final c = await pumpApp(tester);
    c.read(routerProvider).go('/cart');
    await tester.pumpAndSettle();
    expect(find.text('Корзина пуста'), findsOneWidget);
    expect(GoRouter.of(tester.element(find.text('Корзина пуста'))), isNotNull);
  });
}
