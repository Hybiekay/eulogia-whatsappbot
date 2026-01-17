// src/routes/app_routes.dart

import 'package:chatbot/routes/chat_routes.dart';
import 'package:flint_dart/flint_dart.dart';

/// Main route group for the entire app
class ApiRoutes extends RouteGroup {
  @override
  String get prefix => 'api'; // root

  @override
  List<Middleware> get middlewares => []; // optional global middlewares

  @override
  void register(Flint app) {
    // Home route
    app.routes(ChatRoutes());
    // Auth routes
  }
}
