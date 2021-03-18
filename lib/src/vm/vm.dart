import 'dart:convert';
import 'dart:typed_data';

import '../interpreter.dart';
import '../ast_interpreter/type.dart';
import '../parser.dart' show ParseStyle;
import '../lexicon.dart';
import 'compiler.dart';
import 'opcode.dart';
import '../lexer.dart';
import '../ast_interpreter/expression.dart';
import '../errors.dart';
import '../read_file.dart';
import '../context.dart';

class HTVM extends Interpreter {
  static var _fileIndex = 0;

  @override
  int curLine = 0;
  @override
  int curColumn = 0;
  @override
  String curFileName = '';

  @override
  final String workingDirectory;

  final bool debugMode;
  final ReadFileMethod readFileMethod;

  // final _evaledFiles = <String>[];
  late final Map<ASTNode, int> _distances;

  late Uint8List _bytes;
  int _ip = 0; // instruction pointer

  late final HTContext _context;

  var _local;
  dynamic _curStmtValue;

  final _register = List<dynamic>.filled(16, null, growable: true);

  HTVM({
    String sdkDirectory = 'hetu_lib/',
    this.workingDirectory = 'script/',
    this.debugMode = false,
    this.readFileMethod = defaultReadFileMethod,
    Map<String, Function> externalFunctions = const {},
  });

  @override
  Future<dynamic> eval(
    String content, {
    String? fileName,
    String libName = HTLexicon.global,
    HTContext? context, // ingored
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) async {
    curFileName = fileName ?? '__anonymousScript' + (_fileIndex++).toString();

    final tokens = Lexer().lex(content, curFileName);
    _bytes = await Compiler().compile(tokens, this, curFileName, false);
    print(_bytes);

    _run(10);
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

  int peekByte(int distance) {
    return _bytes[_ip + distance];
  }

  int _readByte() {
    return _bytes[_ip++];
  }

  bool readBool() {
    var boolean = _bytes.last == 0 ? false : true;
    ++_ip;
    return boolean;
  }

  // Fetch a uint16 from the byte list
  int _readUint16() {
    final start = _ip;
    _ip += 2;
    final uint16data = _bytes.sublist(start, _ip);
    return uint16data.buffer.asByteData().getUint16(0);
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

  void _setLocal() {
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

  dynamic _run(int ip) {
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
        case HTOpCode.endOfFile:
          print(_curStmtValue);
          return;
        case HTOpCode.endOfLine:
          _curStmtValue = _local;
          break;
        case HTOpCode.constTable:
          _context = HTContext();
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
        case HTOpCode.literal:
          _setLocal();
          break;
        case HTOpCode.reg0:
          _register[0] = _local;
          break;
        case HTOpCode.reg1:
          _register[1] = _local;
          break;
        case HTOpCode.add:
          _local = _register[0] + _register[1];
          break;
        case HTOpCode.subtract:
          _local = _register[0] - _register[1];
          break;
        case HTOpCode.error:
          _handleError();
          break;
        default:
          print('Unknown operator. $instruction');
          break;
      }
    }
  }

  void _handleError() {
    final err_type = _readByte();
    // TODO: line 和 column
    switch (err_type) {
      case HTErrorCode.binOp:
        throw HTErrorUndefinedBinaryOperator(_register[0].toString(), _register[1].toString(), HTLexicon.add);
    }
  }
}
