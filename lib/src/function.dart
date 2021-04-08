import 'common.dart';
import 'namespace.dart';
import 'type.dart';
import 'declaration.dart';
import 'object.dart';
import 'class.dart';

/// [HTFunction] is the base class of
/// [HTAstFunction] and [HTBytecodeFunction] in Hetu.
abstract class HTFunction with HTDeclaration, HTObject {
  static final callStack = <String>[];

  final String declId;
  final String moduleUniqueKey;
  final HTClass? klass;

  final FunctionType funcType;

  final bool isExtern;

  final String? externalTypedef;

  @override
  late final HTFunctionType rtType;

  HTType get returnType => rtType.returnType;

  final List<HTType> typeArgs; // function<T1, T2>

  final bool isStatic;

  final bool isConst;

  final bool isVariadic;

  bool get isMethod => classId != null;

  final int minArity;
  final int maxArity;

  HTNamespace? context;

  HTFunction(String id, this.declId, this.moduleUniqueKey,
      {this.klass,
      this.funcType = FunctionType.normal,
      this.isExtern = false,
      this.externalTypedef,
      this.typeArgs = const [],
      this.isStatic = false,
      this.isConst = false,
      this.isVariadic = false,
      this.minArity = 0,
      this.maxArity = 0,
      HTNamespace? context}) {
    this.id = id;
    classId = klass?.id;
    this.context = context;
  }

  /// Sub-classes of [HTFunction] must define [toString] method.
  @override
  String toString();

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
