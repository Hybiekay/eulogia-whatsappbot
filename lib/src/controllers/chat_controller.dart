import 'package:chatbot/src/services/whatsapp_welcome_service.dart';
import 'package:flint_dart/flint_dart.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';

class ChatController {
  final replyService = ChatReplyService();

  Future<ChatConversation> getOrCreateConversation(String customerId) async {
    // Fetch all conversations for this customer
    final conversations =
        await ChatConversation().where('customer_id', customerId);

    // Take the first one if exists
    ChatConversation? conversation =
        conversations.isNotEmpty ? conversations.first : null;

    if (conversation != null) return conversation;

    // Create a new conversation
    conversation = ChatConversation()
      ..customerId = customerId
      ..startedAt = DateTime.now()
      ..lastMessageAt = DateTime.now();

    await conversation.save();
    return conversation;
  }

  /// Add a message to a conversation
  Future<ChatMessage> addMessage({
    required String chatId,
    required String senderId,
    required SenderType senderType,
    required String message,
  }) async {
    final chatMessage = ChatMessage()
      ..chatId = chatId
      ..senderId = senderId
      ..senderType = senderType
      ..message = message
      ..createdAt = DateTime.now();
    print(chatMessage.toMap());
    await chatMessage.save();

    // Update conversation lastMessageAt
    final convId = int.tryParse(chatId.replaceFirst('chat_', ''));
    if (convId != null) {
      final conversations = await ChatConversation().where('id', convId);
      if (conversations.isNotEmpty) {
        final conversation = conversations.first;
        conversation.lastMessageAt = DateTime.now();
        replyService.sendMessage(conversation.customerId ?? "", message);

        await conversation.save();
      }
    }

    return chatMessage;
  }

  /// Get recent chats (for staff sidebar)
  Future<Response> recentChats(Request req, Response res) async {
    final conversations = await ChatConversation().all();

    final recent = <Map<String, dynamic>>[];
    for (var conv in conversations) {
      final messages = await ChatMessage().where('chat_id', 'chat_${conv.id}');
      final lastMsg = messages.isNotEmpty ? messages.last : null;

      recent.add({
        'chatId': 'chat_${conv.id}',
        'customerId': conv.customerId,
        "customer_name": conv.customerName,
        'staffId': conv.staffId,
        'lastMessage': lastMsg?.message ?? '',
        'lastSender': lastMsg?.senderType?.name ?? '',
        'time': conv.updatedAt?.toIso8601String() ??
            conv.lastMessageAt?.toIso8601String() ??
            DateTime.now().toIso8601String(),
      });
    }

    // Sort by time descending - FIXED: Ensure we're comparing strings, not DateTime objects
    recent.sort((a, b) {
      final timeA = a['time'] ?? '';
      final timeB = b['time'] ?? '';
      return timeB.compareTo(timeA); // Compare as strings
    });

    return res.json(recent);
  }

  /// Get full conversation messages
  Future<Response> conversationMessages(Request req, Response res) async {
    final chatId = req.params['chatId']; // e.g., chat_123
    if (chatId == null) {
      return res.json({'status': false, 'message': 'chatId is required'},
          status: 400);
    }

    final messages = await ChatMessage().where('chat_id', chatId);

    final data = messages.asMaps();
    return res.json({
      'chatId': chatId,
      'messages': data,
    });
  }
}
