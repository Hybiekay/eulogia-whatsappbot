import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

enum SenderType { human, staff, ai }

class ChatMessage extends Model<ChatMessage> {
  int? id;
  String? chatId;
  String? senderId;
  SenderType? senderType;
  String? message;
  String? whatsappMessageId; // Add this field
  DateTime? createdAt;

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'chat_id': chatId,
        'sender_id': senderId,
        'sender_type': senderType?.name,
        'message': message,
        'whatsapp_message_id': whatsappMessageId, // Add this
        'created_at': createdAt?.toIso8601String(),
      };

  @override
  ChatMessage fromMap(Map<dynamic, dynamic> map) => ChatMessage()
    ..id = map['id']
    ..chatId = map['chat_id']
    ..senderId = map['sender_id']
    ..senderType = map['sender_type'] != null
        ? SenderType.values.byName(map['sender_type'])
        : null
    ..message = map['message'] is String
        ? map['message'] as String
        : map['message'] != null
            ? String.fromCharCodes(map['message'])
            : null
    ..whatsappMessageId = map['whatsapp_message_id'] // Add this
    ..createdAt = map['created_at'] is String
        ? DateTime.parse(map['created_at'])
        : map['created_at'];

  @override
  Table get table => Table(
        name: 'chat_messages',
        columns: [
          Column(
            name: 'id',
            type: ColumnType.integer,
            isPrimaryKey: true,
            isAutoIncrement: true,
          ),
          Column(name: 'chat_id', type: ColumnType.string, length: 255),
          Column(name: 'sender_id', type: ColumnType.string, length: 255),
          Column(name: 'sender_type', type: ColumnType.string, length: 50),
          Column(name: 'message', type: ColumnType.text),
          Column(
              name: 'whatsapp_message_id',
              type: ColumnType.string,
              length: 255,
              isNullable: true), // Add this column
          Column(name: 'created_at', type: ColumnType.datetime),
        ],
      );
}
