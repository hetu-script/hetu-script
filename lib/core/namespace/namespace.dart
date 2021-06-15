import '../../error/errors.dart';
import '../../grammar/lexicon.dart';
import '../../type/type.dart';
import '../abstract_interpreter.dart';
import '../declaration/variable_declaration.dart';
import '../declaration/typed_variable_declaration.dart';
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

  /// [TypedVariableDeclaration]s in this [HTNamespace],
  /// could be [TypedVariableDeclaration], [AbstractFunction], [HTEnum] or [HTClass]
  final declarations = <String, VariableDeclaration>{};

  /// [TypedVariableDeclaration]s in this [HTNamespace],
  /// could be [TypedVariableDeclaration], [AbstractFunction], [HTEnum] or [HTClass]
  late final HTNamespace? closure;

  HTNamespace(
    AbstractInterpreter interpreter, {
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
  void define(VariableDeclaration decl,
      {bool override = false, bool error = true}) {
    if (!declarations.containsKey(decl.id) || override) {
      declarations[decl.id] = decl;
    } else {
      if (error) {
        throw HTError.definedRuntime(decl.id);
      }
    }
  }

  /// 从当前命名空间，以及超空间，递归获取一个变量
  /// 注意和memberGet只是从对象本身取值不同
  @override
  dynamic memberGet(String varName,
      {String from = HTLexicon.global, bool error = true}) {
    if (declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = declarations[varName]!;
      return decl.value;
    }

    if (closure != null) {
      return closure!.memberGet(varName, from: from);
    }

    if (error) {
      throw HTError.undefined(varName);
    }
  }

  /// 从当前命名空间，以及超空间，递归获取一个变量并赋值
  /// 注意和memberSet只是对对象本身的成员赋值不同
  @override
  void memberSet(String varName, dynamic varValue,
      {String from = HTLexicon.global}) {
    if (declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = declarations[varName]!;
      decl.value = varValue;
      return;
    }

    if (closure != null) {
      closure!.memberSet(varName, varValue, from: from);
      return;
    }

    throw HTError.undefined(varName);
  }

  void import(HTNamespace other) {
    for (final decl in other.declarations.values) {
      define(decl, error: false);
    }
  }
}
