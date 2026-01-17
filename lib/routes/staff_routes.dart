import 'package:chatbot/controllers/staff_controller.dart';
import 'package:flint_dart/flint_dart.dart';

/// Staff API routes
/// @prefix /staff
class StaffRoutes extends RouteGroup {
  final StaffController controller = StaffController();

  @override
  String get prefix => '/staff';

  @override
  String get tag => 'Staff';

  @override
  void register(Flint app) {
    /// @summary Staff login
    /// @auth none
    /// @response 200 Successful login
    /// @response 400 Invalid credentials
    app.post('/login', controller.login);

    /// @summary Staff signup / registration
    /// @auth none
    /// @response 200 Signup successful
    /// @response 400 Bad request
    app.post('/signup', controller.signup);
  }
}
