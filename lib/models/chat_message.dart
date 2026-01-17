import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

enum SenderType { human, staff, ai }

class ChatMessage extends Model<ChatMessage> {
  ChatMessage() : super(() => ChatMessage());

  // Primary key
  int? get id => getAttribute<int>('id');

  // Relations
  String? get chatId => getAttribute<String>('chat_id');
  int? get senderId => getAttribute<int>('sender_id');

  // Sender type (human | staff | ai)
  SenderType? get senderType {
    final value = getAttribute<String>('sender_type');
    return value != null ? SenderType.values.byName(value) : null;
  }

  // Message content
  String? get message => getAttribute<String>('message');

  // WhatsApp integration
  String? get whatsappMessageId => getAttribute<String>('whatsapp_message_id');

  // Timestamp
  DateTime? get createdAt => getAttribute<DateTime>('created_at');

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
          Column(
            name: 'chat_id',
            type: ColumnType.string,
            length: 255,
          ),
          Column(
            name: 'sender_id',
            type: ColumnType.integer,
          ),
          Column(
            name: 'sender_type',
            type: ColumnType.string,
            length: 50,
          ),
          Column(
            name: 'message',
            type: ColumnType.text,
          ),
          Column(
            name: 'whatsapp_message_id',
            type: ColumnType.string,
            length: 255,
            isNullable: true,
          ),
          Column(
            name: 'created_at',
            type: ColumnType.datetime,
          ),
        ],
      );
}
