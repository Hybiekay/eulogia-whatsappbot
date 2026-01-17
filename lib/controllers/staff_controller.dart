import 'package:chatbot/models/user.dart';
import 'package:flint_dart/flint_dart.dart';

class StaffController {
  /// 🔹 Staff Signup
  Future<Response> signup(Request req, Response res) async {
    final body = await req.validate({
      "name": "required|string",
      "staff_id": "required|string",
      "password": "required|string|min:6"
    });

    final staffId = body['staff_id'];

    print(body);

    // Check if staff ID already exists
    final existing = await User().where('staff_id', staffId).first();
    if (existing != null) {
      return res.json({'status': false, 'message': 'Staff ID already exists'},
          status: 400);
    }

    // Hash password
    final hashedPassword = Hashing().hash(body['password']);

    // Create staff record
    final staff = await User().create({
      "name": body['name'],
      "staff_id": body['staff_id'],
      "role": "staff",
      "password": hashedPassword,
    });

    if (staff == null) {
      return res
          .json({'status': false, 'message': 'Signup failed'}, status: 400);
    }

    // Auto-generate token after signup (optional)
    final jwt = FlintJwt(FlintEnv.get("JWT_SECRET"));
    final token = jwt.generateToken(
      {
        'id': staff.id,
        'staff_id': staff.name,
        'role': staff.role,
      },
      expiry: Duration(hours: 24),
    );

    return res.json({
      'status': true,
      'message': 'Signup successful',
      'data': staff.toMap(),
      'token': token,
    });
  }

  /// 🔹 Staff Login
  Future<Response> login(Request req, Response res) async {
    final body = await req
        .validate({"staff_id": "required|string", "password": "required"});
    print(body);

    final staffId = body['staff_id'];
    final password = body['password'];

    final staff = await User().where('staff_id', staffId).first();

    if (staff == null) {
      return res.json({'status': false, 'message': 'Staff not found'});
    }

    // Compare hashed password
    final passwordMatch = Hashing().verify(
      password,
      staff.password.toString(),
    );

    if (!passwordMatch) {
      return res.json({'status': false, 'message': 'Invalid password'});
    }

    // Generate JWT token
    final jwt = FlintJwt(FlintEnv.get("JWT_SECRET"));
    final token = jwt.generateToken(
      {
        'id': staff.id,
        "name": staff.name,
        'staff_id': staff.id,
        'role': staff.role,
      },
      expiry: Duration(hours: 24),
    );
    return res.json({
      'status': true,
      'message': 'Login successful',
      'data': staff.toMap(),
      'token': token,
    });
  }
}
