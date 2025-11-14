import 'package:flint_dart/flint_dart.dart';
import '../models/staff.dart';

class StaffController {
  /// 🔹 Staff Signup
  Future<Response> signup(Request req, Response res) async {
    final body = await req.validate({
      "name": "required|string",
      "staff_id": "required|string",
      "password": "required|string|min:6"
    });

    final staffId = body['staff_id'];

    // Check if staff ID already exists
    final existing = (await Staff().where('staff_id', staffId)).firstOrNull;
    if (existing != null) {
      return res.json({'status': false, 'message': 'Staff ID already exists'});
    }

    // Hash the password (optional but recommended)
    final hashedPassword =
        Hashing().hash(body['password']); // or body['password']

    final staff = await Staff().create({
      "name": body['name'],
      "staff_id": body['staff_id'],
      "role": "staff",
      "password": hashedPassword
    });

    if (staff != null) {
      return res.json({
        'status': true,
        'message': 'Signup successful',
        'data': staff,
      });
    } else {
      return res.json({
        'status': false,
        'message': 'Signup not successful',
      }, status: 400);
    }
  }

  /// 🔹 Staff Login
  Future<Response> login(Request req, Response res) async {
    final body = await req
        .validate({"staff_id": "required|string", "password": "required"});

    final staffId = body['staff_id'];
    final password = body['password'];

    final staff = (await Staff().where('staff_id', staffId)).firstOrNull;

    if (staff == null) {
      return res.json({'status': false, 'message': 'Staff not found'});
    }

    // Compare hashed password (or plain if not hashed yet)
    final passwordMatch = Hashing().verify(password, staff.password.toString());

    if (!passwordMatch) {
      return res.json({'status': false, 'message': 'Invalid password'});
    }

    return res.json({
      'status': true,
      'message': 'Login successful',
      'data': staff.toMap(),
    });
  }
}
