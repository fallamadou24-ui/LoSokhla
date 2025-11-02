enum MessageType { text, photo, audio }

class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    this.mediaUrl,
    this.durationInSeconds,
    this.sentAt,
    this.type = MessageType.text,
    this.isRead = false,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String? content;
  final String? mediaUrl;
  final int? durationInSeconds;
  final DateTime? sentAt;
  final MessageType type;
  final bool isRead;

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? mediaUrl,
    int? durationInSeconds,
    DateTime? sentAt,
    MessageType? type,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      sentAt: sentAt ?? this.sentAt,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      durationInSeconds: json['durationInSeconds'] as int?,
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'] as String)
          : null,
      type: MessageType.values.firstWhere(
        (value) => value.name == (json['type'] as String?)?.toLowerCase(),
        orElse: () => MessageType.text,
      ),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'mediaUrl': mediaUrl,
      'durationInSeconds': durationInSeconds,
      'sentAt': sentAt?.toIso8601String(),
      'type': type.name,
      'isRead': isRead,
    };
  }
}
