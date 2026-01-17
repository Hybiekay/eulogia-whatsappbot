import 'package:chatbot/controllers/whatsapp_controller.dart';
import 'package:flint_dart/flint_dart.dart';

/// WhatsApp API routes
/// @prefix /whatsapp
class WhatsappRoutes extends RouteGroup {
  final WhatsappController controller = WhatsappController();

  @override
  String get prefix => '/whatsapp';

  @override
  String get tag => 'WhatsApp';

  @override
  void register(Flint app) {
    /// @summary Verify webhook (GET)
    /// @auth none
    /// @response 200 Webhook verified
    app.get('/', controller.verifyWebhook);

    /// @summary Receive WhatsApp messages (POST)
    /// @auth none
    /// @response 200 Message received successfully
    app.post('/', controller.receiveMessage);
  }
}
