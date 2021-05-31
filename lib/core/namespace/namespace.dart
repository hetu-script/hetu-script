import 'package:hetu_script/core/declaration/abstract_declaration.dart';

import '../../error/errors.dart';
import '../../grammar/lexicon.dart';
import '../../type_system/type.dart';
import '../abstract_interpreter.dart';
import '../../analyzer/declaration/variable_declaration.dart';
import '../object.dart';

/// A implementation of [HTNamespace].
/// For interpreter searching for symbols from a certain block or module.
class HTNamespace with HTObject {
  static String _getFullName(String id, HTNamespace? space) {
    var fullName = id;
    var curSpace = space;
    while (curSpace != null) {
      fullName = curSpace.id + HTLexicon.memberGet + fullName;
      curSpace = curSpace.closure;
    }
    return fullName;
  }

  late final String id;

  @override
  String toString() => '${HTLexicon.NAMESPACE} $id';

  @override
  HTType get valueType => HTType.NAMESPACE;

  /// The full closure path of this namespace
  late final String fullName;

  /// [HTDeclaration]s in this [HTNamespace],
  /// could be [HTDeclaration], [AbstractFunction], [HTEnum] or [HTClass]
  final declarations = <String, AbstractDeclaration>{};

  /// [HTDeclaration]s in this [HTNamespace],
  /// could be [HTDeclaration], [AbstractFunction], [HTEnum] or [HTClass]
  late final HTNamespace? closure;

  HTNamespace(
    HTInterpreter interpreter, {
    String? id,
    this.closure,
  }) : super() {
    this.id = id ?? HTLexicon.anonymousNamespace;
    fullName = _getFullName(this.id, closure);
  }

  /// Search for a variable by the exact name and do not search recursively.
  @override
  bool contains(String varName) => declarations.containsKey(varName);

  HTNamespace closureAt(int distance) {
    var namespace = this;
    for (var i = 0; i < distance; ++i) {
      namespace = namespace.closure!;
    }

    return namespace;
  }

  /// 在当前命名空间定义一个变量的类型
  void define(AbstractDeclaration decl, {bool override = false}) {
    if (!declarations.containsKey(decl.id) || override) {
      declarations[decl.id] = decl;
    } else {
      throw HTError.definedRuntime(decl.id);
    }
  }

  /// 从当前命名空间，以及超空间，递归获取一个变量
  /// 注意和memberGet只是从对象本身取值不同
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    if (declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = declarations[varName]!;
      return decl.value;
    }

    if (closure != null) {
      return closure!.fetch(varName, from: from);
    }

    throw HTError.undefined(varName);
  }

  dynamic fetchAt(String varName, int distance,
      {String from = HTLexicon.global}) {
    var space = closureAt(distance);
    return space.fetch(varName, from: from);
  }

  /// 从当前命名空间，以及超空间，递归获取一个变量并赋值
  /// 注意和memberSet只是对对象本身的成员赋值不同
  void assign(String varName, dynamic varValue,
      {String from = HTLexicon.global}) {
    if (declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = declarations[varName]!;
      decl.value = varValue;
      return;
    }

    if (closure != null) {
      closure!.assign(varName, varValue, from: from);
      return;
    }

    throw HTError.undefined(varName);
  }

  void assignAt(String varName, dynamic varValue, int distance,
      {String from = HTLexicon.global}) {
    var space = closureAt(distance);
    space.assign(varName, varValue, from: from);
  }
}
