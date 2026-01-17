import 'package:chatbot/routes/api_routes.dart';
import 'package:chatbot/routes/staff_routes.dart';
import 'package:chatbot/routes/whatsapp_routes.dart';
import 'package:flint_dart/flint_dart.dart';

void main() {
  var port = FlintEnv.getInt("PORT", 8080);
  final app = Flint(withDefaultMiddleware: true, viewPath: "lib/src/views/");

  app.get('/', (req, res) async {
    return res.view("login");
  });

  app.get('/chat', (req, res) async {
    return res.view("chat");
  });

  app.get('/sign-up', (req, res) async {
    return res.view("signup");

// return
  });
  app.static(
    '/css',
    'lib/src/views/css',
  );

  // Mount WhatsApp routes
  app.routes(WhatsappRoutes());
  app.routes(StaffRoutes());
  app.routes(ApiRoutes());

  app.listen(port);
}
