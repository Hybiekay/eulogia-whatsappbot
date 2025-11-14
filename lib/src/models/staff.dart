import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

class Staff extends Model<Staff> {
  int? id;
  String? staffId; // Unique staff identifier (e.g. STF001)
  String? name;
  String? email;
  String? role;
  String? password;
  String? profilePicUrl;
  DateTime? createdAt;

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'staff_id': staffId,
        'name': name,
        'email': email,
        'role': role,
        'profile_pic_url': profilePicUrl,
        'created_at': createdAt?.toIso8601String(),
      };

  @override
  Staff fromMap(Map<dynamic, dynamic> map) => Staff()
    ..id = map['id']
    ..staffId = map['staff_id']
    ..name = map['name']
    ..email = map['email']
    ..role = map['role']
    ..profilePicUrl = map['profile_pic_url']
    ..password = map['password']
    ..createdAt =
        map['created_at'] != null ? DateTime.parse(map['created_at']) : null;

  @override
  Table get table => Table(
        name: 'staff',
        columns: [
          Column(
            name: 'id',
            type: ColumnType.integer,
            isPrimaryKey: true,
            isAutoIncrement: true,
          ),
          Column(
            name: 'staff_id',
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
            isNullable: true,
          ),
          Column(
            name: 'role',
            type: ColumnType.string,
            length: 100,
            defaultValue: "staff",
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
        ],
      );
}
