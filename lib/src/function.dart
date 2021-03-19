import 'common.dart';
import 'class.dart';
import 'namespace.dart';
import 'type.dart';

abstract class HTFunction with HTType {
  static final callStack = <String>[];

  HTNamespace? context;
  //HTNamespace _save;
  String get id;
  String get internalName;

  @override
  late final HTFunctionTypeId typeid;

  late final bool isExtern;

  late final bool isStatic;

  late final bool isConst;

  late final bool isVariadic;

  bool get isMethod => className != null;

  late final FunctionType funcType;
  late final String? className;

  dynamic call(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HTInstance? instance}) {}
}
