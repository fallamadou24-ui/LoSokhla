import 'dart:io';

import 'package:flutter/material.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../services/api/api_exception.dart';
import '../services/api/messaging_api_service.dart';
import '../services/audio/audio_service.dart';
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
  final AudioService _audioService = AudioService();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = const [];
  bool _isLoadingMessages = false;
  Object? _loadError;

  bool _isRecording = false;
  bool _isUploading = false;
  DateTime? _recordingStartedAt;

  @override
  void initState() {
    super.initState();
    _messages = List<Message>.from(widget.conversation.messages);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    _loadMessages();
  }

  @override
  void dispose() {
    _audioService.dispose();
    _scrollController.dispose();
    super.dispose();
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
        body: Column(
          children: [
            if (_isLoadingMessages && _messages.isNotEmpty)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildMessagesList()),
            if (_isUploading)
              const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: _buildAudioControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoadingMessages && _messages.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (_loadError != null && _messages.isEmpty) {
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
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _loadMessages(),
              child: const Text('Reessayer'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMessages,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            EmptyState(
              icon: Icons.mail_outline,
              title: 'Aucun message',
              message: 'Dites bonjour pour demarrer la discussion.',
            ),
          ],
        ),
      );
    }

    final listView = ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _MessageTile(message: message);
      },
    );

    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: listView,
    );
  }

  Widget _buildAudioControls() {
    if (_isUploading) {
      return Row(
        children: const [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 12),
          Expanded(child: Text('Envoi de la note vocale...')),
        ],
      );
    }

    if (_isRecording) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Enregistrement en cours...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          IconButton(
            tooltip: 'Annuler',
            icon: const Icon(Icons.close),
            onPressed: _cancelRecording,
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _stopAndSendRecording,
            icon: const Icon(Icons.send),
            label: const Text('Envoyer'),
          ),
        ],
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton.icon(
        onPressed: _startRecording,
        icon: const Icon(Icons.mic),
        label: const Text('Enregistrer une note vocale'),
      ),
    );
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoadingMessages = true;
      _loadError = null;
    });

    try {
      final fetched = await widget.messagingApiService.fetchMessages(widget.conversation.id);
      setState(() {
        _messages = List<Message>.from(fetched);
      });
      _scrollToBottom();
    } on UnimplementedError {
      // Ignore when API is not yet implemented.
    } on ApiException catch (error) {
      setState(() {
        _loadError = error;
      });
    } catch (error) {
      setState(() {
        _loadError = error;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording || _isUploading) {
      return;
    }

    try {
      setState(() {
        _isRecording = true;
        _recordingStartedAt = DateTime.now();
      });
      await _audioService.startRecording();
    } on ApiException catch (error) {
      setState(() {
        _isRecording = false;
        _recordingStartedAt = null;
      });
      _showError(error.message);
    } catch (error) {
      setState(() {
        _isRecording = false;
        _recordingStartedAt = null;
      });
      _showError('Echec du demarrage de l\'enregistrement.');
    }
  }

  Future<void> _stopAndSendRecording() async {
    if (!_isRecording || _isUploading) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    File? audioFile;
    try {
      audioFile = await _audioService.stopRecording();
      setState(() {
        _isRecording = false;
      });

      if (audioFile == null) {
        throw const ApiException('Aucun fichier audio n\'a ete genere.');
      }

      final uploadUrl = await _audioService.uploadRecording(audioFile);
      final durationSeconds = _recordingStartedAt != null
          ? DateTime.now().difference(_recordingStartedAt!).inSeconds
          : null;
      final safeDuration = durationSeconds != null && durationSeconds > 0 ? durationSeconds : 1;

      Message? sentMessage;
      try {
        sentMessage = await widget.messagingApiService.sendMessage(
          conversationId: widget.conversation.id,
          type: MessageType.audio,
          text: null,
          mediaPath: uploadUrl,
        );
      } on UnimplementedError {
        sentMessage = Message(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          conversationId: widget.conversation.id,
          senderId: 'currentUser',
          mediaUrl: uploadUrl,
          type: MessageType.audio,
          durationInSeconds: safeDuration,
          sentAt: DateTime.now(),
          isRead: false,
        );
      }

      if (sentMessage != null) {
        setState(() {
          _messages = List<Message>.from(_messages)..add(sentMessage);
        });
        _scrollToBottom();
      }
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError('Echec de l\'envoi de la note vocale.');
    } finally {
      if (audioFile != null && await audioFile.exists()) {
        await audioFile.delete();
      }
      _recordingStartedAt = null;
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _isRecording = false;
      });
    }
  }

  Future<void> _cancelRecording() async {
    await _audioService.cancelRecording();
    setState(() {
      _isRecording = false;
      _recordingStartedAt = null;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
