import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/brand.dart';
import '../../../core/config/env.dart';
import '../domain/chat_message.dart';

/// One conversation per client with the stylist.
abstract interface class ChatRepository {
  Stream<List<ChatMessage>> watchMessages(String clientId);
  Future<void> send(String clientId, String text);
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (Env.hasSupabase) return SupabaseChatRepository(Supabase.instance.client);
  return MockChatRepository();
});

class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository(this._db);
  final SupabaseClient _db;

  @override
  Stream<List<ChatMessage>> watchMessages(String clientId) => _db
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('client_id', clientId)
      .order('created_at', ascending: true)
      .map((rows) => rows.map(ChatMessage.fromJson).toList());

  @override
  Future<void> send(String clientId, String text) => _db
      .from('messages')
      .insert({'client_id': clientId, 'sender': 'client', 'text': text});
}

class MockChatRepository implements ChatRepository {
  MockChatRepository({this.replyDelay = const Duration(milliseconds: 1200)});

  final Duration replyDelay;
  final _messages = <ChatMessage>[
    ChatMessage(
      id: 'm0',
      sender: MessageSender.stylist,
      text: 'Здравствуйте! Я ${Brand.stylistName}. Расскажите, для какого '
          'случая ищете образ — или пройдите анкету, и я соберу варианты.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];
  final _changes = StreamController<List<ChatMessage>>.broadcast();
  var _seq = 1;

  @override
  Stream<List<ChatMessage>> watchMessages(String clientId) async* {
    yield List.unmodifiable(_messages);
    yield* _changes.stream;
  }

  @override
  Future<void> send(String clientId, String text) async {
    _add(MessageSender.client, text);
    unawaited(Future<void>.delayed(replyDelay, () {
      _add(MessageSender.stylist,
          'Принял! Посмотрю наличие и пришлю варианты в течение часа.');
    }));
  }

  void _add(MessageSender sender, String text) {
    _messages.add(ChatMessage(
      id: 'm${_seq++}',
      sender: sender,
      text: text,
      createdAt: DateTime.now(),
    ));
    _changes.add(List.unmodifiable(_messages));
  }
}
