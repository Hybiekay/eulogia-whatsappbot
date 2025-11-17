import 'package:chatbot/src/routes/api_routes.dart';
import 'package:chatbot/src/routes/staff_routes.dart';
import 'package:flint_dart/flint_dart.dart';
import 'package:chatbot/src/routes/whatsapp_routes.dart';

void main() {
  final app = Flint(withDefaultMiddleware: true, viewPath: "lib/src/views/");

  app.get('/', (req, res) async {
    return res.view("login");
  });

  app.get('/chat', (req, res) async {
    return res.view("chat");
  });

  app.get('/sign-up', (req, res) async {
    return res.view("lib/src/views/signup");

// return
  });
  app.static(
    '/css',
    'lib/src/views/css',
  );

  // Mount WhatsApp routes
  app.mount("/whatsapp", whatsappRoute);
  app.mount("/staff", staffRoute);
  app.mount("/api", apiRoutes);

  app.listen(3000);
}
