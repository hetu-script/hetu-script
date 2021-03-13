import 'dart:typed_data';

import 'common.dart';
import 'binding.dart';
import 'parser.dart';
import 'lexicon.dart';
import 'compiler.dart';
import 'operator.dart';

enum Instruction {
  opReturn,
}

class HT_VM implements CodeRunner {
  String _curFileName;
  String _curDirectory;
  @override
  String get curFileName => _curFileName;
  @override
  String get curDirectory => _curDirectory;

  HT_VM();

  Uint8List _byteList;
  int _ip;

  @override
  void loadExternalFunctions(Map<String, HT_ExternFunc> lib) {}

  @override
  dynamic eval(
    String content, {
    String fileName,
    String libName = HT_Lexicon.globals,
    HT_Context context,
    ParseStyle style = ParseStyle.library,
    String invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) {
    _byteList = Compiler().compile('');
    _ip = 0;

    while (true) {
      final instruction = readByte();
      switch (instruction) {
        case HT_Operator.RETURN:
          {
            print('Succesfully run.');
            return;
          }
      }
    }
  }

  int readByte() {
    return _byteList[_ip++];
  }
}
