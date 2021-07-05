import '../../error/error.dart';
import '../../grammar/lexicon.dart';
import '../../source/source.dart';
import '../declaration.dart';
import '../../object/object.dart';
import 'module.dart';

class ImportDeclaration {
  final String fullName;

  final String? alias;

  final List<String> showList;

  ImportDeclaration(this.fullName, {this.alias, this.showList = const []});
}

/// Namespace is used when importing with a name
/// or for interpreter searching for symbols
/// from a certain block or module.
class HTNamespace extends HTDeclaration with HTObject {
  @override
  String toString() => '${HTLexicon.NAMESPACE} $id';

  late String _fullName;

  /// The full closure path of this namespace
  String get fullName => _fullName;

  final declarations = <String, HTDeclaration>{};

  final imports = <String, ImportDeclaration>{};

  HTNamespace(
      {String? id,
      String? classId,
      HTNamespace? closure,
      HTSource? source,
      bool isTopLevel = false,
      bool isExported = false})
      : super(
            id: id,
            classId: classId,
            closure: closure,
            source: source,
            isTopLevel: isTopLevel,
            isExported: isExported) {
    // calculate the full name of this namespace
    _fullName = displayName;
    var curSpace = closure;
    while (curSpace != null) {
      _fullName = curSpace.displayName + HTLexicon.memberGet + fullName;
      curSpace = curSpace.closure;
    }
  }

  /// define a declaration in this namespace,
  /// the defined id could be different from
  /// declaration's id
  void define(String id, HTDeclaration decl,
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
  dynamic memberGet(String varName, {bool recursive = true}) {
    // if (varName.startsWith(HTLexicon.privatePrefix) &&
    //     !from.startsWith(fullName)) {
    //   throw HTError.privateMember(varName);
    // }
    if (declarations.containsKey(varName)) {
      final decl = declarations[varName]!;
      return decl.value;
    }

    if (recursive && (closure != null)) {
      return closure!.memberGet(varName, recursive: recursive);
    }

    throw HTError.undefined(varName);
  }

  /// 从当前命名空间，以及超空间，递归获取一个变量并赋值
  /// 注意和memberSet只是对对象本身的成员赋值不同
  @override
  void memberSet(String varName, dynamic varValue, {bool recursive = true}) {
    if (declarations.containsKey(varName)) {
      final decl = declarations[varName]!;
      decl.value = varValue;
      return;
    }

    if (recursive && (closure != null)) {
      closure!.memberSet(varName, varValue, recursive: recursive);
      return;
    }

    throw HTError.undefined(varName);
  }

  void declareImport(String key,
      {String? alias, List<String> showList = const []}) {
    final decl = ImportDeclaration(key, alias: alias, showList: showList);
    imports[key] = decl;
  }

  void import(HTNamespace other, {bool clone = false}) {
    if ((other is HTModule) && other.isLibraryEntry) {
      for (final key in other.declarations.keys) {
        var decl = other.declarations[key]!;
        if (decl.isExported) {
          if (clone) {
            decl = decl.clone();
          }
          define(key, decl, error: false);
        }
      }
    } else {
      for (final key in other.declarations.keys) {
        var decl = other.declarations[key]!;
        if (clone) {
          decl = decl.clone();
        }
        define(key, decl, error: false);
      }
    }
  }

  @override
  HTNamespace clone() {
    final cloned =
        HTNamespace(id: id, classId: classId, closure: closure, source: source);
    cloned.import(this, clone: true);
    return cloned;
  }
}
