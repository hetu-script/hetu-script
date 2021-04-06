import 'common.dart';
import 'namespace.dart';
import 'type.dart';
import 'declaration.dart';
import 'object.dart';
import 'class.dart';

/// [HTFunction] is the base class of functions in Hetu.
///
/// Ast and byte codes has their own implementation.
abstract class HTFunction with HTDeclaration, HTObject {
  static final callStack = <String>[];

  final String declId;
  final String moduleUniqueKey;
  final HTClass? klass;

  final FunctionType funcType;

  final ExternalFunctionType externalFunctionType;

  final String? externalTypedef;

  @override
  late final HTFunctionTypeId typeid;

  HTTypeId get returnType => typeid.returnType;

  final List<HTTypeId> typeArgs; // function<T1, T2>

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
      this.externalFunctionType = ExternalFunctionType.none,
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

  /// Sub-classes of [HTFunction] must define [clone] method.
  @override
  HTFunction clone();

  /// Sub-classes of [HTFunction] must define [toString] method.
  @override
  String toString();

  /// Sub-classes of [HTFunction] must define [call] method.
  dynamic call(
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const [],
      bool errorHandled = true});

  @override
  bool isA(HTTypeId otherTypeId) {
    if (otherTypeId == HTTypeId.ANY) {
      return true;
    } else if (HTTypeId is! HTFunctionTypeId) {
      return false;
    } else {
      return typeid == otherTypeId;
    }
  }
}
