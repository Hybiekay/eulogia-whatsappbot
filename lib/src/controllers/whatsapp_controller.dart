import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chatbot/src/models/chat_conversation.dart';
import 'package:chatbot/src/models/chat_message.dart';
import 'package:chatbot/src/services/whatsapp_welcome_service.dart';
import 'package:flint_dart/flint_dart.dart';

class WhatsappController {
  final replyService = ChatReplyService();
  final String verifyToken = FlintEnv.get('WHATSAPP_VERIFY_TOKEN');
  final String phoneNumberId = FlintEnv.get('WHATSAPP_PHONE_NUMBER_ID');
  final String accessToken = FlintEnv.get('WHATSAPP_ACCESS_TOKEN');

  /// Webhook verification
  Future<Response> verifyWebhook(Request req, Response res) async {
    final mode = req.query['hub.mode'];
    final challenge = req.query['hub.challenge'];
    final token = req.query['hub.verify_token'];

    if (mode == 'subscribe' && token == verifyToken) {
      return res.send(challenge ?? '');
    }
    return res.status(403).send("Verification failed");
  }

  /// Receive incoming WhatsApp message
  Future<Response> receiveMessage(Request req, Response res) async {
    final body = await req.json();
    print('📨 Received webhook: ${body.toString()}');

    // Ignore status updates (delivered, read, failed, etc.)
    if (_isStatusUpdate(body)) {
      print('📊 Ignoring status update');
      return res.json({'status': 'status_update_ignored'});
    }

    if (body['entry'] != null) {
      final entry = body['entry'][0];
      final changes = entry['changes'][0];
      final messages = changes['value']['messages'];

      if (messages != null && messages.isNotEmpty) {
        final msg = messages[0];
        final messageId = msg['id'];
        final from = msg['from'];
        final text = msg['text']?['body']?.trim() ?? '';
        final timestamp = msg['timestamp'];

        // Get customer name safely
        String customerName = 'Unknown';
        final contacts = changes['value']['contacts'];
        if (contacts != null && contacts.isNotEmpty) {
          customerName = contacts[0]['profile']['name'] ?? 'Unknown';
        }

        // Check if message is too old (more than 5 minutes)
        if (_isOldMessage(timestamp)) {
          print('🕒 Ignoring old message from $timestamp');
          return res.json({'status': 'old_message_ignored'});
        }

        // Check if we've already processed this WhatsApp message ID
        final existingMessages =
            await ChatMessage().where('whatsapp_message_id', messageId);
        if (existingMessages.isNotEmpty) {
          print('🔄 Skipping duplicate WhatsApp message: $messageId');
          return res.json({'status': 'duplicate_ignored'});
        }

        print('💬 Processing new message from $customerName $from: $text');

        await handle(from, customerName, text, messageId);
        print('✅ Successfully processed message from $from');
      }
    }

    return res.json({'status': 'received'});
  }

  Future<void> handle(String from, String customerName, String text,
      String whatsappMessageId) async {
    final conversation = await _getOrCreateConversation(from, customerName);

    // Save user message with WhatsApp message ID
    await ChatMessage().create({
      "chat_id": 'chat_${conversation.id}',
      "sender_id": from,
      "sender_type": "human",
      "message": text,
      "whatsapp_message_id": whatsappMessageId, // Store the WhatsApp ID
      "created_at": DateTime.now(),
    });

    // Generate and send reply
    final reply = await replyService.generateReply(
      text,
      conversation: conversation,
      customerId: from,
    );

    // Save AI reply
    await ChatMessage().create({
      "chat_id": 'chat_${conversation.id}',
      "sender_id": 'ai',
      "sender_type": "ai",
      "message": formatMarkdownForWhatsApp(reply),
      "created_at": DateTime.now(),
    });

    // Update conversation
    conversation.lastMessageAt = DateTime.now();
    conversation.updatedAt = DateTime.now();
    await conversation.save();

    // Send reply via WhatsApp
    await _sendMessage(from, reply);
  }

  /// Create or get existing conversation
  Future<ChatConversation> _getOrCreateConversation(
      String customerId, String customerName) async {
    final list = await ChatConversation().where('customer_id', customerId);
    ChatConversation? conversation = list.isNotEmpty ? list.first : null;

    if (conversation == null) {
      conversation = ChatConversation()
        ..customerName = customerName
        ..customerId = customerId
        ..escalated = false
        ..status = 'active'
        ..staffId = ''
        ..startedAt = DateTime.now()
        ..lastMessageAt = DateTime.now()
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
      return await conversation.save() ?? conversation;
    }
    return conversation;
  }

  /// Check if webhook is a status update (not a new message)
  bool _isStatusUpdate(Map<String, dynamic> body) {
    final entry = body['entry']?[0];
    final changes = entry?['changes']?[0];
    final statuses = changes?['value']?['statuses'];
    return statuses != null && statuses.isNotEmpty;
  }

  /// Check if message is too old (prevents processing historical messages)
  bool _isOldMessage(dynamic timestamp) {
    try {
      // Handle both string and int timestamps
      int timestampInt;
      if (timestamp is String) {
        timestampInt = int.parse(timestamp);
      } else if (timestamp is int) {
        timestampInt = timestamp;
      } else {
        // If we can't parse it, assume it's not old
        return false;
      }

      final messageTime =
          DateTime.fromMillisecondsSinceEpoch(timestampInt * 1000);
      final now = DateTime.now();
      final difference = now.difference(messageTime);

      // Ignore messages older than 5 minutes
      return difference.inMinutes > 5;
    } catch (e) {
      print('⚠️ Error parsing timestamp $timestamp: $e');
      return false; // If we can't parse, don't ignore the message
    }
  }

  /// Send WhatsApp message with error handling for 24-hour rule using http package
  Future<void> _sendMessage(String to, String message) async {
    final url =
        Uri.parse('https://graph.facebook.com/v22.0/$phoneNumberId/messages');
    final safeMessage = message.replaceAll('\r', '').replaceAll('₦', 'NGN');

    final payload = {
      "messaging_product": "whatsapp",
      "to": to,
      "type": "text",
      "text": {"body": safeMessage},
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorBody = jsonDecode(response.body);
        final errorCode = errorBody['error']?['code'];

        if (errorCode == 131047) {
          print(
              '⚠️ Message failed: 24-hour rule violation. Customer needs to message first.');
        } else {
          print(
              '⚠️ Failed to send message: ${response.statusCode} - ${errorBody['error']?['message']}');
        }
      } else {
        print("✅ Message sent to $to");
      }
    } catch (e) {
      print("❌ Error sending WhatsApp message: $e");
    }
  }
}

String formatMarkdownForWhatsApp(String text) {
  if (text.isEmpty) return text;

  // 1. Convert headings (### or ## or #) to bold
  text = text.replaceAllMapped(
      RegExp(r'^(#{1,6})\s*(.+)$', multiLine: true), (m) => '*${m[2]}*');

  // 2. Convert bold **text** to WhatsApp bold
  text = text.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => '*${m[1]}*');

  // 3. Convert italic _text_ to WhatsApp italic
  text = text.replaceAllMapped(RegExp(r'_(.+?)_'), (m) => '_${m[1]}_');

  // 4. Convert list items starting with * or - to WhatsApp-friendly -
  text = text.replaceAllMapped(
      RegExp(r'^\s*[\*\-]\s+(.+)$', multiLine: true), (m) => '- ${m[1]}');

  // 5. Optionally trim extra spaces
  text = text.replaceAll(RegExp(r'\n{2,}'), '\n'); // collapse multiple newlines
  text = text.trim();

  return text;
}
