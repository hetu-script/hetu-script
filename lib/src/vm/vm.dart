import 'dart:convert';
import 'dart:typed_data';

import '../interpreter.dart';
import '../type.dart';
import '../parser.dart' show ParseStyle;
import '../lexicon.dart';
import 'compiler.dart';
import 'opcode.dart';
import '../lexer.dart';
import '../errors.dart';
import '../read_file.dart';
import '../namespace.dart';
import 'bytes_resolver.dart';

mixin VMRef {
  late final HTVM interpreter;
}

class HTVM extends Interpreter {
  // final _evaledFiles = <String>[];

  late Uint8List _bytes;
  int _ip = 0; // instruction pointer

  /// 符号表，不同语句块和环境的符号可能会有重名。
  /// key代表ip指针，value代表符号代表的值所在的命名空间上层深度
  final _distances = <int, int>{};

  dynamic _curValue;
  late String _curSymbol;

  // final List<dynamic> _stack = [];
  final _register = List<dynamic>.filled(255, null, growable: false);

  HTVM(
      {String sdkDirectory = 'hetu_lib/',
      String workingDirectory = 'script/',
      bool debugMode = false,
      ReadFileMethod readFileMethod = defaultReadFileMethod}) {
    curNamespace = globals = HTNamespace(this, id: HTLexicon.global);
    this.workingDirectory = workingDirectory;
    this.debugMode = debugMode;
    this.readFileMethod = readFileMethod;
  }

  @override
  Future<dynamic> eval(
    String content, {
    String? fileName,
    String libName = HTLexicon.global,
    HTNamespace? namespace,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) async {
    curFileName = fileName ?? HTLexicon.anonymousScript;
    curNamespace = namespace ?? globals;

    final tokens = Lexer().lex(content, curFileName);
    _bytes = await Compiler().compile(tokens, this, curNamespace, curFileName, style, debugMode);
    print(_bytes);

    HTBytesResolver().resolve(_bytes, 10, curFileName);

    final result = _execute(10);

    print(result);
  }

  @override
  Future<dynamic> import(
    String fileName, {
    String? directory,
    String? libName,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) async {}

  @override
  dynamic invoke(String functionName,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}}) {}

  @override
  HTTypeId typeof(dynamic object) {
    return HTTypeId.ANY;
  }

  dynamic resolveSymbol(String id) {}

  int _peekByte(int distance) {
    final des = _ip + distance;
    if (des >= 0 && des < _bytes.length) {
      return _bytes[des];
    } else {
      return -1;
    }
  }

  int _readByte() {
    return _bytes[_ip++];
  }

  bool _readBool() {
    return _bytes[_ip++] == 0 ? false : true;
  }

  // Fetch a uint8 from the byte list
  int _readUint8() {
    final start = _ip;
    _ip += 1;
    final uint16data = _bytes.sublist(start, _ip);
    return uint16data.buffer.asByteData().getUint8(0);
  }

  // Fetch a uint16 from the byte list
  int _readUint16() {
    final start = _ip;
    _ip += 2;
    final uint16data = _bytes.sublist(start, _ip);
    return uint16data.buffer.asByteData().getUint16(0);
  }

  // Fetch a uint32 from the byte list
  int _readUint32() {
    final start = _ip;
    _ip += 4;
    final uint32data = _bytes.sublist(start, _ip);
    return uint32data.buffer.asByteData().getUint32(0);
  }

  // Fetch a int64 from the byte list
  int _readInt64() {
    final start = _ip;
    _ip += 8;
    final int64data = _bytes.sublist(start, _ip);
    return int64data.buffer.asByteData().getInt64(0);
  }

  // Fetch a float64 from the byte list
  double _readFloat64() {
    final start = _ip;
    _ip += 8;
    final int64data = _bytes.sublist(start, _ip);
    return int64data.buffer.asByteData().getFloat64(0);
  }

  // Fetch a utf8 string from the byte list
  String _readShortUtf8String() {
    final length = _readUint8();
    final start = _ip;
    _ip += length;
    final codeUnits = _bytes.sublist(start, _ip);
    return utf8.decoder.convert(codeUnits);
  }

  // Fetch a utf8 string from the byte list
  String _readUtf8String() {
    final length = _readUint16();
    final start = _ip;
    _ip += length;
    final codeUnits = _bytes.sublist(start, _ip);
    return utf8.decoder.convert(codeUnits);
  }

  void _storeLocalLiteral() {
    final oprandType = _readByte();
    switch (oprandType) {
      case HTOpRandType.nil:
        _curValue = null;
        break;
      case HTOpRandType.boolean:
        (_readByte() == 0) ? _curValue = false : _curValue = true;
        break;
      case HTOpRandType.int64:
        _curValue = curNamespace.getConstInt(_readUint16());
        break;
      case HTOpRandType.float64:
        _curValue = curNamespace.getConstFloat(_readUint16());
        break;
      case HTOpRandType.utf8String:
        _curValue = curNamespace.getConstString(_readUint16());
        break;
      case HTOpRandType.symbol:
      // _curValue = curNamespace.fetch(varName)
    }
  }

  void _storeLocalSymbol() {
    _curSymbol = _readShortUtf8String();
  }

  void _storeRegister(int index, dynamic value) {
    // if (index > _register.length) {
    //   _register.length = index + 8;
    // }

    _register[index] = value;
  }

  void _handleError() {
    final err_type = _readByte();
    // TODO: line 和 column
    switch (err_type) {
    }
  }

  void _handleBinaryOp(int opcode) {
    final left = _readByte();
    final right = _readByte();

    switch (opcode) {
      case HTOpCode.assign:
        // _local = _register[left] = _register[right];
        break;
      case HTOpCode.assignMultiply:
        // _local = _register[left] *= _register[right];
        break;
      case HTOpCode.assignDevide:
        // _local = _register[left] /= _register[right];
        break;
      case HTOpCode.assignAdd:
        // _local = _register[left] += _register[right];
        break;
      case HTOpCode.assignSubtract:
        // _local = _register[left] -= _register[right];
        break;
      case HTOpCode.logicalOr:
        _curValue = _register[left] = _register[left] || _register[right];
        break;
      case HTOpCode.logicalAnd:
        _curValue = _register[left] = _register[left] && _register[right];
        break;
      case HTOpCode.equal:
        _curValue = _register[left] = _register[left] == _register[right];
        break;
      case HTOpCode.notEqual:
        _curValue = _register[left] = _register[left] != _register[right];
        break;
      case HTOpCode.lesser:
        _curValue = _register[left] = _register[left] < _register[right];
        break;
      case HTOpCode.greater:
        _curValue = _register[left] = _register[left] > _register[right];
        break;
      case HTOpCode.lesserOrEqual:
        _curValue = _register[left] = _register[left] <= _register[right];
        break;
      case HTOpCode.greaterOrEqual:
        _curValue = _register[left] = _register[left] >= _register[right];
        break;
      case HTOpCode.add:
        _curValue = _register[left] = _register[left] + _register[right];
        break;
      case HTOpCode.subtract:
        _curValue = _register[left] = _register[left] - _register[right];
        break;
      case HTOpCode.multiply:
        _curValue = _register[left] = _register[left] * _register[right];
        break;
      case HTOpCode.devide:
        _curValue = _register[left] = _register[left] / _register[right];
        break;
      case HTOpCode.modulo:
        _curValue = _register[left] = _register[left] % _register[right];
        break;
      default:
      // throw HTErrorUndefinedBinaryOperator(_register[left].toString(), _register[right].toString(), opcode);
    }
  }

  void _handleUnaryPrefixOp(int op) {
    final value = _readByte();

    switch (op) {
      case HTOpCode.negative:
        _curValue = _register[value] = -_register[value];
        break;
      case HTOpCode.logicalNot:
        _curValue = _register[value] = !_register[value];
        break;
      case HTOpCode.preIncrement:
        _curValue = _register[value] = ++_register[value];
        break;
      case HTOpCode.preDecrement:
        _curValue = _register[value] = --_register[value];
        break;
      default:
      // throw HTErrorUndefinedOperator(_register[left].toString(), _register[right].toString(), HTLexicon.add);
    }
  }

  void _handleUnaryPostfixOp(int op) {
    final value = _readByte();

    switch (op) {
      case HTOpCode.memberGet:
        // _local = _register[value] = -_register[value];
        break;
      case HTOpCode.subGet:
        // _local = _register[value] = !_register[value];
        break;
      case HTOpCode.call:
        // _local = _register[value] = !_register[value];
        break;
      case HTOpCode.postIncrement:
        _curValue = _register[value];
        _register[value] += 1;
        break;
      case HTOpCode.postDecrement:
        _curValue = _register[value];
        _register[value] -= 1;
        break;
      default:
      // throw HTErrorUndefinedOperator(_register[left].toString(), _register[right].toString(), HTLexicon.add);
    }
  }

  dynamic _execute(int ip) {
    final savedIp = _ip;

    _ip = ip;
    // final signature = _bytes.sublist(0, 4);
    // if (signature.buffer.asByteData().getUint32(0) != Compiler.hetuSignature) {
    //   throw HTErrorSignature(curFileName);
    // }

    // final mainVersion = _bytes[4];
    // final minorVersion = _bytes[5];
    // final pathVersion = _bytes.buffer.asByteData().getUint32(6);
    // _curFileVersion = [mainVersion, minorVersion, pathVersion];
    // print('Executable bytecode file version: $_curFileVersion');

    // 直接从第10个字节开始，跳过程序标记和版本号

    while (_ip < _bytes.length) {
      final instruction = _readByte();
      switch (instruction) {
        // 返回当前运算值
        case HTOpCode.subReturn:
          _ip = savedIp;
          return _curValue;
        // 语句结束
        case HTOpCode.endOfStatement:
          break;
        // 从字节码读取常量表并保存在当前环境中
        case HTOpCode.constTable:
          var table_length = _readUint16();
          for (var i = 0; i < table_length; ++i) {
            curNamespace.addConstInt(_readInt64());
          }
          table_length = _readUint16();
          for (var i = 0; i < table_length; ++i) {
            curNamespace.addConstFloat(_readFloat64());
          }
          table_length = _readUint16();
          for (var i = 0; i < table_length; ++i) {
            curNamespace.addConstString(_readUtf8String());
          }
          break;
        // 将字面量存储在本地变量中
        case HTOpCode.literal:
          _storeLocalLiteral();
          break;
        // 当前符号（变量名）
        case HTOpCode.symbol:
          _storeLocalSymbol();
          break;
        // 将本地变量存储如下一个字节代表的寄存器位置中
        case HTOpCode.register:
          _storeRegister(_readByte(), _curValue);
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
          _handleBinaryOp(instruction);
          break;
        case HTOpCode.negative:
        case HTOpCode.logicalNot:
        case HTOpCode.preIncrement:
        case HTOpCode.preDecrement:
          _handleUnaryPrefixOp(instruction);
          break;
        case HTOpCode.memberGet:
        case HTOpCode.subGet:
        case HTOpCode.call:
        case HTOpCode.postIncrement:
        case HTOpCode.postDecrement:
          _handleUnaryPostfixOp(instruction);
          break;
        case HTOpCode.debugInfo:
          curLine = _readUint32();
          curLine = _readUint32();
          curFileName = _readShortUtf8String();
          break;
        // 错误处理
        case HTOpCode.error:
          _handleError();
          break;
        default:
          print('Unknown opcode: $instruction');
          break;
      }
    }
  }
}
