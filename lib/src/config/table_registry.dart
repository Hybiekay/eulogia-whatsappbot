import 'dart:isolate';

import 'package:chatbot/src/models/chat_conversation.dart';
import 'package:chatbot/src/models/chat_message.dart';
import 'package:chatbot/src/models/staff.dart';
import 'package:flint_dart/schema.dart';

void main(_, SendPort? sendPort) {
  runTableRegistry(
      [Staff().table, ChatMessage().table, ChatConversation().table],
      _,
      sendPort);
}
