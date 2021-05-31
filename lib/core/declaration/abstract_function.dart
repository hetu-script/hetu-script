import '../../grammar/semantic.dart';
import '../../type_system/type.dart';
import '../../type_system/function_type.dart';
import '../namespace/namespace.dart';
import '../object.dart';
import '../abstract_interpreter.dart';

/// [AbstractFunction] is the base class of
/// [HTAstFunction] and [HTBytecodeFunction] in Hetu.
abstract class AbstractFunction with HTObject {
  static final callStack = <String>[];

  final String id;
  // final String? classId;

  final String? declId;

  final String? classId;

  final FunctionCategory category;

  final bool isExternal;

  Function? externalFunc;

  final String? externalId;

  HTType get returnType => valueType.returnType;

  @override
  late final HTFunctionType valueType;
  // HTType get valueType => HTType.function;

  final bool isStatic;

  final bool isConst;

  final bool isVariadic;

  final int minArity;
  final int maxArity;

  HTNamespace? context;

  AbstractFunction(this.id, HTInterpreter interpreter,
      {this.declId,
      this.classId,
      this.category = FunctionCategory.normal,
      this.isExternal = false,
      this.externalFunc,
      this.externalId,
      this.isStatic = false,
      this.isConst = false,
      this.isVariadic = false,
      this.minArity = 0,
      this.maxArity = 0,
      this.context});

  /// Sub-classes of [AbstractFunction] must define [toString] method.
  @override
  String toString();

  /// Sub-classes of [AbstractFunction] must define [call] method.
  dynamic call(
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool createInstance = true,
      bool errorHandled = true});
}
