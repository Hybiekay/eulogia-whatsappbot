import 'dart:isolate';

import 'package:flint_dart/schema.dart';
import 'package:chatbot/src/models/post_model.dart';
import 'package:chatbot/src/models/user_model.dart';

void main(_, SendPort? sendPort) {
  runTableRegistry([
    User().table,
    PostModel().table,
  ], _, sendPort);
}
