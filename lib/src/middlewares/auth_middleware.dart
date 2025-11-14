import 'package:flint_dart/flint_dart.dart';

class AuthMiddleware extends Middleware {
  @override
  Handler handle(Handler next) {
    return (Request req, Response res) async {
      final token = req.bearerToken;

      if (token == null) {
        return res.json(
          {'status': false, 'message': 'Missing token'},
          status: 401,
        );
      }

      try {} catch (e) {
        return res.json(
          {'status': false, 'message': 'Invalid or expired token'},
          status: 401,
        );
      }

      return await next(req, res);
    };
  }
}
