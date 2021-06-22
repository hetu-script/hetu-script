import '../error/error.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../type/type.dart';
import 'element.dart';
import 'object.dart';

/// For interpreter searching for symbols
/// from a certain block or module.
class HTNamespace extends HTElement with HTObject {
  @override
  String toString() => '${HTLexicon.NAMESPACE} $id';

  @override
  HTType get valueType => HTType.NAMESPACE;

  late String _fullName;

  /// The full closure path of this namespace
  String get fullName => _fullName;

  final declarations = <String, HTElement>{};

  HTNamespace(
    String moduleFullName,
    String libraryName, {
    String id = SemanticNames.anonymousNamespace,
    String? classId,
    Map<String, HTElement> declarations = const {},
    HTNamespace? closure,
  }) : super(id, moduleFullName, libraryName,
            classId: classId, closure: closure) {
    // calculate the full name of this namespace
    _fullName = id;
    var curSpace = closure;
    while (curSpace != null) {
      _fullName = curSpace.id + HTLexicon.memberGet + fullName;
      curSpace = curSpace.closure;
    }

    this.declarations.addAll(declarations);
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
        throw HTError.definedRuntime(id);
      }
    }
  }

  /// 从当前命名空间，以及超空间，递归获取一个变量
  /// 注意和memberGet只是从对象本身取值不同
  @override
  dynamic memberGet(String field,
      {String from = SemanticNames.global,
      bool recursive = true,
      bool error = true}) {
    if (declarations.containsKey(field)) {
      if (field.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(field);
      }
      final decl = declarations[field]!;
      return decl.value;
    }

    if (recursive && (closure != null)) {
      return closure!.memberGet(field, from: from);
    }

    if (error) {
      throw HTError.undefined(field);
    }
  }

  /// 从当前命名空间，以及超空间，递归获取一个变量并赋值
  /// 注意和memberSet只是对对象本身的成员赋值不同
  @override
  void memberSet(String field, dynamic varValue,
      {String from = SemanticNames.global,
      bool recursive = true,
      bool error = true}) {
    if (declarations.containsKey(field)) {
      if (field.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(field);
      }
      final decl = declarations[field]!;
      decl.value = varValue;
      return;
    }

    if (recursive && (closure != null)) {
      closure!.memberSet(field, varValue, from: from);
      return;
    }

    throw HTError.undefined(field);
  }

  void import(HTNamespace other) {
    for (final decl in other.declarations.values) {
      define(decl.id, decl, error: false);
    }
  }

  @override
  HTNamespace clone() => HTNamespace(moduleFullName, libraryName,
      id: id, classId: classId, declarations: declarations, closure: closure);
}
