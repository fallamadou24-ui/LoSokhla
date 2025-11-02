import 'package:flutter/material.dart';

import '../models/conversation.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    this.onTap,
  });

  final Conversation conversation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = _buildSubtitle(conversation);
    final dateLabel = _formatUpdatedAt(conversation.updatedAt);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: conversation.participantAvatarUrl != null
            ? NetworkImage(conversation.participantAvatarUrl!)
            : null,
        child: conversation.participantAvatarUrl == null
            ? Text(
                conversation.participantName.isNotEmpty
                    ? conversation.participantName.characters.first.toUpperCase()
                    : '?',
              )
            : null,
      ),
      title: Text(conversation.participantName),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (dateLabel != null)
            Text(
              dateLabel,
              style: theme.textTheme.bodySmall,
            ),
          if (conversation.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _buildSubtitle(Conversation conversation) {
    final lastMessage = conversation.lastMessage;
    if (lastMessage == null) return null;

    switch (lastMessage.type) {
      case MessageType.text:
        return lastMessage.content ?? 'Message texte';
      case MessageType.photo:
        return 'Piece jointe (photo)';
      case MessageType.audio:
        return 'Note vocale';
    }
  }

  String? _formatUpdatedAt(DateTime? date) {
    if (date == null) return null;
    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
