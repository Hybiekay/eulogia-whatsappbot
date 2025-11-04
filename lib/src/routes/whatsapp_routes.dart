// ✅ Route registration
import 'package:flint_dart/flint_dart.dart';
import 'package:chatbot/src/controllers/whatsapp_controller.dart';

void whatsappRoute(Flint app) {
  final controller = WhatsappController();

  // Webhook verification (GET)
  app.get("/", controller.verifyWebhook);

  // Webhook receiver (POST)
  app.post("/", controller.receiveMessage);
}
