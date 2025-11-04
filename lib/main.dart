import 'package:flint_dart/flint_dart.dart';
import 'package:chatbot/src/routes/whatsapp_routes.dart';
import 'package:chatbot/src/views/welcome.dart';

void main() {
  final app = Flint(withDefaultMiddleware: true);

  app.get('/', (req, res) async => res.render(Welcome()));

  // Mount WhatsApp routes
  app.mount("/whatsapp", whatsappRoute);

  app.listen(3000);
}
