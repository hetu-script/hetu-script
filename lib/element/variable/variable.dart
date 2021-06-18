import '../../error/error.dart';
import '../../interpreter/interpreter.dart';
import '../../interpreter/compiler.dart' show GotoInfo;
import '../class/class.dart';
import '../namespace.dart';
import '../element.dart';

class HTVariable extends HTElement with HetuRef, GotoInfo {
  // 为了允许保存宿主程序变量，这里是dynamic，而不是HTObject
  dynamic _value;

  final HTNamespace? closure;

  var _isInitializing = false;

  var _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // var _isTypeInitialized = false;

  /// Create a standard [HTVariable].
  /// has to be defined in a [HTNamespace] of an [Interpreter]
  /// before it can be acessed within a script.
  HTVariable(
      String id, String moduleFullName, String libraryName, Hetu interpreter,
      {String? classId,
      dynamic value,
      bool isExternal = false,
      bool isStatic = false,
      bool isMutable = false,
      bool isConst = false,
      int? definitionIp,
      int? definitionLine,
      int? definitionColumn,
      this.closure})
      : super(id, moduleFullName, libraryName,
            classId: classId,
            isExternal: isExternal,
            isStatic: isStatic,
            isMutable: isMutable,
            isConst: isConst) {
    this.interpreter = interpreter;
    this.definitionIp = definitionIp;
    this.definitionLine = definitionLine;
    this.definitionColumn = definitionColumn;

    if (value != null) {
      this.value = value;
      _isInitialized = true;
    }

    // if (declType != null) {
    //   _declType = declType;

    //   if (_declType is HTFunctionDeclarationType ||
    //       _declType is HTObjectType ||
    //       (HTLexicon.primitiveType.contains(declType.id))) {
    //     _isTypeInitialized = true;
    //   }
    // } else {
    //   if (!typeInferrence || (definitionIp == null)) {
    //     _declType = HTType.ANY;
    //     _isTypeInitialized = true;
    //   }
    // }
  }

  /// initialize the declared type if it's a class name.
  /// only return the [HTClass] when its a non-external class
  // void _initializeType() {
  //   final resolvedType = HTType.resolve(_declType!, interpreter);
  //   _declType = resolvedType.type;
  //   _declClass = resolvedType.klass;
  //   _isTypeInitialized = true;
  // }

  /// Initialize this variable with its declared initializer bytecode
  void initialize() {
    if (isInitialized) return;

    if (definitionIp != null) {
      if (!_isInitializing) {
        _isInitializing = true;
        final initVal = interpreter.execute(
            moduleFullName: moduleFullName,
            libraryName: libraryName,
            ip: definitionIp!,
            namespace: closure,
            line: definitionLine,
            column: definitionColumn);

        value = initVal;

        _isInitializing = false;
      } else {
        throw HTError.circleInit(id);
      }
    } else {
      value = null; // null 也要 assign 一下，因为需要类型检查
    }
  }

  /// Assign a new value to this variable.
  @override
  set value(dynamic value) {
    _value = value;
    _isInitialized = true;
  }

  @override
  dynamic get value {
    if (!isExternal) {
      if (!isInitialized) {
        initialize();
      }
      return _value;
    } else {
      final externClass = interpreter.fetchExternalClass(classId!);
      return externClass.memberGet(id);
    }
  }

  @override
  HTVariable clone() => HTVariable(id, moduleFullName, libraryName, interpreter,
      classId: classId,
      value: value,
      definitionIp: definitionIp,
      definitionLine: definitionLine,
      definitionColumn: definitionColumn,
      isExternal: isExternal);
}
