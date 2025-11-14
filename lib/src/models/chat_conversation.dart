import 'package:flint_dart/flint_dart.dart';

class ChatConversation extends Model<ChatConversation> {
  int? id;
  String? customerName;
  String? customerId;
  String? staffId;
  bool? escalated = false;
  String? status = 'active'; // 'active', 'closed', 'resolved'
  DateTime? startedAt;
  DateTime? lastMessageAt;
  DateTime? createdAt;
  DateTime? updatedAt;

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        "customer_name": customerName,
        'customer_id': customerId,
        'staff_id': staffId,
        'escalated': escalated,
        'status': status,
        'started_at': startedAt?.toIso8601String(),
        'last_message_at': lastMessageAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String()
      };

  @override
  ChatConversation fromMap(Map<dynamic, dynamic> map) => ChatConversation()
    ..id = map['id']
    ..customerName = map['customer_name']
    ..customerId = map['customer_id']
    ..staffId = map['staff_id']
    ..escalated = _parseBool(map['escalated'])
    ..status = map['status']?.toString() ?? 'active'
    ..startedAt = map['started_at'] is String
        ? DateTime.parse(map['started_at'])
        : map['started_at']
    ..lastMessageAt = map['last_message_at'] is String
        ? DateTime.parse(map['last_message_at'])
        : map['last_message_at']
    ..createdAt = map['created_at'] is String
        ? DateTime.parse(map['created_at'])
        : map['created_at']
    ..updatedAt = map['updated_at'] is String
        ? DateTime.parse(map['updated_at'])
        : map['updated_at'];

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  @override
  Table get table => Table(
        name: 'chat_conversations',
        columns: [
          Column(
            name: 'id',
            type: ColumnType.integer,
            isPrimaryKey: true,
            isAutoIncrement: true,
          ),
          Column(name: 'customer_id', type: ColumnType.string, length: 255),
          Column(
              name: 'customer_name',
              type: ColumnType.string,
              length: 255,
              isNullable: true),
          Column(
              name: 'staff_id',
              type: ColumnType.string,
              length: 255,
              isNullable: true),
          Column(
              name: 'escalated', type: ColumnType.boolean, defaultValue: false),
          Column(
              name: 'status',
              type: ColumnType.string,
              length: 20,
              defaultValue: 'active'),
          Column(name: 'started_at', type: ColumnType.datetime),
          Column(name: 'last_message_at', type: ColumnType.datetime),
        ],
      );
}
