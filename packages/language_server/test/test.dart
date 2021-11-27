// @dart = 2.9

import 'package:hetu_script_language_server/server_starter.dart';

const jsonRpcVersion = '2.0';

void main(List<String> args) {
  final starter = HTLanguageServer();
  starter.start(args);
}
