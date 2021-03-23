import 'common.dart';
import 'namespace.dart';
import 'type.dart';
import 'lexicon.dart';

/// 函数抽象类，ast 和 字节码分别有各自的具体实现
abstract class HTFunction with HTType {
  static var _anonymousIndex = 0;
  static final callStack = <String>[];

  late final String id;
  final String? className;

  final FunctionType funcType;

  @override
  late final HTFunctionTypeId typeid;

  HTTypeId get returnType => typeid.returnType;

  final List<HTTypeId> typeParams; // function<T1, T2>

  final bool isExtern;

  final bool isStatic;

  final bool isConst;

  final bool isVariadic;

  bool get isMethod => className != null;

  final int minArity;
  final int maxArity;

  HTNamespace? context;

  HTFunction(
      {String? id,
      this.className,
      this.funcType = FunctionType.normal,
      this.typeParams = const [],
      this.isExtern = false,
      this.isStatic = false,
      this.isConst = false,
      this.isVariadic = false,
      this.minArity = 0,
      this.maxArity = 0}) {
    switch (funcType) {
      case FunctionType.constructor:
        this.id = (id == null) ? className! : '${className!}.$id';
        break;
      case FunctionType.getter:
        this.id = HTLexicon.getter + id!;
        break;
      case FunctionType.setter:
        this.id = HTLexicon.setter + id!;
        break;
      default:
        this.id = id ?? HTLexicon.anonymousFunction + (_anonymousIndex++).toString();
    }
  }

  dynamic call(
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const <HTTypeId>[]}) {}
}
