import 'common.dart';
import 'namespace.dart';
import 'type.dart';

/// 函数抽象类，ast 和 字节码分别有各自的具体实现
abstract class HTFunction with HTType {
  static var anonymousIndex = 0;
  static final callStack = <String>[];

  final String id;
  final String declId;
  final String? className;

  final FunctionType funcType;

  final ExternFunctionType externType;

  final String? externalTypedef;

  @override
  late final HTFunctionTypeId typeid;

  HTTypeId get returnType => typeid.returnType;

  final List<HTTypeId> typeParams; // function<T1, T2>

  final bool isStatic;

  final bool isConst;

  final bool isVariadic;

  bool get isMethod => className != null;

  final int minArity;
  final int maxArity;

  HTNamespace? context;

  HTFunction(this.id, this.declId,
      {this.className,
      this.funcType = FunctionType.normal,
      this.externType = ExternFunctionType.none,
      this.externalTypedef,
      this.typeParams = const [],
      this.isStatic = false,
      this.isConst = false,
      this.isVariadic = false,
      this.minArity = 0,
      this.maxArity = 0});

  dynamic call(
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const <HTTypeId>[]}) {}
}
