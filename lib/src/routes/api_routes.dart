import 'package:chatbot/src/controllers/chat_controller.dart';
import 'package:chatbot/src/models/chat_message.dart';
import 'package:flint_dart/flint_dart.dart';

void apiRoutes(Flint app) {
  final chatController = ChatController();

  /// Route to get recent chats (for staff dashboard/sidebar)
  app.get('/chats/recent', (Request req, Response res) async {
    return await chatController.recentChats(req, res);
  });

  /// Route to get messages for a specific conversation
  app.get('/chats/:chatId/messages', (Request req, Response res) async {
    return await chatController.conversationMessages(req, res);
  });

  /// Route to add a new message (bot or human)
  app.post('/chats/:chatId/send', (Request req, Response res) async {
    final chatId = req.params['chatId'];
    print(chatId);

    if (chatId == null) {
      return res.json({'status': false, 'message': 'chatId is required'},
          status: 400);
    }

    final body = await req.json();
    final senderId = body['senderId'];
    final senderTypeStr = body['senderType'];
    final message = body['message'];

    if (senderTypeStr == null || message == null) {
      print("one is null");
      return res.json({'status': false, 'message': 'Missing parameters'},
          status: 400);
    }
    print(body);
    // Convert senderType string to enum
    final senderType =
        SenderType.values.firstWhere((e) => e.name == senderTypeStr);

    final chatMessage = await chatController.addMessage(
      chatId: chatId,
      senderId: senderId ?? "djh",
      senderType: senderType,
      message: message,
    );

    return res.json({'status': true, 'message': chatMessage.toMap()});
  });
}
