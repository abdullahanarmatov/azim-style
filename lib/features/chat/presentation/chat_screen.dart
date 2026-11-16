import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/brand.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stylist_avatar.dart';
import '../../auth/presentation/auth_gate.dart';
import '../data/chat_repository.dart';
import '../domain/chat_message.dart';

final messagesProvider =
    StreamProvider.autoDispose.family<List<ChatMessage>, String>(
  (ref, clientId) => ref.watch(chatRepositoryProvider).watchMessages(clientId),
);

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, this.initialText});
  final String? initialText;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          leading: Navigator.of(context).canPop() ? const BackButton() : null,
          title: const Row(
            children: [
              SizedBox(width: 16),
              StylistAvatar(radius: 18),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Brand.stylistName, style: TextStyle(fontSize: 16)),
                    Text('Обычно отвечает в течение часа',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: AuthGate(
          reason: 'Войдите, чтобы переписка со стилистом сохранялась.',
          builder: (_, user) => _Conversation(clientId: user.id, initialText: initialText),
        ),
      );
}

class _Conversation extends ConsumerStatefulWidget {
  const _Conversation({required this.clientId, this.initialText});
  final String clientId;
  final String? initialText;

  @override
  ConsumerState<_Conversation> createState() => _ConversationState();
}

class _ConversationState extends ConsumerState<_Conversation> {
  late final _input = TextEditingController(text: widget.initialText);
  var _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(chatRepositoryProvider).send(widget.clientId, text);
      _input.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Сообщение не отправлено. Повторите.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider(widget.clientId));
    return Column(
      children: [
        Expanded(
          child: messages.when(
            data: (list) => list.isEmpty
                ? const MessageView(
                    icon: Icons.chat_bubble_outline,
                    title: 'Напишите стилисту',
                    message: 'Спросите про наличие, размер или попросите собрать образ.',
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _Bubble(message: list[list.length - 1 - i]),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.invalidate(messagesProvider(widget.clientId)),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Сообщение',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Отправить',
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mine = message.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: mine ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (message.sender == MessageSender.assistant)
                Text('AI-ассистент',
                    style: TextStyle(fontSize: 11, color: scheme.secondary)),
              Text(message.text,
                  style: TextStyle(color: mine ? scheme.onPrimary : scheme.onSurface)),
              const SizedBox(height: 2),
              Text(DateFormat.Hm().format(message.createdAt.toLocal()),
                  style: TextStyle(
                      fontSize: 10,
                      color: (mine ? scheme.onPrimary : scheme.onSurface)
                          .withValues(alpha: 0.6))),
            ],
          ),
        ),
      ),
    );
  }
}
