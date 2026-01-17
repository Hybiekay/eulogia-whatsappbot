import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

class User extends Model<User> {
  User() : super(() => User());

  // Primary key
  int? get id => getAttribute<int>('id');

  // Public user identifier (USR001)
  String? get userId => getAttribute<String>('user_id');

  // Profile
  String? get name => getAttribute<String>('name');
  String? get email => getAttribute<String>('email');
  String? get role => getAttribute<String>('role'); // admin | staff | client
  String? get profilePicUrl => getAttribute<String>('profile_pic_url');

  // Security / status
  String? get password => getAttribute<String>('password');
  bool get isActive => getAttribute<bool>('is_active') ?? true;

  // Timestamps

  @override
  Table get table => Table(
        name: 'users',
        columns: [
          Column(
            name: 'id',
            type: ColumnType.integer,
            isPrimaryKey: true,
            isAutoIncrement: true,
          ),
          Column(
            name: 'user_id',
            type: ColumnType.string,
            length: 100,
            isUnique: true,
          ),
          Column(
            name: 'name',
            type: ColumnType.string,
            length: 255,
          ),
          Column(
            name: 'email',
            type: ColumnType.string,
            length: 255,
            isUnique: true,
          ),
          Column(
            name: 'role',
            type: ColumnType.string,
            length: 50,
            defaultValue: 'client',
          ),
          Column(
            name: 'password',
            type: ColumnType.string,
          ),
          Column(
            name: 'profile_pic_url',
            type: ColumnType.string,
            length: 500,
            isNullable: true,
          ),
          Column(
            name: 'is_active',
            type: ColumnType.boolean,
            defaultValue: true,
          ),
        ],
      );
}
