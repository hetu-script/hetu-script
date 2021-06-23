import '../error/error.dart';
import '../grammar/lexicon.dart';
import '../source/source.dart';
import 'element.dart';

/// For interpreter searching for symbols
/// from a certain block or module.
class HTNamespace extends HTElement {
  @override
  String toString() => '${HTLexicon.NAMESPACE} $id';

  late String _fullName;

  /// The full closure path of this namespace
  String get fullName => _fullName;

  final declarations = <String, HTElement>{};

  HTNamespace(
      {String? id,
      String? classId,
      HTNamespace? closure,
      HTSource? source,
      Map<String, HTElement> declarations = const {}})
      : super(id: id, classId: classId, closure: closure, source: source) {
    // calculate the full name of this namespace
    _fullName = name;
    var curSpace = closure;
    while (curSpace != null) {
      _fullName = curSpace.name + HTLexicon.memberGet + fullName;
      curSpace = curSpace.closure;
    }

    this.declarations.addAll(declarations);
  }

  /// define a declaration in this namespace,
  /// the defined id could be different from
  /// declaration's id
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
  dynamic memberGet(String field, {bool recursive = true, bool error = true}) {
    // if (field.startsWith(HTLexicon.privatePrefix) &&
    //     !from.startsWith(fullName)) {
    //   throw HTError.privateMember(field);
    // }
    if (declarations.containsKey(field)) {
      final decl = declarations[field]!;
      return decl.value;
    }

    if (recursive && (closure != null)) {
      return closure!.memberGet(field);
    }

    if (error) {
      throw HTError.undefined(field);
    }
  }

  /// 从当前命名空间，以及超空间，递归获取一个变量并赋值
  /// 注意和memberSet只是对对象本身的成员赋值不同
  @override
  void memberSet(String field, dynamic varValue,
      {bool recursive = true, bool error = true}) {
    if (declarations.containsKey(field)) {
      final decl = declarations[field]!;
      decl.value = varValue;
      return;
    }

    if (recursive && (closure != null)) {
      closure!.memberSet(field, varValue);
      return;
    }

    throw HTError.undefined(field);
  }

  void import(HTNamespace other) {
    for (final decl in other.declarations.values) {
      if (decl.id != null) {
        define(decl.id!, decl, error: false);
      }
    }
  }

  @override
  HTNamespace clone() => HTNamespace(
      id: id,
      classId: classId,
      closure: closure,
      source: source,
      declarations: declarations);
}
