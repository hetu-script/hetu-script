import '../error/error.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../type/type.dart';
import 'variable/typed_variable_declaration.dart';
import 'element.dart';

/// For interpreter searching for symbols
/// from a certain block or module.
class HTNamespace extends HTElement {
  @override
  String toString() => '${HTLexicon.NAMESPACE} $id';

  @override
  HTType get valueType => HTType.NAMESPACE;

  late String _fullName;

  /// The full closure path of this namespace
  String get fullName => _fullName;

  @override
  final declarations = <String, HTElement>{};

  /// [HTTypedVariableDeclaration]s in this [HTNamespace],
  /// could be [HTTypedVariableDeclaration], [AbstractFunction], [HTEnum] or [HTClass]
  late final HTNamespace? closure;

  HTNamespace(
    String moduleFullName,
    String libraryName, {
    String id = SemanticNames.anonymousNamespace,
    String? classId,
    bool isExternal = false,
    this.closure,
  }) : super(id, moduleFullName, libraryName,
            classId: classId, isExternal: isExternal) {
    // calculate the full name of this namespace
    _fullName = id;
    var curSpace = closure;
    while (curSpace != null) {
      _fullName = curSpace.id + HTLexicon.memberGet + fullName;
      curSpace = curSpace.closure;
    }
  }

  HTNamespace closureAt(int distance) {
    var namespace = this;
    for (var i = 0; i < distance; ++i) {
      namespace = namespace.closure!;
    }

    return namespace;
  }

  /// 在当前命名空间定义一个变量的类型
  void define(String id, HTElement decl,
      {bool override = false, bool error = true}) {
    if (!declarations.containsKey(id) || override) {
      declarations[id] = decl;
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
      {String from = SemanticNames.global,
      bool recursive = true,
      bool error = true}) {
    if (declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = declarations[varName]!;
      return decl.value;
    }

    if (recursive && (closure != null)) {
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
      {String from = SemanticNames.global}) {
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
      define(decl.id, decl, error: false);
    }
  }
}
