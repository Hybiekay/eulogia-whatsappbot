import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

class ChatConversation extends Model<ChatConversation> {
  ChatConversation() : super(() => ChatConversation());

  // Primary key

  String? get preference =>
      getAttribute<String>('preference'); // stores A/B/C or product name
  String? get productId => getAttribute<String>(
      'product_id'); // stores product internal ID, e.g., 'eucloudhost'

  String? get customerId => getAttribute<String>('customer_id');
  String? get customerName => getAttribute<String>('customer_name');

  // Assigned staff
  String? get staffId => getAttribute<String>('staff_id');

  // Conversation state
  bool get escalated => getAttribute<bool>('escalated') ?? false;
  String get status =>
      getAttribute<String>('status') ?? 'active'; // active | closed | resolved

  // Conversation timestamps
  DateTime? get startedAt => getAttribute<DateTime>('started_at');
  DateTime? get lastMessageAt => getAttribute<DateTime>('last_message_at');

  // Record timestamps
  DateTime? get createdAt => getAttribute<DateTime>('created_at');
  DateTime? get updatedAt => getAttribute<DateTime>('updated_at');

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
          Column(
            name: 'customer_id',
            type: ColumnType.string,
            length: 255,
          ),
          Column(
            name: 'customer_name',
            type: ColumnType.string,
            length: 255,
            isNullable: true,
          ),
          Column(
            name: 'staff_id',
            type: ColumnType.integer,
            isNullable: true,
          ),
          Column(
            name: 'escalated',
            type: ColumnType.boolean,
            defaultValue: false,
          ),
          Column(
            name: 'status',
            type: ColumnType.string,
            length: 20,
            defaultValue: 'active',
          ),
          Column(
            name: 'started_at',
            type: ColumnType.datetime,
          ),
          Column(
            name: 'last_message_at',
            type: ColumnType.datetime,
          ),
          Column(
            name: 'created_at',
            type: ColumnType.datetime,
          ),
          Column(
            name: 'updated_at',
            type: ColumnType.datetime,
          ),
          Column(
              name: 'preference',
              type: ColumnType.string,
              length: 50,
              isNullable: true),
          Column(
              name: 'product_id',
              type: ColumnType.string,
              length: 50,
              isNullable: true),
        ],
      );
}
