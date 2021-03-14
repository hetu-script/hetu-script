import 'dart:convert';
import 'dart:typed_data';

import 'common.dart';
import 'extern_class.dart';
import 'parser.dart';
import 'lexicon.dart';
import 'compiler.dart';
import 'operator.dart';
import 'lexer.dart';
import 'errors.dart';

enum Instruction {
  opReturn,
}

class HT_VM with HT_ExternalBinding implements CodeRunner {
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

  /// 常量表
  final _int64Table = <int>[];
  final _float64Table = <double>[];
  final _stringTable = <String>[];

  late Uint8List _bytes;
  int _ip = 0; // instruction pointer

  HT_VM(
      {String sdkDirectory = 'hetu_lib/',
      String currentDirectory = 'script/',
      this.debugMode = false,
      this.readFileMethod = defaultReadFileMethod,
      Map<String, Function> externalFunctions = const {}});

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
    _curFileName = fileName ?? '__anonymousScript' + (Lexer.fileIndex++).toString();

    _bytes = Compiler().compile('');

    print(_bytes);

    _int64Table.clear();
    _float64Table.clear();
    _stringTable.clear();

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
    _ip = 10;
    if (readByte() != HT_Operator.constInt64Table) {
      throw HTErr_Int64Table(_curFileName);
    } else {
      final table_length = readInt64();
      for (var i = 0; i < table_length; ++i) {
        _int64Table.add(readInt64());
      }
      print(_int64Table);
    }
    if (readByte() != HT_Operator.constFloat64Table) {
      throw HTErr_Float64Table(_curFileName);
    } else {
      final table_length = readInt64();
      for (var i = 0; i < table_length; ++i) {
        _float64Table.add(readFloat64());
      }
      print(_float64Table);
    }
    if (readByte() != HT_Operator.constUtf8StringTable) {
      throw HTErr_StringTable(_curFileName);
    } else {
      final table_length = readInt64();
      for (var i = 0; i < table_length; ++i) {
        _stringTable.add(readUtf8String());
      }
      print(_stringTable);
    }

    for (; _ip < _bytes.length;) {
      final instruction = readByte();
      switch (instruction) {
        case HT_Operator.endOfFile:
          print('Evaluation returned.\nSuccesfully run.');
          return;
        // case HT_Operator.constant:
        //   final index = readInt64();
        //   print('Constant: ${_chunk.constants[index]}');
        //   break;
        default:
          print('Unknown operator. $instruction');
          break;
      }
    }
  }

  @override
  dynamic invoke(String functionName,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}}) {}

  int readByte() {
    return _bytes[_ip++];
  }

  bool readBool() {
    var boolean = _bytes.last == 0 ? false : true;
    ++_ip;
    return boolean;
  }

  int readInt64() {
    final start = _ip;
    _ip += 8;
    final int64data = _bytes.sublist(start, _ip);
    return int64data.buffer.asByteData().getInt64(0);
  }

  double readFloat64() {
    final start = _ip;
    _ip += 8;
    final int64data = _bytes.sublist(start, _ip);
    return int64data.buffer.asByteData().getFloat64(0);
  }

  String readUtf8String() {
    final length = readInt64();
    final start = _ip;
    _ip += length;
    final codeUnits = _bytes.sublist(start, _ip);
    return utf8.decoder.convert(codeUnits);
  }
}
