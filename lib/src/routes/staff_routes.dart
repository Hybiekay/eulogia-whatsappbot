import 'package:chatbot/src/controllers/staff_controller.dart';
import 'package:flint_dart/flint_dart.dart';

void staffRoute(Flint app) {
  app.post("/login", StaffController().login);
  app.post('/signup', StaffController().signup);
}
