import '../../error/error.dart';
import '../../grammar/lexicon.dart';
import '../../source/source.dart';
import '../../declaration/declaration.dart';
import '../entity.dart';

class ImportDeclaration {
  final String fromPath;

  final String? alias;

  final Set<String> showList;

  final bool isExported;

  ImportDeclaration(
    this.fromPath, {
    this.alias,
    this.showList = const {},
    this.isExported = true,
  });
}

/// Namespace is used when importing with a name
/// or for interpreter searching for symbols
class HTNamespace extends HTDeclaration with HTEntity {
  @override
  String toString() => '${HTLexicon.kNamespace} $id';

  late String _fullName;

  /// The full closure path of this namespace
  String get fullName => _fullName;

  final declarations = <String, HTDeclaration>{};

  final imports = <String, ImportDeclaration>{};

  final exports = <String>[];

  bool get willExportAll => exports.isEmpty;

  final importedDeclarations = <String, HTDeclaration>{};

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
  void define(String varName, HTDeclaration decl,
      {bool override = false, bool error = true}) {
    if (!declarations.containsKey(varName) || override) {
      declarations[varName] = decl;
    } else {
      if (error) {
        throw HTError.definedRuntime(varName);
      }
    }
  }

  void delete(String varName, {bool error = true}) {
    if (declarations.containsKey(varName)) {
      declarations.remove(varName);
    } else {
      if (error) {
        throw HTError.undefined(varName);
      }
    }
  }

  /// Fetch a value from this namespace,
  /// if not found and [recursive] is true, will continue search in super namespaces.
  @override
  dynamic memberGet(String varName,
      {String? from, bool recursive = false, bool error = true}) {
    if (declarations.containsKey(varName)) {
      final decl = declarations[varName]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      return decl.value;
    }
    if (importedDeclarations.containsKey(varName)) {
      final decl = importedDeclarations[varName]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      return decl.value;
    }
    if (recursive && (closure != null)) {
      return closure!.memberGet(varName, from: from, recursive: recursive);
    }
    if (error) {
      throw HTError.undefined(varName);
    }
  }

  /// Fetch a declaration from this namespace,
  /// if not found and [recursive] is true, will continue search in super namespaces,
  /// then assign the value to that declaration.
  @override
  void memberSet(String varName, dynamic varValue,
      {String? from, bool recursive = false}) {
    if (declarations.containsKey(varName)) {
      final decl = declarations[varName]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      decl.value = varValue;
      return;
    }
    if (importedDeclarations.containsKey(varName)) {
      final decl = importedDeclarations[varName]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      decl.value = varValue;
      return;
    }
    if (recursive && (closure != null)) {
      closure!.memberSet(varName, varValue, from: from, recursive: recursive);
      return;
    }
    throw HTError.undefined(varName);
  }

  void declareImport(ImportDeclaration decl) {
    imports[decl.fromPath] = decl;
  }

  void declareExport(String id) {
    exports.add(id);
  }

  void defineImport(String key, HTDeclaration decl) {
    if (!importedDeclarations.containsKey(key)) {
      importedDeclarations[key] = decl;
    } else {
      throw HTError.definedRuntime(key);
    }
  }

  void import(HTNamespace other,
      {bool clone = false,
      bool isExported = false,
      Set<String> showList = const {}}) {
    for (final key in other.declarations.keys) {
      var decl = other.declarations[key]!;
      if (decl.isPrivate) {
        continue;
      }
      if (!other.willExportAll) {
        if (!other.exports.contains(decl.id)) {
          continue;
        }
      }
      if (clone) {
        decl = decl.clone();
      }
      defineImport(key, decl);
      if (isExported) {
        declareExport(key);
      }
    }
    for (final key in other.importedDeclarations.keys) {
      var decl = other.importedDeclarations[key]!;
      if (decl.isPrivate) {
        continue;
      }
      if (!other.exports.contains(decl.id)) {
        continue;
      }
      if (clone) {
        decl = decl.clone();
      }
      defineImport(key, decl);
      if (isExported) {
        declareExport(key);
      }
    }
  }

  @override
  void resolve() {
    for (final decl in declarations.values) {
      decl.resolve();
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
