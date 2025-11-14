import 'package:chatbot/src/controllers/chat_controller.dart';
import 'package:flint_dart/flint_dart.dart';

void chatRoute(Flint app) {
  final controller = ChatController();

  // Get recent conversations for sidebar
  app.get('/chats/recent', controller.recentChats);

  // Get full messages for a conversation
  app.get('/chats/:chatId/messages', controller.conversationMessages);

  // Add a new message to a conversation
  app.post('/chats/:chatId/messages', (Request req, Response res) async {
    final chatId = req.params['chatId'];
    final body = await req.json();

    final senderId = body['senderId'];
    final senderType = body['senderType']; // human, staff, ai
    final message = body['message'];

    if (chatId == null ||
        senderId == null ||
        senderType == null ||
        message == null) {
      return res
          .json({'status': false, 'message': 'Missing fields'}, status: 400);
    }

    final chatMessage = await controller.addMessage(
      chatId: chatId,
      senderId: senderId,
      senderType: senderType,
      message: message,
    );

    return res.json({
      'status': true,
      'message': 'Message sent',
      'data': chatMessage.toMap()
    });
  });
}
