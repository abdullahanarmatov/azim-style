import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/brand.dart';
import '../../../core/utils/links.dart';
import '../../../core/widgets/stylist_avatar.dart';
import '../../auth/data/auth_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            leading: const StylistAvatar(radius: 24),
            title: const Text(Brand.stylistName),
            subtitle: const Text(Brand.stylistTagline),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Instagram'),
            subtitle: const Text(Brand.instagramHandle),
            onTap: openInstagram,
          ),
          if (Brand.whatsappPhone.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('WhatsApp'),
              onTap: () => openWhatsApp(),
            ),
          const Divider(height: 32),
          if (user == null)
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Войти'),
              subtitle: const Text('Чтобы сохранять заказы и переписку'),
              onTap: () => context.push('/sign-in'),
            )
          else
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(user.name ?? user.email ?? 'Клиент'),
              subtitle: user.name != null && user.email != null ? Text(user.email!) : null,
            ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Мои заказы'),
            onTap: () => context.go('/profile/orders'),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: const Text('Пройти анкету стиля'),
            onTap: () => context.push('/quiz'),
          ),
          if (user != null)
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text('Выйти', style: TextStyle(color: theme.colorScheme.error)),
              onTap: () => ref.read(authRepositoryProvider).signOut(),
            ),
        ],
      ),
    );
  }
}
