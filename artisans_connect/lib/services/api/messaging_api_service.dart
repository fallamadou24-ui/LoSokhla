import '../../models/conversation.dart';
import '../../models/message.dart';

class MessagingApiService {
  const MessagingApiService();

  Future<List<Conversation>> fetchConversations() async {
    // TODO: Impl?menter l'appel API pour r?cup?rer les conversations.
    throw UnimplementedError('fetchConversations() n\'est pas encore impl?ment?.');
  }

  Future<List<Message>> fetchMessages(String conversationId) async {
    // TODO: Impl?menter l'appel API pour r?cup?rer les messages d'une conversation.
    throw UnimplementedError('fetchMessages() n\'est pas encore impl?ment?.');
  }

  Future<Message> sendMessage({
    required String conversationId,
    required MessageType type,
    String? text,
    String? mediaPath,
  }) async {
    // TODO: Impl?menter l'appel API pour envoyer un message.
    throw UnimplementedError('sendMessage() n\'est pas encore impl?ment?.');
  }
}
