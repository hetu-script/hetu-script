import '../../error/error.dart';
import '../../grammar/lexicon.dart';
import '../../source/source.dart';
import '../declaration.dart';
import '../../value/entity.dart';
// import 'module.dart';

class ImportDeclaration {
  final String fullName;

  final String? alias;

  final List<String> showList;

  final bool isExported;

  ImportDeclaration(
    this.fullName, {
    this.alias,
    this.showList = const [],
    this.isExported = true,
  });
}

/// Namespace is used when importing with a name
/// or for interpreter searching for symbols
/// from a certain block or module.
class HTNamespace extends HTDeclaration with HTEntity {
  @override
  String toString() => '${HTLexicon.NAMESPACE} $id';

  late String _fullName;

  /// The full closure path of this namespace
  String get fullName => _fullName;

  final declarations = <String, HTDeclaration>{};

  final imports = <String, ImportDeclaration>{};

  final exports = <String>[];

  HTNamespace(
      {String? id,
      String? classId,
      HTNamespace? closure,
      HTSource? source,
      bool isTopLevel = false})
      : super(
            id: id,
            classId: classId,
            closure: closure,
            source: source,
            isTopLevel: isTopLevel) {
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

  /// Fetch a value from this namespace,
  /// if not found and [recursive] is true, will continue search in super namespaces.
  @override
  dynamic memberGet(String varName,
      {bool recursive = true, bool error = true}) {
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

    if (error) {
      throw HTError.undefined(varName);
    }
  }

  /// Fetch a declaration from this namespace,
  /// if not found and [recursive] is true, will continue search in super namespaces,
  /// then assign the value to that declaration.
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
      {String? alias,
      List<String> showList = const [],
      bool isExported = false}) {
    final decl = ImportDeclaration(
      key,
      alias: alias,
      showList: showList,
      isExported: isExported,
    );
    imports[key] = decl;
  }

  void declareExport(String id) {
    exports.add(id);
  }

  void import(HTNamespace other,
      {bool clone = false,
      bool isExported = false,
      List<String> showList = const []}) {
    if (isExported && showList.isNotEmpty) {
      for (final id in showList) {
        declareExport(id);
      }
    }
    for (final key in other.declarations.keys) {
      var decl = other.declarations[key]!;
      if (other.exports.isNotEmpty) {
        if (!other.exports.contains(decl.id)) {
          continue;
        }
      }
      if (clone) {
        decl = decl.clone();
      }
      define(key, decl, error: false);
      if (isExported && showList.isEmpty) {
        declareExport(decl.id!);
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
