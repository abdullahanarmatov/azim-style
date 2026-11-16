import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/money.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_gate.dart';
import '../data/order_repository.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Мои заказы')),
        body: AuthGate(
          reason: 'Войдите, чтобы видеть историю заказов.',
          builder: (_, _) => const _OrdersList(),
        ),
      );
}

class _OrdersList extends ConsumerWidget {
  const _OrdersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);
    final date = DateFormat('d MMM, HH:mm', 'ru');
    return orders.when(
      data: (list) => list.isEmpty
          ? const MessageView(icon: Icons.receipt_long_outlined, title: 'Заказов пока нет')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 24),
              itemBuilder: (_, i) {
                final o = list[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Заказ ${o.shortId} · ${formatMoney(o.total)}'),
                  subtitle: Text('${date.format(o.createdAt.toLocal())}\n'
                      '${o.lines.map((l) => '${l.title} (${l.size}) × ${l.quantity}').join(', ')}'),
                  isThreeLine: true,
                  trailing: Chip(label: Text(o.status.label)),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myOrdersProvider)),
    );
  }
}
