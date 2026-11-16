import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/state_views.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false),
        body: MessageView(
          icon: Icons.check_circle_outline,
          title: 'Заказ оформлен',
          message: 'Номер ${orderId.length > 6 ? orderId.substring(0, 6).toUpperCase() : orderId}. '
              'Стилист проверит наличие и свяжется с вами для подтверждения.',
          actionLabel: 'Мои заказы',
          onAction: () => context.go('/profile/orders'),
        ),
      );
}
