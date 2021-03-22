import '../interpreter.dart';
import '../type.dart';
import '../common.dart';
import '../lexicon.dart';
import 'compiler.dart';
import 'opcode.dart';
import '../lexer.dart';
import '../errors.dart';
import '../plugin/importHandler.dart';
import '../namespace.dart';
import 'bytes_resolver.dart';
import '../plugin/errorHandler.dart';
import 'bytes_reader.dart';
import 'bytes_declaration.dart';
import 'bytes_funciton.dart';
import '../declaration.dart';
import '../function.dart';
import '../class.dart';
import '../extern_function.dart';

mixin VMRef {
  late final HTVM interpreter;
}

class HTVM extends Interpreter {
  late BytesReader _bytesReader;

  late final _codeStartIp;

  /// 符号表
  ///
  /// key代symbol的id
  ///
  /// value代表symbol所在的ip指针
  final _curNamespaceSymbols = <String, int>{};

  dynamic _curValue;
  String? _curSymbol;
  String? _curClassName;
  final _leftValueStack = <String>[];

  // final List<dynamic> _stack = [];
  final _register = List<dynamic>.filled(16, null, growable: false);

  HTVM({HTErrorHandler? errorHandler, HTImportHandler? importHandler})
      : super(errorHandler: errorHandler, importHandler: importHandler);

  @override
  Future<dynamic> eval(
    String content, {
    String? fileName,
    String libName = HTLexicon.global,
    HTNamespace? namespace,
    ParseStyle style = ParseStyle.module,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) async {
    curFileName = fileName ?? HTLexicon.anonymousScript;
    curNamespace = namespace ?? global;

    final tokens = Lexer().lex(content, curFileName);
    final bytes = await Compiler().compile(tokens, this, curFileName, style, debugMode);
    _bytesReader = BytesReader(bytes);
    print('Bytes length: ${_bytesReader.bytes.length}');
    print(_bytesReader.bytes);

    HTBytesResolver().resolve(_bytesReader.bytes, 10, curFileName);

    final result = execute();

    print(result);
  }

  @override
  Future<dynamic> import(
    String fileName, {
    String? directory,
    String? libName,
    ParseStyle style = ParseStyle.module,
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

  void _storeLocal() {
    final valueType = _bytesReader.read();
    switch (valueType) {
      case HTValueTypeCode.NULL:
        _curValue = null;
        break;
      case HTValueTypeCode.boolean:
        (_bytesReader.read() == 0) ? _curValue = false : _curValue = true;
        break;
      case HTValueTypeCode.int64:
        _curValue = curNamespace.getConstInt(_bytesReader.readUint16());
        break;
      case HTValueTypeCode.float64:
        _curValue = curNamespace.getConstFloat(_bytesReader.readUint16());
        break;
      case HTValueTypeCode.utf8String:
        _curValue = curNamespace.getConstString(_bytesReader.readUint16());
        break;
      case HTValueTypeCode.symbol:
        _curSymbol = _bytesReader.readShortUtf8String();
        _curValue = curNamespace.fetch(_curSymbol!);
        break;
      case HTValueTypeCode.group:
        _curValue = execute(ip: _bytesReader.ip, keepIp: true);
        break;
      case HTValueTypeCode.list:
        final list = [];
        final length = _bytesReader.readUint16();
        for (var i = 0; i < length; ++i) {
          list.add(execute(ip: _bytesReader.ip, keepIp: true));
        }
        _curValue = list;
        break;
      case HTValueTypeCode.map:
        final map = {};
        final length = _bytesReader.readUint16();
        for (var i = 0; i < length; ++i) {
          final key = execute(ip: _bytesReader.ip, keepIp: true);
          map[key] = execute(ip: _bytesReader.ip, keepIp: true);
        }
        _curValue = map;
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
    final err_type = _bytesReader.read();
    // TODO: line 和 column
    switch (err_type) {
    }
  }

  void _handleAssignOp(int opcode) {
    final right = _bytesReader.read();

    switch (opcode) {
      case HTOpCode.assign:
        _curValue = _register[right];
        curNamespace.assign(_leftValueStack.last, _curValue);
        _leftValueStack.removeLast();
        break;
      case HTOpCode.assignMultiply:
        final leftValue = curNamespace.fetch(_leftValueStack.last);
        _curValue = leftValue * _register[right];
        curNamespace.assign(_leftValueStack.last, _curValue);
        _leftValueStack.removeLast();
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
    }
  }

  void _handleBinaryOp(int opcode) {
    final left = _bytesReader.read();
    final right = _bytesReader.read();

    switch (opcode) {
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
    final value = _bytesReader.read();

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

  void _handleCallExpr(int regPos) {
    final callee = _register[regPos];
    var positionalArgs = [];
    final positionalArgsLength = _bytesReader.read();
    for (var i = 0; i < positionalArgsLength; ++i) {
      final arg = execute(ip: _bytesReader.ip, keepIp: true);
      positionalArgs.add(arg);
    }

    var namedArgs = <String, dynamic>{};
    final namedArgsLength = _bytesReader.read();
    for (var i = 0; i < namedArgsLength; ++i) {
      final name = _bytesReader.readShortUtf8String();
      final arg = execute(ip: _bytesReader.ip, keepIp: true);
      namedArgs[name] = arg;
    }

    if (callee is HTFunction) {
      if (!callee.isExtern) {
        // 普通函数
        if (callee.funcType != FunctionType.constructor) {
          _curValue = callee.call(positionalArgs: positionalArgs, namedArgs: namedArgs);
        } else {
          final className = callee.className;
          final klass = global.fetch(className!);
          if (klass is HTClass) {
            if (!klass.isExtern) {
              // 命名构造函数
              _curValue = klass.createInstance(
                  constructorName: callee.id, positionalArgs: positionalArgs, namedArgs: namedArgs);
            } else {
              // 外部命名构造函数
              final externClass = fetchExternalClass(className);
              final constructor = externClass.fetch(callee.id!);
              if (constructor is HTExternalFunction) {
                try {
                  _curValue = constructor(positionalArgs, namedArgs);
                } on RangeError {
                  throw HTErrorExternParams();
                }
              } else {
                _curValue = Function.apply(
                    constructor, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
                // throw HTErrorExternFunc(constructor.toString());
              }
            }
          } else {
            throw HTErrorCallable(callee.toString());
          }
        }
      } else {
        final externFunc = fetchExternalFunction(callee.id!);
        if (externFunc is HTExternalFunction) {
          try {
            _curValue = externFunc(positionalArgs, namedArgs);
          } on RangeError {
            throw HTErrorExternParams();
          }
        } else {
          _curValue =
              Function.apply(externFunc, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
          // throw HTErrorExternFunc(constructor.toString());
        }
      }
    } else if (callee is HTClass) {
      if (!callee.isExtern) {
        // 默认构造函数
        _curValue = callee.createInstance(positionalArgs: positionalArgs, namedArgs: namedArgs);
      } else {
        // 外部默认构造函数
        final externClass = fetchExternalClass(callee.id);
        final constructor = externClass.fetch(callee.id);
        if (constructor is HTExternalFunction) {
          try {
            _curValue = constructor(positionalArgs, namedArgs);
          } on RangeError {
            throw HTErrorExternParams();
          }
        } else {
          _curValue =
              Function.apply(constructor, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
          // throw HTErrorExternFunc(constructor.toString());
        }
      }
    } // 外部函数
    else if (callee is Function) {
      if (callee is HTExternalFunction) {
        try {
          _curValue = callee(positionalArgs, namedArgs);
        } on RangeError {
          throw HTErrorExternParams();
        }
      } else {
        _curValue = Function.apply(callee, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
        // throw HTErrorExternFunc(callee.toString());
      }
    } else {
      throw HTErrorCallable(callee.toString());
    }
  }

  void _handleUnaryPostfixOp(int op) {
    final value = _bytesReader.read();

    switch (op) {
      case HTOpCode.memberGet:
        // _local = _register[value] = -_register[value];
        break;
      case HTOpCode.subGet:
        // _local = _register[value] = !_register[value];
        break;
      case HTOpCode.call:
        _handleCallExpr(value);
        break;
      case HTOpCode.postIncrement:
        _curValue = _register[value];
        _register[value] += 1;
        break;
      case HTOpCode.postDecrement:
        _curValue = _register[value];
        _register[value] -= 1;
        break;
    }
  }

  List<HTBytesParamDecl> _handleParam(int paramDeclsLength) {
    final paramDecls = <HTBytesParamDecl>[];

    for (var i = 0; i < paramDeclsLength; ++i) {
      final id = _bytesReader.readShortUtf8String();
      final isOptional = _bytesReader.readBool();
      final isNamed = _bytesReader.readBool();
      final isVariadic = _bytesReader.readBool();

      int? initializerIp;
      final hasInitializer = _bytesReader.readBool();
      if (hasInitializer) {
        final length = _bytesReader.readUint16();
        initializerIp = _bytesReader.ip;
        _bytesReader.skip(length);
      }

      paramDecls.add(HTBytesParamDecl(id, this,
          initializerIp: initializerIp,
          typeInference: true,
          isOptional: isOptional,
          isNamed: isNamed,
          isVariadic: isVariadic));
    }

    return paramDecls;
  }

  void _handleFuncDecl() {
    final id = _bytesReader.readShortUtf8String();

    final funcType = FunctionType.values[_bytesReader.read()];
    final isExtern = _bytesReader.readBool();
    final isStatic = _bytesReader.readBool();
    final isConst = _bytesReader.readBool();
    final isVariadic = _bytesReader.readBool();

    final arity = _bytesReader.read();
    final paramDecls = _handleParam(_bytesReader.read());

    int? definitionIp;
    final hasDefinition = _bytesReader.readBool();
    if (hasDefinition) {
      final length = _bytesReader.readUint16();
      definitionIp = _bytesReader.ip;
      _bytesReader.skip(length);
    }

    final func = HTBytesFunction(
      this,
      id: id,
      className: _curClassName,
      funcType: funcType,
      paramDecls: paramDecls,
      definitionIp: definitionIp,
      isExtern: isExtern,
      isStatic: isStatic,
      isConst: isConst,
      isVariadic: isVariadic,
      arity: arity,
      context: curNamespace,
    );

    curNamespace.define(HTDeclaration(id, value: func, declType: func.typeid));
  }

  void _handleClassDecl() {}

  void _handleVarDecl() {
    final id = _bytesReader.readShortUtf8String();

    final typeInference = _bytesReader.readBool();
    final isExtern = _bytesReader.readBool();
    final isImmutable = _bytesReader.readBool();
    final isMember = _bytesReader.readBool();
    final isStatic = _bytesReader.readBool();

    int? initializerIp;
    final hasInitializer = _bytesReader.readBool();
    if (hasInitializer) {
      final length = _bytesReader.readUint16();
      initializerIp = _bytesReader.ip;
      _bytesReader.skip(length);
    }

    curNamespace.define(HTBytesDecl(id, this,
        initializerIp: initializerIp,
        typeInference: typeInference,
        isExtern: isExtern,
        isImmutable: isImmutable,
        isMember: isMember,
        isStatic: isStatic));
  }

  dynamic execute({int ip = 0, bool keepIp = false}) {
    final savedIp = _bytesReader.ip;
    _bytesReader.ip = ip;

    var instruction = _bytesReader.read();
    while (instruction != HTOpCode.endOfFile) {
      switch (instruction) {
        case HTOpCode.signature:
          _bytesReader.readUint32();
          break;
        case HTOpCode.version:
          final major = _bytesReader.read();
          final minor = _bytesReader.read();
          final patch = _bytesReader.readUint16();
          scriptVersion = HTVersion(major, minor, patch);
          print('Version: $scriptVersion');
          break;
        case HTOpCode.debug:
          debugMode = _bytesReader.read() == 0 ? false : true;
          print('Debug: $debugMode');
          break;
        //常量表
        case HTOpCode.constTable:
          final int64Length = _bytesReader.readUint16();
          for (var i = 0; i < int64Length; ++i) {
            curNamespace.addConstInt(_bytesReader.readInt64());
          }
          final float64Length = _bytesReader.readUint16();
          for (var i = 0; i < float64Length; ++i) {
            curNamespace.addConstFloat(_bytesReader.readFloat64());
          }
          final utf8StringLength = _bytesReader.readUint16();
          for (var i = 0; i < utf8StringLength; ++i) {
            curNamespace.addConstString(_bytesReader.readUtf8String());
          }
          break;
        // 变量表
        case HTOpCode.declTable:
          var funcDeclLength = _bytesReader.readUint16();
          for (var i = 0; i < funcDeclLength; ++i) {
            _handleFuncDecl();
          }
          var classDeclLength = _bytesReader.readUint16();
          for (var i = 0; i < classDeclLength; ++i) {
            _handleClassDecl();
          }
          var varDeclLength = _bytesReader.readUint16();
          for (var i = 0; i < varDeclLength; ++i) {
            _handleVarDecl();
          }
          break;
        // 将字面量存储在本地变量中
        case HTOpCode.local:
          _storeLocal();
          break;
        // 将本地变量存入下一个字节代表的寄存器位置中
        case HTOpCode.register:
          _storeRegister(_bytesReader.read(), _curValue);
          break;
        case HTOpCode.leftValue:
          _leftValueStack.add(_curSymbol!);
          break;
        case HTOpCode.assign:
        case HTOpCode.assignMultiply:
        case HTOpCode.assignDevide:
        case HTOpCode.assignAdd:
        case HTOpCode.assignSubtract:
          _handleAssignOp(instruction);
          break;
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
        case HTOpCode.endOfExec:
          if (!keepIp) {
            _bytesReader.ip = savedIp;
          }
          return _curValue;
        // 语句结束
        case HTOpCode.endOfStmt:
          _curSymbol = null;
          break;
        case HTOpCode.debugInfo:
          curLine = _bytesReader.readUint32();
          curColumn = _bytesReader.readUint32();
          curFileName = _bytesReader.readShortUtf8String();
          break;
        // 错误处理
        case HTOpCode.error:
          _handleError();
          break;
        default:
          print('Unknown opcode: $instruction');
          break;
      }

      instruction = _bytesReader.read();
    }
  }
}
