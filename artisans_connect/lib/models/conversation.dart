import 'message.dart';

class Conversation {
  const Conversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantAvatarUrl,
    this.lastMessage,
    this.unreadCount = 0,
    this.updatedAt,
    this.messages = const [],
  });

  final String id;
  final String participantId;
  final String participantName;
  final String? participantAvatarUrl;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime? updatedAt;
  final List<Message> messages;

  Conversation copyWith({
    String? id,
    String? participantId,
    String? participantName,
    String? participantAvatarUrl,
    Message? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
    List<Message>? messages,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantAvatarUrl: participantAvatarUrl ?? this.participantAvatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      participantId: json['participantId'] as String,
      participantName: json['participantName'] as String,
      participantAvatarUrl: json['participantAvatarUrl'] as String?,
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((item) => Message.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const <Message>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantId': participantId,
      'participantName': participantName,
      'participantAvatarUrl': participantAvatarUrl,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'updatedAt': updatedAt?.toIso8601String(),
      'messages': messages.map((item) => item.toJson()).toList(),
    };
  }
}
