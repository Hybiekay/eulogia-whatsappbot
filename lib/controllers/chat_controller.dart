import 'package:chatbot/services/whatsapp_welcome_service.dart';
import 'package:flint_dart/flint_dart.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';

class ChatController {
  final replyService = ChatReplyService();
  Future<ChatConversation> getOrCreateConversation(String customerId) async {
    // Fetch all conversations for this customer
    final conversations =
        await ChatConversation().where('customer_id', customerId).get();

    // Take the first one if exists
    ChatConversation? conversation =
        conversations.isNotEmpty ? conversations.first : null;

    if (conversation != null) return conversation;

    // Create a new conversation using setAttributes
    conversation = ChatConversation();
    conversation.setAttributes({
      'customer_id': customerId,
      'started_at': DateTime.now(),
      'last_message_at': DateTime.now(),
      'status': 'active',
      'escalated': false,
    });

    await conversation.save();
    return conversation;
  }

  Future<ChatMessage> addMessage({
    required String chatId,
    required String senderId,
    required SenderType senderType,
    required String message,
    String? preference,
    String? productId,
    String? status,
  }) async {
    final chatMessage = ChatMessage();
    chatMessage.setAttributes({
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_type': senderType.name, // store enum as string
      'message': message,
      'created_at': DateTime.now(),
    });

    await chatMessage.save();

    // Update conversation attributes
    final convId = int.tryParse(chatId.replaceFirst('chat_', ''));
    if (convId != null) {
      final conversations = await ChatConversation().where('id', convId).get();
      if (conversations.isNotEmpty) {
        final conversation = conversations.first;

        // Use setAttributes for bulk update
        final attrs = {
          'last_message_at': DateTime.now(),
          if (preference != null) 'preference': preference,
          if (productId != null) 'product_id': productId,
          if (status != null) 'status': status,
        };

        conversation.setAttributes(attrs);
        await conversation.save();

        // Optionally, send message via WhatsApp
        replyService.sendMessage(conversation.customerId ?? "", message);
      }
    }

    return chatMessage;
  }

  /// Get recent chats (for staff sidebar)
  Future<Response> recentChats(Request req, Response res) async {
    final conversations = await ChatConversation().all();

    final recent = <Map<String, dynamic>>[];
    for (var conv in conversations) {
      final messages =
          await ChatMessage().where('chat_id', 'chat_${conv.id}').get();
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

    final messages = await ChatMessage().where('chat_id', chatId).get();

    final data = messages.asMaps();
    return res.json({
      'chatId': chatId,
      'messages': data,
    });
  }
}
