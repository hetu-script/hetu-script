import 'package:hetu_script/src/declaration.dart';
import 'package:hetu_script/src/object.dart';

import 'common.dart';
import 'namespace.dart';
import 'type.dart';

/// 函数抽象类，ast 和 字节码分别有各自的具体实现
abstract class HTFunction with HTDeclaration, HTObject {
  static var anonymousIndex = 0;
  static final callStack = <String>[];

  final String declId;
  final String? classId;
  // final HTTypeId? classTypeId;
  final String module;

  final FunctionType funcType;

  final ExternalFuncDeclType externalFuncDeclType;

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

  HTFunction(String id, this.declId, this.module,
      {this.classId,
      this.funcType = FunctionType.normal,
      this.externalFuncDeclType = ExternalFuncDeclType.none,
      this.externalTypedef,
      this.typeParams = const [],
      this.isStatic = false,
      this.isConst = false,
      this.isVariadic = false,
      this.minArity = 0,
      this.maxArity = 0}) {
    this.id = id;
  }

  dynamic call(
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const [],
      bool errorHandled = false});
}
