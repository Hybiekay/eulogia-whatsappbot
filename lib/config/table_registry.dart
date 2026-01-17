import 'dart:isolate';

import 'package:chatbot/models/user.dart';
import 'package:chatbot/models/chat_conversation.dart';
import 'package:chatbot/models/chat_message.dart';
import 'package:flint_dart/schema.dart';

void main(_, SendPort? sendPort) {
  runTableRegistry(
      [User().table, ChatMessage().table, ChatConversation().table],
      _,
      sendPort);
}
