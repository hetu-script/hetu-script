import '../../grammar/semantic.dart';
import '../../type_system/type.dart';
import '../../type_system/function_type.dart';
import '../namespace/namespace.dart';
import '../declaration.dart';
import '../object.dart';
import '../abstract_interpreter.dart';
import '../class/class.dart';

/// [HTFunction] is the base class of
/// [HTAstFunction] and [HTBytecodeFunction] in Hetu.
abstract class HTFunction extends HTDeclaration with HTObject, InterpreterRef {
  static final callStack = <String>[];

  final String declId;
  final HTClass? klass;

  final FunctionCategory category;

  final bool isExternal;

  Function? externalFuncDef;

  final String? externalTypedef;

  @override
  late final HTFunctionType declType;

  HTType get returnType => declType.returnType;

  @override
  HTType get valueType => declType;
  // HTType get valueType => HTType.function;

  final bool isStatic;

  final bool isConst;

  final bool isVariadic;

  bool get isMethod => classId != null;

  final int minArity;
  final int maxArity;

  HTNamespace? context;

  HTFunction(String id, this.declId, HTInterpreter interpreter,
      {this.klass,
      this.category = FunctionCategory.normal,
      this.isExternal = false,
      this.externalFuncDef,
      this.externalTypedef,
      this.isStatic = false,
      this.isConst = false,
      this.isVariadic = false,
      this.minArity = 0,
      this.maxArity = 0,
      HTNamespace? context})
      : super(id, klass?.id) {
    this.interpreter = interpreter;
    this.context = context;
  }

  /// Sub-classes of [HTFunction] must define [toString] method.
  @override
  String toString();

  @override
  dynamic get value {
    if (externalTypedef != null) {
      final externalFunc =
          interpreter.unwrapExternalFunctionType(externalTypedef!, this);
      return externalFunc;
    } else if (category == FunctionCategory.getter) {
      return call();
    } else {
      return this;
    }
  }

  /// Sub-classes of [HTFunction] must define [call] method.
  dynamic call(
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool createInstance = true,
      bool errorHandled = true});

  /// Sub-classes of [HTFunction] must define [clone] method.
  @override
  HTFunction clone();
}
