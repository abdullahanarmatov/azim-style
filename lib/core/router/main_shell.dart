import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/cart/data/cart_controller.dart';

/// Bottom navigation on phones, navigation rail on tablets / Windows.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  void _go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    final cartIcon = Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: const Icon(Icons.shopping_bag_outlined),
    );
    final items = [
      (const Icon(Icons.home_outlined), const Icon(Icons.home), 'Главная'),
      (const Icon(Icons.style_outlined), const Icon(Icons.style), 'Образы'),
      (const Icon(Icons.chat_bubble_outline), const Icon(Icons.chat_bubble), 'Стилист'),
      (cartIcon, cartIcon, 'Корзина'),
      (const Icon(Icons.person_outline), const Icon(Icons.person), 'Профиль'),
    ];

    if (MediaQuery.sizeOf(context).width >= 840) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _go,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final (icon, selected, label) in items)
                  NavigationRailDestination(
                      icon: icon, selectedIcon: selected, label: Text(label)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _go,
        destinations: [
          for (final (icon, selected, label) in items)
            NavigationDestination(icon: icon, selectedIcon: selected, label: label),
        ],
      ),
    );
  }
}
