import 'package:flutter/material.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../services/api/messaging_api_service.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final MessagingApiService _messagingApiService = const MessagingApiService();
  Future<List<Conversation>>? _futureConversations;

  @override
  void initState() {
    super.initState();
    _futureConversations = _loadConversations();
  }

  Future<List<Conversation>> _loadConversations() {
    return _messagingApiService.fetchConversations();
  }

  Future<void> _refresh() async {
    final future = _loadConversations();
    setState(() {
      _futureConversations = future;
    });
    await future.then((_) {}, onError: (_) {});
  }

  void _openConversation(Conversation conversation) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: _ConversationDetailSheet(
            conversation: conversation,
            messagingApiService: _messagingApiService,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messagerie')),
      body: FutureBuilder<List<Conversation>>(
        future: _futureConversations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator());
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Impossible de charger les conversations.',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _refresh,
                    child: const Text('Reessayer'),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? const <Conversation>[];
          if (conversations.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'Aucune conversation',
                    message: 'Lorsque vous contacterez un artisan, la conversation apparaitra ici.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return ConversationTile(
                  conversation: conversation,
                  onTap: () => _openConversation(conversation),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ConversationDetailSheet extends StatefulWidget {
  const _ConversationDetailSheet({
    required this.conversation,
    required this.messagingApiService,
  });

  final Conversation conversation;
  final MessagingApiService messagingApiService;

  @override
  State<_ConversationDetailSheet> createState() => _ConversationDetailSheetState();
}

class _ConversationDetailSheetState extends State<_ConversationDetailSheet> {
  late Future<List<Message>> _futureMessages;

  @override
  void initState() {
    super.initState();
    _futureMessages = widget.messagingApiService.fetchMessages(widget.conversation.id);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.conversation.participantName),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: FutureBuilder<List<Message>>(
          future: _futureMessages,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: LoadingIndicator());
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      'Impossible de charger les messages.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              );
            }

            final messages = snapshot.data ?? const <Message>[];
            if (messages.isEmpty) {
              return const Center(
                child: EmptyState(
                  icon: Icons.mail_outline,
                  title: 'Aucun message',
                  message: 'Dites bonjour pour demarrer la discussion.',
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _MessageTile(message: message);
              },
            );
          },
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(message);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _buildLeadingIcon(message.type),
        title: Text(content),
        subtitle: message.sentAt != null
            ? Text(
                'Envoye a ${message.sentAt!.hour.toString().padLeft(2, '0')}:${message.sentAt!.minute.toString().padLeft(2, '0')}',
              )
            : null,
      ),
    );
  }

  String _buildContent(Message message) {
    switch (message.type) {
      case MessageType.text:
        return message.content ?? 'Message texte';
      case MessageType.photo:
        return 'Piece jointe (photo)';
      case MessageType.audio:
        final duration = message.durationInSeconds ?? 0;
        return 'Note vocale (${duration}s)';
    }
  }

  Widget _buildLeadingIcon(MessageType type) {
    switch (type) {
      case MessageType.text:
        return const Icon(Icons.text_fields);
      case MessageType.photo:
        return const Icon(Icons.photo_outlined);
      case MessageType.audio:
        return const Icon(Icons.mic_none);
    }
  }
}
