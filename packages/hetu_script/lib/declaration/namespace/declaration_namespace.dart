import '../../error/error.dart';
import '../../source/source.dart';
import '../../declaration/declaration.dart';
import '../../value/entity.dart';
import '../../value/unresolved_import_statement.dart';

/// A semantic namespace that holds declarations for symbol resolving.
/// will return declaration rather than actual values.
class HTDeclarationNamespace<T> extends HTDeclaration with HTEntity {
  late String _fullName;

  /// The full closure path of this namespace
  String get fullName => _fullName;

  final symbols = <String, T>{};

  final importedSymbols = <String, T>{};

  final imports = <String, UnresolvedImportStatement>{};

  final exports = <String>[];

  bool get willExportAll => exports.isEmpty;

  HTDeclarationNamespace(
      {String? id,
      String? classId,
      HTDeclarationNamespace? closure,
      HTSource? source})
      : super(id: id, classId: classId, closure: closure, source: source) {
    // calculate the full name of this namespace
    _fullName = displayName;
    var curSpace = closure;
    while (curSpace != null) {
      _fullName = '${curSpace.displayName}.$fullName';
      curSpace = curSpace.closure;
    }
  }

  @override
  bool contains(String varName, {String? from, bool recursive = false}) {
    if (symbols.containsKey(varName)) {
      if (isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      return true;
    } else if (importedSymbols.containsKey(varName)) {
      return true;
    } else if (recursive && (closure != null)) {
      return closure!.contains(varName, from: from, recursive: recursive);
    }
    return false;
  }

  /// define a declaration in this namespace,
  /// the defined id could be different from
  /// declaration's id
  void define(String varName, T decl,
      {bool override = false, bool error = true}) {
    if (!symbols.containsKey(varName) || override) {
      symbols[varName] = decl;
    } else {
      if (error) {
        throw HTError.defined(varName, ErrorType.staticWarning);
      }
    }
  }

  void delete(String varName, {bool error = true}) {
    if (symbols.containsKey(varName)) {
      symbols.remove(varName);
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
    if (symbols.containsKey(varName)) {
      final decl = symbols[varName]!;
      // if (from != null && !from.startsWith(fullName)) {
      //   throw HTError.privateMember(varName);
      // }
      return decl;
    } else if (importedSymbols.containsKey(varName)) {
      final decl = importedSymbols[varName]!;
      return decl;
    } else if (recursive && (closure != null)) {
      return closure!.memberGet(varName, from: from, recursive: recursive);
    }

    if (error) {
      throw HTError.undefined(varName);
    }
  }

  void declareImport(UnresolvedImportStatement decl) {
    imports[decl.fromPath] = decl;
  }

  void declareExport(String id) {
    exports.add(id);
  }

  void defineImport(String key, T decl) {
    if (!importedSymbols.containsKey(key)) {
      importedSymbols[key] = decl;
    } else {
      throw HTError.defined(key, ErrorType.runtimeError);
    }
  }

  void import(HTDeclarationNamespace other,
      {bool clone = false,
      bool isExported = false,
      Set<String> showList = const {}}) {
    for (final key in other.symbols.keys) {
      var decl = other.symbols[key]!;
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
    for (final key in other.importedSymbols.keys) {
      var decl = other.importedSymbols[key]!;
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
  HTDeclarationNamespace clone() {
    final cloned = HTDeclarationNamespace(
        id: id, classId: classId, closure: closure, source: source);
    cloned.symbols.addAll(symbols);
    cloned.imports.addAll(imports);
    cloned.exports.addAll(exports);
    cloned.importedSymbols.addAll(importedSymbols);
    return cloned;
  }
}
