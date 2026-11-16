import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/money.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/domain/order.dart';
import '../data/cart_controller.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Оформление')),
        body: AuthGate(
          reason: 'Войдите, чтобы мы сохранили заказ и связались с вами.',
          builder: (_, user) => _CheckoutForm(user: user),
        ),
      );
}

class _CheckoutForm extends ConsumerStatefulWidget {
  const _CheckoutForm({required this.user});
  final AppUser user;

  @override
  ConsumerState<_CheckoutForm> createState() => _CheckoutFormState();
}

class _CheckoutFormState extends ConsumerState<_CheckoutForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.name);
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _comment = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _comment]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final id = await ref.read(orderRepositoryProvider).placeOrder(
            ref.read(cartProvider),
            CheckoutDetails(
              name: _name.text.trim(),
              phone: _phone.text.trim(),
              address: _address.text.trim(),
              comment: _comment.text.trim(),
            ),
          );
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(myOrdersProvider);
      if (mounted) context.pushReplacement('/orders/success?id=$id');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().contains('out_of_stock')
            ? 'Часть товаров закончилась. Обновите корзину.'
            : 'Не удалось оформить заказ. Попробуйте ещё раз.'),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Заполните поле' : null;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return MessageView(
        icon: Icons.shopping_bag_outlined,
        title: 'Корзина пуста',
        actionLabel: 'К покупкам',
        onAction: () => context.go('/'),
      );
    }

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(labelText: 'Имя'),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: const InputDecoration(labelText: 'Телефон', hintText: '+7 ...'),
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
              return digits.length < 10 ? 'Проверьте номер' : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _address,
            maxLines: 2,
            autofillHints: const [AutofillHints.fullStreetAddress],
            decoration: const InputDecoration(labelText: 'Адрес доставки'),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _comment,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Комментарий', hintText: 'Удобное время, примерка и т.п.'),
          ),
          const SizedBox(height: 24),
          for (final i in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(child: Text('${i.product.title} · ${i.size} × ${i.quantity}')),
                  Text(formatMoney(i.subtotal)),
                ],
              ),
            ),
          const Divider(height: 24),
          Row(
            children: [
              Text('К оплате', style: theme.textTheme.titleMedium),
              const Spacer(),
              Text(formatMoney(total), style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 8),
          Text('Оплата при получении или переводом после подтверждения стилистом.',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Подтвердить заказ'),
          ),
        ],
      ),
    );
  }
}
