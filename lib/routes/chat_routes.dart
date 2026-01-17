import 'package:chatbot/controllers/chat_controller.dart';
import 'package:chatbot/middlewares/auth_middleware.dart';
import 'package:chatbot/models/chat_message.dart';
import 'package:flint_dart/flint_dart.dart';

/// Chat API routes
/// @prefix /api/chats
class ChatRoutes extends RouteGroup {
  @override
  String get prefix => '/chats';

  @override
  List<Middleware> get middlewares => [
        AuthMiddleware(), // Optional: require authentication for all chat routes
      ];

  @override
  String get tag => "Chat";

  @override
  void register(Flint app) {
    final chatController = ChatController();

    /// @summary Get recent chats (for staff dashboard/sidebar)
    /// @auth bearer
    /// @response 200 Successful response
    /// @response 401 Unauthorized
    app.get('/recent', chatController.recentChats);

    /// @summary Get messages for a specific conversation
    /// @auth bearer
    /// @response 200 Successful response
    /// @response 401 Unauthorized
    app.get('/:chatId/messages', chatController.conversationMessages);

    /// @summary Send a new message (human, staff, or AI)
    /// @auth bearer
    /// @response 200 Message sent successfully
    /// @response 400 Missing parameters
    /// @response 401 Unauthorized
    app.post('/:chatId/send', (Request req, Response res) async {
      final chatId = req.params['chatId'];
      if (chatId == null) {
        return res.json(
          {'status': false, 'message': 'chatId is required'},
          status: 400,
        );
      }

      final body = await req.json();
      final senderId = body['senderId'];
      final senderTypeStr = body['senderType'];
      final message = body['message'];

      if (senderTypeStr == null || message == null) {
        return res.json(
          {'status': false, 'message': 'Missing parameters'},
          status: 400,
        );
      }

      // Convert senderType string to enum
      final senderType =
          SenderType.values.firstWhere((e) => e.name == senderTypeStr);

      final chatMessage = await chatController.addMessage(
        chatId: chatId,
        senderId: senderId ?? "unknown",
        senderType: senderType,
        message: message,
      );

      return res.json({'status': true, 'message': chatMessage.toMap()});
    });
  }
}
