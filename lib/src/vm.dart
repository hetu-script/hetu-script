import 'dart:convert';
import 'dart:typed_data';

import 'common.dart';
import 'extern_class.dart';
import 'parser.dart';
import 'lexicon.dart';
import 'compiler.dart';
import 'opcode.dart';
import 'lexer.dart';
import 'expression.dart';
import 'resolver.dart';
import 'errors.dart';

class HT_VM implements CodeRunner {
  static var _fileIndex = 0;

  final bool debugMode;
  final ReadFileMethod readFileMethod;

  late String _curFileName;
  // late List<int> _curFileVersion;
  late String _curDirectory;
  @override
  String? get curFileName => _curFileName;
  @override
  String? get curDirectory => _curDirectory;

  // final _evaledFiles = <String>[];
  late final Map<Expr, int> _distances;

  late Uint8List _bytes;
  int _ip = 0; // instruction pointer

  var _context = HT_Context();

  var _local;
  final _register = List<dynamic>.filled(16, null, growable: true);

  HT_VM({
    String sdkDirectory = 'hetu_lib/',
    String currentDirectory = 'script/',
    this.debugMode = false,
    this.readFileMethod = defaultReadFileMethod,
    Map<String, Function> externalFunctions = const {},
  });

  @override
  void bindExternalNamespace(String id, HT_ExternNamespace namespace) {}
  @override
  HT_ExternNamespace fetchExternalClass(String id) => throw 'error';
  @override
  void bindExternalFunction(String id, Function function) {}
  @override
  Function fetchExternalFunction(String id) => throw 'error';

  @override
  void bindExternalVariable(String id, Function getter, Function setter) {}
  @override
  dynamic getExternalVariable(String id) {}
  @override
  void setExternalVariable(String id, value) {}

  @override
  dynamic eval(
    String content, {
    String? fileName,
    String libName = HT_Lexicon.global,
    HT_Context? context,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) {
    if (context != null) {
      _context = context;
    }
    _curFileName = fileName ?? '__anonymousScript' + (_fileIndex++).toString();

    if (debugMode) {
      final tokens = Lexer().lex(content);
      final statements = Parser(this).parse(tokens, _context, _curFileName, style);
      _distances = Resolver(this).resolve(statements, _curFileName, libName: libName);
      _bytes = Compiler().compileAST(statements, _context, _curFileName);
    } else {
      final tokens = Lexer().lex(content);
      _bytes = Compiler().compileTokens(tokens);
    }

    run(10);
  }

  dynamic run(int ip) {
    _ip = ip;
    // final signature = _bytes.sublist(0, 4);
    // if (signature.buffer.asByteData().getUint32(0) != Compiler.hetuSignature) {
    //   throw HTErr_Signature(_curFileName);
    // }

    // final mainVersion = _bytes[4];
    // final minorVersion = _bytes[5];
    // final pathVersion = _bytes.buffer.asByteData().getUint32(6);
    // _curFileVersion = [mainVersion, minorVersion, pathVersion];
    // print('Executable bytecode file version: $_curFileVersion');

    // 直接从第10个字节开始，跳过程序标记和版本号

    while (_ip < _bytes.length) {
      final instruction = readByte();
      switch (instruction) {
        case HT_OpCode.end:
          return;
        case HT_OpCode.constTable:
          _context = HT_Context();
          var table_length = readInt64();
          for (var i = 0; i < table_length; ++i) {
            _context.addConstInt(readInt64());
          }
          table_length = readInt64();
          for (var i = 0; i < table_length; ++i) {
            _context.addConstFloat(readFloat64());
          }
          table_length = readInt64();
          for (var i = 0; i < table_length; ++i) {
            _context.addConstString(readUtf8String());
          }
          break;
        case HT_OpCode.local:
          setLocal();
          break;
        case HT_OpCode.add:
          _local = _register[1] + _register[2];
          break;
        case HT_OpCode.reg0:
          _register[0] = _local;
          break;
        case HT_OpCode.reg1:
          _register[1] = _local;
          break;
        case HT_OpCode.error:
          handleError();
          break;
        default:
          print('Unknown operator. $instruction');
          break;
      }
    }
  }

  @override
  dynamic evalf(
    String fileName, {
    String? directory,
    String? libName,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) async {}

  @override
  dynamic evalfSync(
    String fileName, {
    String? directory,
    String? libName,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) {}

  @override
  dynamic invoke(String functionName,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}}) {}

  int peekByte(int distance) {
    return _bytes[_ip + distance];
  }

  int readByte() {
    return _bytes[_ip++];
  }

  bool readBool() {
    var boolean = _bytes.last == 0 ? false : true;
    ++_ip;
    return boolean;
  }

  // Fetch a int64 from the byte list
  int readInt64() {
    final start = _ip;
    _ip += 8;
    final int64data = _bytes.sublist(start, _ip);
    return int64data.buffer.asByteData().getInt64(0);
  }

  // Fetch a float64 from the byte list
  double readFloat64() {
    final start = _ip;
    _ip += 8;
    final int64data = _bytes.sublist(start, _ip);
    return int64data.buffer.asByteData().getFloat64(0);
  }

  // Fetch a utf8 string from the byte list
  String readUtf8String() {
    final length = readInt64();
    final start = _ip;
    _ip += length;
    final codeUnits = _bytes.sublist(start, _ip);
    return utf8.decoder.convert(codeUnits);
  }

  void setLocal() {
    final oprand_type = readByte();
    switch (oprand_type) {
      case HT_OpRandType.constInt64:
        _local = _context.getConstInt(readInt64());
        break;
      case HT_OpRandType.constFloat64:
        _local = _context.getConstInt(readInt64());
        break;
      case HT_OpRandType.constUtf8String:
        _local = _context.getConstInt(readInt64());
        break;
    }
  }

  void handleError() {
    final err_type = readByte();
    // TODO: line 和 column
    switch (err_type) {
      case HT_ErrorCode.binOp:
        throw HTErr_UndefinedBinaryOperator(
            _register[0].toString(), _register[1].toString(), HT_Lexicon.add, curFileName);
    }
  }
}
