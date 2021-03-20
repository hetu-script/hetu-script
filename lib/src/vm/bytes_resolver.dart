import 'dart:typed_data';

import '../lexicon.dart';

class HTBytesResolver {
  int _curLine = 0;
  int get curLine => _curLine;
  int _curColumn = 0;
  int get curColumn => _curColumn;
  late final String curFileName;

  late String _libName;

  late int _ip; // instruction pointer

  /// 符号表，不同语句块和环境的符号可能会有重名。
  /// key代表ip指针，value代表符号代表的值所在的命名空间上层深度
  final _distances = <int, int>{};

  // 返回每个symbol对应的求值深度
  Map<int, int> resolve(Uint8List bytes, int ip, String fileName, {String libName = HTLexicon.global}) {
    curFileName = fileName;
    _libName = libName;

    _ip = ip;

    return _distances;
  }
}
