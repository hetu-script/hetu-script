import 'common.dart';
import 'namespace.dart';
import 'type.dart';
import 'lexicon.dart';

/// 具体的FunctionTypeId由具体的实现者提供
abstract class HTFunction with HTType {
  static var anonymousIndex = 0;
  static final callStack = <String>[];

  late final String? id;
  late final String internalName;
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

  HTNamespace? context;

  HTFunction(
      {String? id,
      this.className,
      this.funcType = FunctionType.normal,
      this.typeParams = const [],
      this.isExtern = false,
      this.isStatic = false,
      this.isConst = false,
      this.isVariadic = false}) {
    switch (funcType) {
      case FunctionType.constructor:
        if (id != null) {
          this.id = id;
          internalName = '$className.$id';
        } else {
          internalName = '$className';
        }
        break;
      case FunctionType.getter:
        this.id = id;
        internalName = HTLexicon.getter + id!;
        break;
      case FunctionType.setter:
        this.id = id;
        internalName = HTLexicon.setter + id!;
        break;
      case FunctionType.literal:
        this.id = internalName = HTLexicon.anonymousFunction + (HTFunction.anonymousIndex++).toString();
        break;
      case FunctionType.nested:
        if (id == null) {
          this.id = internalName = HTLexicon.anonymousFunction + (HTFunction.anonymousIndex++).toString();
        } else {
          this.id = internalName = id;
        }
        break;
      case FunctionType.normal:
        this.id = internalName = id!;
        break;
    }
  }

  dynamic call(
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const <HTTypeId>[]}) {}
}
