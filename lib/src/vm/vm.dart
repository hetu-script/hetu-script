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

mixin VMRef {
  late final HTVM interpreter;
}

class HTVM extends Interpreter {
  static var _fileIndex = 0;

  // final _evaledFiles = <String>[];

  late Uint8List _bytes;
  int _ip = 0; // instruction pointer

  late final HTNamespace _context;

  dynamic _local;

  // final List<dynamic> _stack = [];
  final _register = List<dynamic>.filled(255, null, growable: false);

  HTVM(
      {String sdkDirectory = 'hetu_lib/',
      String workingDirectory = 'script/',
      bool debugMode = false,
      ReadFileMethod readFileMethod = defaultReadFileMethod}) {
    context = globals = HTNamespace(this, id: HTLexicon.global);
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
    curFileName = fileName ?? '__anonymousScript' + (_fileIndex++).toString();
    context = namespace is HTNamespace ? namespace : globals;

    final tokens = Lexer().lex(content, curFileName);
    _bytes = await Compiler().compile(tokens, this, context, curFileName, style, debugMode);
    print(_bytes);

    final result = _exec(10);

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

  // Fetch a uint16 from the byte list
  int _readUint16() {
    final start = _ip;
    _ip += 2;
    final uint16data = _bytes.sublist(start, _ip);
    return uint16data.buffer.asByteData().getUint16(0);
  }

  // Fetch a uint32 from the byte list
  int _readInt32() {
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
  String _readUtf8String() {
    final length = _readInt64();
    final start = _ip;
    _ip += length;
    final codeUnits = _bytes.sublist(start, _ip);
    return utf8.decoder.convert(codeUnits);
  }

  void _storeLocal() {
    final oprandType = _readByte();
    switch (oprandType) {
      case HTOpRandType.nil:
        _local = null;
        break;
      case HTOpRandType.boolean:
        (_readByte() == 0) ? _local = false : _local = true;
        break;
      case HTOpRandType.int64:
        _local = _context.getConstInt(_readUint16());
        break;
      case HTOpRandType.float64:
        _local = _context.getConstFloat(_readUint16());
        break;
      case HTOpRandType.utf8String:
        _local = _context.getConstString(_readUint16());
        break;
    }
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

  void _execBinaryOp(int op) {
    final left = _readByte();
    final right = _readByte();
    final store = _readByte();

    switch (op) {
      case HTOpCode.add:
        _local = _register[store] = _register[left] + _register[right];
        break;
      case HTOpCode.subtract:
        _local = _register[store] = _register[left] - _register[right];
        break;
      case HTOpCode.multiply:
        _local = _register[store] = _register[left] * _register[right];
        break;
      case HTOpCode.devide:
        _local = _register[store] = _register[left] / _register[right];
        break;
      case HTOpCode.modulo:
        _local = _register[store] = _register[left] % _register[right];
        break;
      default:
        throw HTErrorUndefinedBinaryOperator(_register[left].toString(), _register[right].toString(), HTLexicon.add);
    }
  }

  dynamic _exec(int ip) {
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
          return _local;
        // 语句结束
        case HTOpCode.endOfStatement:
          break;
        // 从字节码读取常量表并保存在当前环境中
        case HTOpCode.constTable:
          var table_length = _readUint16();
          for (var i = 0; i < table_length; ++i) {
            _context.addConstInt(_readInt64());
          }
          table_length = _readUint16();
          for (var i = 0; i < table_length; ++i) {
            _context.addConstFloat(_readFloat64());
          }
          table_length = _readUint16();
          for (var i = 0; i < table_length; ++i) {
            _context.addConstString(_readUtf8String());
          }
          break;
        // 将字面量存储在本地变量中
        case HTOpCode.literal:
          _storeLocal();
          break;
        // 将本地变量存储如下一个字节代表的寄存器位置中
        case HTOpCode.register:
          _storeRegister(_readByte(), _local);
          break;
        case HTOpCode.add:
        case HTOpCode.subtract:
        case HTOpCode.multiply:
        case HTOpCode.devide:
        case HTOpCode.modulo:
          _execBinaryOp(instruction);
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
