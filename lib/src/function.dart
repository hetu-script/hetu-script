import 'package:hetu_script/src/declaration.dart';
import 'package:hetu_script/src/object.dart';

import 'common.dart';
import 'namespace.dart';
import 'type.dart';

/// [HTFunction] is the base class of functions in Hetu.
///
/// Extends this class to call functions in ast or bytecode modules.
abstract class HTFunction with HTDeclaration, HTObject {
  static final callStack = <String>[];

  final String declId;
  // final HTTypeId? classTypeId;
  final String moduleUniqueKey;

  final FunctionType funcType;

  final ExternalFunctionType externalFunctionType;

  final String? externalTypedef;

  @override
  late final HTFunctionTypeId typeid;

  HTTypeId get returnType => typeid.returnType;

  final List<HTTypeId> typeParams; // function<T1, T2>

  final bool isStatic;

  final bool isConst;

  final bool isVariadic;

  bool get isMethod => classId != null;

  final int minArity;
  final int maxArity;

  HTNamespace? context;

  HTFunction(String id, this.declId, this.moduleUniqueKey,
      {String? classId,
      this.funcType = FunctionType.normal,
      this.externalFunctionType = ExternalFunctionType.none,
      this.externalTypedef,
      this.typeParams = const [],
      this.isStatic = false,
      this.isConst = false,
      this.isVariadic = false,
      this.minArity = 0,
      this.maxArity = 0}) {
    this.id = id;
    this.classId = classId;
  }

  dynamic call(
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const [],
      bool errorHandled = true});
}
