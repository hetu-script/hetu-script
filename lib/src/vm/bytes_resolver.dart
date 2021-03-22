import 'dart:typed_data';

import '../lexicon.dart';
import 'opcode.dart';
import 'bytes_reader.dart';

class HTBytesResolver {
  late BytesReader _bytesReader;

  int _curLine = 0;
  int get curLine => _curLine;
  int _curColumn = 0;
  int get curColumn => _curColumn;
  late final String curFileName;

  late String _libName;

  /// 符号表，不同语句块和环境的符号可能会有重名。
  /// key代表ip指针，value代表符号代表的值所在的命名空间上层深度
  final _distances = <int, int>{};

  // 返回每个symbol对应的求值深度
  Map<int, int> resolve(Uint8List bytes, int ip, String fileName, {String libName = HTLexicon.global}) {
    _bytesReader = BytesReader(bytes);

    curFileName = fileName;
    _libName = libName;

    return _distances;
  }

  dynamic _resolve(int pos) {
    final savedIp = _bytesReader.ip;

    _bytesReader.ip = pos;

    var instruction = _bytesReader.read();
    while (instruction != HTOpCode.endOfFile) {
      switch (instruction) {
        // 返回当前运算值
        case HTOpCode.endOfExec:
        // _ip = savedIp;
        // return _curValue;
        // 语句结束
        case HTOpCode.endOfStmt:
          break;
        // 从字节码读取常量表并保存在当前环境中
        case HTOpCode.constTable:
          var table_length = _bytesReader.readUint16();
          for (var i = 0; i < table_length; ++i) {
            _bytesReader.readInt64();
          }
          table_length = _bytesReader.readUint16();
          for (var i = 0; i < table_length; ++i) {
            _bytesReader.readFloat64();
          }
          table_length = _bytesReader.readUint16();
          for (var i = 0; i < table_length; ++i) {
            _bytesReader.readUtf8String();
          }
          break;
        // 将字面量存储在本地变量中
        case HTOpCode.local:
          final oprandType = _bytesReader.read();
          switch (oprandType) {
            case HTValueTypeCode.NULL:
              break;
            case HTValueTypeCode.boolean:
              _bytesReader.read();
              break;
            case HTValueTypeCode.int64:
            case HTValueTypeCode.float64:
            case HTValueTypeCode.utf8String:
              _bytesReader.readUint16();
              break;
            // 当前符号（变量名）
            case HTValueTypeCode.symbol:
            // _curValue = curNamespace.fetch(varName)
          }
          break;
        // 将本地变量存储如下一个字节代表的寄存器位置中
        case HTOpCode.register:
          break;
        case HTOpCode.assign:
        case HTOpCode.assignMultiply:
        case HTOpCode.assignDevide:
        case HTOpCode.assignAdd:
        case HTOpCode.assignSubtract:
        case HTOpCode.logicalOr:
        case HTOpCode.logicalAnd:
        case HTOpCode.equal:
        case HTOpCode.notEqual:
        case HTOpCode.lesser:
        case HTOpCode.greater:
        case HTOpCode.lesserOrEqual:
        case HTOpCode.greaterOrEqual:
        case HTOpCode.add:
        case HTOpCode.subtract:
        case HTOpCode.multiply:
        case HTOpCode.devide:
        case HTOpCode.modulo:
          _bytesReader.read();
          _bytesReader.read();
          break;
        case HTOpCode.negative:
        case HTOpCode.logicalNot:
        case HTOpCode.preIncrement:
        case HTOpCode.preDecrement:
          _bytesReader.read();
          break;
        case HTOpCode.memberGet:
        case HTOpCode.subGet:
        case HTOpCode.call:
        case HTOpCode.postIncrement:
        case HTOpCode.postDecrement:
          // _handleUnaryPostfixOp(instruction);
          break;
        case HTOpCode.debugInfo:
          _curLine = _bytesReader.readUint32();
          _curColumn = _bytesReader.readUint32();
          curFileName = _bytesReader.readShortUtf8String();
          break;
        default:
          break;
      }

      instruction = _bytesReader.read();
    }
  }
}
