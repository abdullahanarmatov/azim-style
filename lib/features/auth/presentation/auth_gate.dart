import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/state_views.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

/// Shows [builder] for signed-in users, otherwise a friendly sign-in prompt.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.reason, required this.builder});

  final String reason;
  final Widget Function(BuildContext context, AppUser user) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      data: (user) => user != null
          ? builder(context, user)
          : MessageView(
              icon: Icons.lock_outline,
              title: 'Нужен вход',
              message: reason,
              actionLabel: 'Войти',
              onAction: () => context.push('/sign-in'),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          ErrorView(error: e, onRetry: () => ref.invalidate(authStateProvider)),
    );
  }
}
