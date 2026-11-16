import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/env.dart';
import '../data/auth_repository.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  var _codeSent = false;
  var _busy = false;
  String? _error;

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      setState(() => _error = e is AuthFailure
          ? e.message
          : 'Не получилось. Проверьте данные и попробуйте ещё раз.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final repo = ref.read(authRepositoryProvider);
    final email = _email.text.trim();
    if (!_codeSent) {
      if (!_emailRe.hasMatch(email)) {
        setState(() => _error = 'Введите корректный e-mail');
        return;
      }
      await _run(() async {
        await repo.sendCode(email);
        setState(() => _codeSent = true);
      });
    } else {
      await _run(() async {
        await repo.verifyCode(email, _code.text.trim());
        if (!mounted) return;
        context.canPop() ? context.pop() : context.go('/');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_codeSent ? 'Введите код из письма' : 'Войдите по e-mail',
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            _codeSent
                ? 'Мы отправили 6-значный код на ${_email.text.trim()}'
                : 'Без пароля: пришлём одноразовый код. Нужен, чтобы сохранять '
                    'заказы и переписку со стилистом.',
            style: theme.textTheme.bodyMedium,
          ),
          if (!Env.hasSupabase) ...[
            const SizedBox(height: 8),
            Text('Демо-режим: подойдёт любой e-mail и любые 6 цифр.',
                style: theme.textTheme.labelSmall),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: _email,
            enabled: !_codeSent,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'E-mail'),
            onSubmitted: (_) => _submit(),
          ),
          if (_codeSent) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _code,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofillHints: const [AutofillHints.oneTimeCode],
              decoration: const InputDecoration(labelText: 'Код'),
              onSubmitted: (_) => _submit(),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_codeSent ? 'Войти' : 'Получить код'),
          ),
          if (_codeSent)
            TextButton(
              onPressed: _busy ? null : () => setState(() => _codeSent = false),
              child: const Text('Изменить e-mail'),
            ),
        ],
      ),
    );
  }
}
