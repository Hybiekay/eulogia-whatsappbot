import 'dart:convert';
import 'dart:io';

import 'package:chatbot/src/models/chat_conversation.dart';
import 'package:chatbot/src/models/chat_message.dart';
import 'package:flint_dart/flint_dart.dart';

final String verifyToken = FlintEnv.get('WHATSAPP_VERIFY_TOKEN');
final String phoneNumberId = FlintEnv.get('WHATSAPP_PHONE_NUMBER_ID');
final String accessToken = FlintEnv.get('WHATSAPP_ACCESS_TOKEN');

class WhatsappWelcomeService {
  String getReply() {
    return """👋 Welcome to *Eulogia Technologies*.

Choose a product:
1️⃣ *EuCloudHost* - Cloud Hosting Solutions
2️⃣ *Euvate* - Digital Voting Platform  
3️⃣ *SchoolHQ.ng* - School Management System
4️⃣ *Training Class* - Professional Training

Reply with the product number or name.""";
  }

  String getProductInfo(String productName) {
    final lower = productName.toLowerCase();

    switch (lower) {
      case '1':
      case 'eucloudhost':
      case 'cloud hosting':
        return """☁️ *EuCloudHost - Cloud Hosting Solutions*

*Features:*
• SSD Cloud Storage
• 99.9% Uptime Guarantee
• Free SSL Certificates
• 24/7 Technical Support
• Scalable Resources

*Starting at:* ₦5,000/month

Reply with *pricing*, *features* or *support* for more info.""";

      case '2':
      case 'euvate':
      case 'voting':
        return """🗳️ *Euvate - Digital Voting Platform*

*Features:*
• Secure Online Voting
• Real-time Results
• Voter Authentication
• Audit Trail
• Customizable Ballots

*Perfect for:* Elections, Polls, Surveys

Reply with *demo*, *pricing* or *setup* for more info.""";

      case '3':
      case 'schoolhq.ng':
      case 'school':
        return """🏫 *SchoolHQ.ng - School Management System*

*Features:*
• Student Management
• Fee Payment Processing
• Result Management
• Parent Portal
• Timetable Scheduling

*Modules Available:* Primary, Secondary, University

Reply with *demo*, *modules* or *pricing* for more info.""";

      case '4':
      case 'training class':
      case 'training':
        return """🎓 *Training Class - Professional Training*

*Courses Available:*
• Web Development
• Mobile App Development
• Data Science
• Digital Marketing
• Cloud Computing

*Features:* Live Classes, Certificates, Job Support

Reply with *courses*, *schedule* or *fees* for more info.""";

      default:
        return "❌ Product not found. Please choose from:\n1️⃣ EuCloudHost\n2️⃣ Euvate\n3️⃣ SchoolHQ.ng\n4️⃣ Training Class";
    }
  }
}

class ChatReplyService {
  final WhatsappWelcomeService welcomeService = WhatsappWelcomeService();
  final client = FlintClient(baseUrl: "https://graph.facebook.com/v22.0/");
  static String geminiApiKey = FlintEnv.get('GEMINI_API_KEY');
  final aiClient = GeminiProvider(apiKey: geminiApiKey);

  Future<String> generateReply(
    String message, {
    required ChatConversation conversation,
    String? customerId,
    String? customerName,
  }) async {
    final lower = message.trim().toLowerCase();

    // If conversation is closed, reopen it automatically
    if (conversation.status == 'closed' || conversation.status == 'resolved') {
      conversation.status = 'active';
      conversation.lastMessageAt = DateTime.now();
      conversation.updatedAt = DateTime.now();
      conversation.customerName = customerName;
      await conversation.save();

      return """🔄 Welcome back! I've reopened our conversation.

👋 How can I help you today?

You can:
• Type *menu* to see our products
• Ask about any of our services
• Type *close* when you're done""";
    }

    // Handle "new" command - reset current conversation
    if (lower == 'new' || lower == 'new conversation' || lower == 'reset') {
      return await _resetConversation(conversation);
    }

    // Handle conversation closing commands
    if (_isClosingCommand(lower)) {
      return await _handleCloseConversation(conversation, message);
    }

    // Handle satisfaction responses
    if (_isSatisfactionResponse(lower)) {
      return await _handleSatisfactionResponse(conversation, lower);
    }

    // Check for pending conversations first
    final pendingChats =
        await _checkPendingConversations(customerId, conversation.id);
    if (pendingChats.isNotEmpty) {
      return _handlePendingConversationReply(pendingChats.first, message);
    }

    // If already escalated to human
    if (conversation.escalated == true) {
      await _sendEmailToStaff(
        subject: "Follow-up from ${customerId ?? 'customer'}",
        body:
            "Customer message: $message\n\nConversation ID: ${conversation.id}",
      );
      return "🤖 I've notified our team about your follow-up message. They'll respond shortly.";
    }

    // Greetings and menu
    if (_isGreeting(lower)) {
      return welcomeService.getReply();
    }

    // Product selection
    if (_isProductSelection(lower)) {
      return welcomeService.getProductInfo(lower);
    }

    // Product-specific follow-up questions
    if (_isProductFollowUp(
        lower, await _getLastBotMessage(conversation.id.toString()))) {
      return _handleProductFollowUp(
          lower, await _getLastBotMessage(conversation.id.toString()));
    }

    // Check if message is related to our products
    final isProductRelated = await _isProductRelatedQuestion(message);
    if (!isProductRelated) {
      // Before escalating, ask if they want to close
      if (_shouldSuggestClosing(message)) {
        return """🤖 I specialize in helping with *Eulogia Technologies* products. 

It seems you're asking about something outside our services. 

Would you like to:
• Type *menu* to see our products
• Type *close* to end this conversation
• Contact us at hello@eulogiatech.com for other inquiries""";
      }
    }

    // Try AI for product-related questions
    final aiReply = await _askGemini(message, conversation);

    if (aiReply == null || aiReply.trim().isEmpty) {
      await _escalateToHuman(conversation, message, customerName);
      return """🤖 I'm connecting you with our specialist who can better assist with your query. 

They'll respond within a few minutes. 

In the meantime, you can also:
• Type *menu* to see our products
• Visit our website: eulogiatech.com""";
    }

    // Check if AI suggests human escalation
    if (_shouldEscalateToHuman(aiReply)) {
      await _escalateToHuman(conversation, message, customerName);
      return aiReply;
    }

    // After helpful response, ask if they need more help
    if (_shouldAskForSatisfaction(aiReply)) {
      return """$aiReply

---
✅ Was that helpful? Reply:
• *Yes* - if your question is answered
• *No* - if you need more help
• *Close* - to end the conversation""";
    }

    return aiReply;
  }

  bool _isClosingCommand(String message) {
    final closingCommands = [
      'close',
      'end',
      'done',
      'finish',
      'stop',
      'bye',
      'goodbye',
      'exit',
      'quit',
      'that\'s all',
      'no more',
      'thank you'
    ];
    return closingCommands.contains(message);
  }

  bool _isSatisfactionResponse(String message) {
    final satisfactionResponses = [
      'yes',
      'no',
      'y',
      'n',
      'yeah',
      'nah',
      'yep',
      'nope',
      'sure',
      'not really',
      'kind of',
      'perfect',
      'great'
    ];
    return satisfactionResponses.contains(message);
  }

  Future<String> _handleCloseConversation(
      ChatConversation conversation, String message) async {
    // Ask for confirmation before closing
    if (!message.toLowerCase().contains('confirm')) {
      return """🔒 Are you sure you want to close this conversation?

This will end our chat session. You can always message again to start a new conversation.

Reply:
• *Confirm close* - to close the conversation
• *Menu* - to continue browsing our products
• *No* - to keep chatting""";
    }

    // Close the conversation
    conversation.status = 'closed';
    conversation.escalated = false;
    conversation.staffId = null;
    conversation.lastMessageAt = DateTime.now();
    conversation.updatedAt = DateTime.now();
    await conversation.save();

    return """✅ Conversation closed. Thank you for chatting with *Eulogia Technologies*! 

We're here to help with:
☁️ EuCloudHost - Cloud Hosting
🗳️ Euvate - Voting Platform  
🏫 SchoolHQ.ng - School Management
🎓 Training Class - Courses

*Need help again?* Just send any message to reopen this conversation.

Have a great day! 🌟""";
  }

  Future<String> _handleSatisfactionResponse(
      ChatConversation conversation, String response) async {
    if (response == 'yes' ||
        response == 'y' ||
        response == 'yeah' ||
        response == 'yep' ||
        response == 'sure' ||
        response == 'perfect' ||
        response == 'great') {
      return """🎉 Great! I'm glad I could help.

Is there anything else you'd like to know about our products? 

You can:
• Type *menu* to see all products
• Ask about specific features
• Type *close* to end our conversation

We're here to help! 😊""";
    } else {
      // If not satisfied, offer more options
      return """🤔 I'm sorry I couldn't fully help you. 

Would you like to:
• Type *menu* to explore other products
• Type *human* to speak with our support team
• Type *close* to end this conversation
• Ask your question in a different way

I'm here to help you find the right solution!""";
    }
  }

  bool _shouldSuggestClosing(String message) {
    // Suggest closing for clearly unrelated topics
    final unrelatedTopics = [
      'weather',
      'sports',
      'news',
      'movie',
      'music',
      'food',
      'travel',
      'health',
      'politics',
      'other company',
      'competitor',
      'your personal'
    ];
    final lower = message.toLowerCase();
    return unrelatedTopics.any((topic) => lower.contains(topic));
  }

  bool _shouldAskForSatisfaction(String aiReply) {
    // Ask for satisfaction after substantial AI responses
    return aiReply.length > 50 &&
        !aiReply.toLowerCase().contains('human') &&
        !aiReply.toLowerCase().contains('contact') &&
        !aiReply.toLowerCase().contains('escalate');
  }

  Future<String> _resetConversation(ChatConversation conversation) async {
    // Reset the conversation but keep it active
    conversation.escalated = false;
    conversation.staffId = null;
    conversation.status = 'active';
    conversation.lastMessageAt = DateTime.now();
    conversation.updatedAt = DateTime.now();

    await conversation.save();

    return """🔄 Conversation reset! Starting fresh.

👋 Welcome to *Eulogia Technologies*.

Choose a product:
1️⃣ *EuCloudHost* - Cloud Hosting Solutions
2️⃣ *Euvate* - Digital Voting Platform  
3️⃣ *SchoolHQ.ng* - School Management System
4️⃣ *Training Class* - Professional Training

Reply with the product number or name.

Type *close* anytime to end the conversation.""";
  }

  Future<List<ChatConversation>> _checkPendingConversations(
      String? customerId, int? currentConversationId) async {
    if (customerId == null) return [];

    try {
      final allConversations =
          await ChatConversation().where("customer_id", customerId);

      // Filter for escalated conversations that are NOT the current one and are active
      return allConversations
          .where((conv) =>
              conv.escalated == true &&
              conv.id != currentConversationId &&
              conv.status == 'active' &&
              (conv.staffId == null || conv.staffId!.isEmpty))
          .toList();
    } catch (e) {
      print('Error checking pending conversations: $e');
      return [];
    }
  }

  Future<String?> _getLastBotMessage(String chatId) async {
    try {
      final messages = await ChatMessage().where("chat_id", chatId);
      var mess = messages.where((e) => e.senderType == SenderType.ai);

      return mess.isNotEmpty ? mess.first.message : null;
    } catch (e) {
      print('Error getting last bot message: $e');
      return null;
    }
  }

  String _handlePendingConversationReply(
      ChatConversation pendingChat, String newMessage) {
    return """📞 I see you have an ongoing conversation with our support team.

Your message has been added to the existing thread. Our agent will respond shortly.

*Reference:* Ticket #${pendingChat.id}
*Last update:* ${_formatTime(pendingChat.updatedAt)}

Type *new* to start a new conversation about a different topic.""";
  }

  bool _isGreeting(String message) {
    final greetings = [
      'hi',
      'hello',
      'hey',
      'hy',
      'menu',
      'options',
      'product',
      'services',
      'start'
    ];
    return greetings.contains(message);
  }

  bool _isProductSelection(String message) {
    final selections = [
      '1',
      '2',
      '3',
      '4',
      'eucloudhost',
      'euvate',
      'schoolhq.ng',
      'school',
      'training class',
      'training'
    ];
    return selections.contains(message);
  }

  bool _isProductFollowUp(String currentMessage, String? lastMessage) {
    if (lastMessage == null) return false;

    final followUps = {
      'pricing': ['eucloudhost', 'euvate', 'schoolhq.ng', 'training'],
      'features': ['eucloudhost', 'euvate', 'schoolhq.ng', 'training'],
      'demo': ['euvate', 'schoolhq.ng'],
      'support': ['eucloudhost'],
      'courses': ['training'],
      'fees': ['training'],
      'setup': ['euvate'],
      'modules': ['schoolhq.ng'],
      'contact': ['eucloudhost', 'euvate', 'schoolhq.ng', 'training'],
      'sales': ['eucloudhost', 'euvate', 'schoolhq.ng', 'training']
    };

    return followUps.entries.any((entry) {
      final keyword = entry.key;
      final products = entry.value;
      return currentMessage.contains(keyword) &&
          products
              .any((product) => lastMessage.toLowerCase().contains(product));
    });
  }

  String _handleProductFollowUp(String question, String? lastMessage) {
    if (question.contains('pricing') ||
        question.contains('price') ||
        question.contains('cost')) {
      return """💳 *Pricing Information*

*EuCloudHost:* Starting from ₦5,000/month
*Euvate:* Custom pricing based on voters
*SchoolHQ.ng:* From ₦50,000/year  
*Training Class:* Courses from ₦30,000

Reply with the product name for detailed pricing, or *contact* to speak with sales.""";
    }

    if (question.contains('demo') ||
        question.contains('trial') ||
        question.contains('test')) {
      return """🎬 *Demo Request*

Great! To schedule a demo:
1. Visit: eulogiatech.com/demo
2. Or reply with your email and preferred time

Our team will contact you within 24 hours.""";
    }

    if (question.contains('contact') ||
        question.contains('sales') ||
        question.contains('call')) {
      return """📞 *Contact Sales*

*Email:* sales@eulogiatech.com
*Phone:* +234 XXX XXX XXXX
*Website:* eulogiatech.com/contact

Our sales team is available Mon-Fri, 9AM-5PM.""";
    }

    if (question.contains('features') ||
        question.contains('what can') ||
        question.contains('capabilities')) {
      return "🤖 For detailed features, please visit our website at eulogiatech.com or type the product name for specific information.";
    }

    if (question.contains('support') ||
        question.contains('help') ||
        question.contains('issue')) {
      return """🛠️ *Technical Support*

For technical support:
*Email:* support@eulogiatech.com
*Hours:* 24/7 for EuCloudHost, Mon-Sun 8AM-8PM for other products

Please include your account details for faster resolution.""";
    }

    return "🤖 For more specific information, please visit our website or type *contact* to speak with our team.";
  }

  Future<bool> _isProductRelatedQuestion(String message) async {
    final keywords = [
      'hosting',
      'cloud',
      'server',
      'website',
      'domain',
      'ssl',
      'voting',
      'election',
      'poll',
      'survey',
      'ballot',
      'school',
      'student',
      'teacher',
      'fee',
      'result',
      'exam',
      'timetable',
      'training',
      'course',
      'learn',
      'class',
      'certificate',
      'lesson',
      'eulogia',
      'eucloudhost',
      'euvate',
      'schoolhq',
      'tech'
    ];

    final lower = message.toLowerCase();
    return keywords.any((keyword) => lower.contains(keyword));
  }

  bool _shouldEscalateToHuman(String aiReply) {
    final escalationKeywords = [
      'human agent',
      'customer service',
      'contact support',
      'speak with',
      'real person',
      'escalate',
      'live agent'
    ];

    final lower = aiReply.toLowerCase();
    return escalationKeywords.any((keyword) => lower.contains(keyword));
  }

  Future<void> _escalateToHuman(
      ChatConversation conversation, String message, String? email) async {
    try {
      // Update conversation to escalated
      conversation.escalated = true;
      conversation.updatedAt = DateTime.now();
      await conversation.save();

      await _sendEmailToStaff(
        subject: "New Escalated Chat - ${conversation.id}",
        body: """
Customer: ${email ?? 'Unknown'}
Customer ID: ${conversation.customerId}

Message: $message

Conversation ID: ${conversation.id}
Started: ${conversation.startedAt}
        """,
      );
    } catch (e) {
      print('Error escalating to human: $e');
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Unknown';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<String?> _askGemini(
      String userPrompt, ChatConversation conversation) async {
    try {
      // Load and trim documentation context
      final context = await File('data/eulogia_docs.md').readAsString();
      final maxTokens = 1000;
      final trimmedContext = context.split(' ').take(maxTokens).join(' ');
      aiClient.addContextMemory(trimmedContext);

      // Load last 5 messages
      final messagesList = await ChatMessage()
          .where("chat_id", "chat_${conversation.id}")
          .asMaps;
      List<AIMessage> aiMessages = messagesList.map((m) {
        final senderType = m["sender_type"];

        String role;

        if (senderType == SenderType.human.name ||
            senderType == SenderType.staff.name) {
          role = "user";
        } else if (senderType == SenderType.ai.name) {
          role = "assistant";
        } else {
          role = "user"; // fallback
        }
        return AIMessage(
          role: role,
          content: m["message"],
        );
      }).toList();

      final recentMessages = aiMessages.length > 5
          ? aiMessages.sublist(aiMessages.length - 5)
          : aiMessages;

      aiClient.addAllMessage(recentMessages);

      // Ask AI
      final response = await aiClient.request(
        model: 'gemini-2.5-flash',
        prompt: userPrompt,
      );

      final text = response.data["candidates"]?[0]?["content"]["parts"]?[0]
              ?["text"]
          ?.trim();

      return formatMarkdownForWhatsApp(text);
    } catch (e) {
      print("❌ Gemini AI error: $e");
      return null;
    }
  }

  /// Notify human staff and save escalation
  Future<void> _notifyHuman(ChatConversation conversation, String message,
      String? customerEmail) async {
    print("_notifyHuman");
    // Mark conversation as escalated
    conversation.escalated = true;
    conversation.staffId = '';
    conversation.startedAt = DateTime.now();
    await conversation.save();
    // Send email
    await _sendEmailToStaff(
      subject: "Customer needs human assistance",
      body:
          "Customer ${conversation.customerId} sent a message AI couldn't handle:\n\n$message\n\nEmail: ${customerEmail ?? 'N/A'}",
    );
    print("_notifyHuman done");
  }

  /// Send email to staff
  Future<void> _sendEmailToStaff(
      {required String subject, required String body}) async {
    final mailer = Mail();

    await mailer.to("hybiekay2@gmail.com").subject(subject).text(body);
  }

  /// Send WhatsApp message
  Future<void> sendMessage(String to, String message) async {
    final endpoint = "$phoneNumberId/messages";
    final safeMessage = message.replaceAll('\r', '').replaceAll('₦', 'NGN');

    final payload = {
      "messaging_product": "whatsapp",
      "to": to,
      "type": "text",
      "text": {"body": safeMessage},
    };

    try {
      final response = await client.post(
        endpoint,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print(
            "⚠️ Failed to send message: ${response.statusCode} - ${response.error}");
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
