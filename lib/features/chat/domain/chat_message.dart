enum MessageSender { client, stylist, assistant }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final MessageSender sender;
  final String text;
  final DateTime createdAt;

  bool get isMine => sender == MessageSender.client;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        sender: MessageSender.values.firstWhere(
          (s) => s.name == json['sender'],
          orElse: () => MessageSender.stylist,
        ),
        text: json['text'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
