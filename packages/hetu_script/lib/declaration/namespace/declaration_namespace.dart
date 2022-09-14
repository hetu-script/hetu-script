import '../../error/error.dart';
// import '../../source/source.dart';
import '../../declaration/declaration.dart';
import '../../value/entity.dart';
import '../../value/unresolved_import.dart';
import '../../lexer/lexicon.dart';

/// A semantic namespace that holds symbol for resolving.
class HTDeclarationNamespace<T> extends HTDeclaration with HTEntity {
  final HTLexicon lexicon;

  late String _fullName;

  /// The full closure path of this namespace
  String get fullName => _fullName;

  final symbols = <String, T>{};

  final importedSymbols = <String, T>{};

  final imports = <String, UnresolvedImport>{};

  final exports = <String>{};

  bool willExportAll = true;

  HTDeclarationNamespace({
    super.id,
    super.classId,
    super.closure,
    super.source,
    super.documentation,
    required this.lexicon,
  }) {
    // calculate the full name of this namespace
    _fullName = displayName;
    var curSpace = closure;
    while (curSpace != null) {
      _fullName = '${curSpace.displayName}.$fullName';
      curSpace = curSpace.closure;
    }
  }

  @override
  bool contains(String varName,
      {bool isPrivate = false, String? from, bool recursive = false}) {
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
  /// the defined id could be different from declaration's id
  bool define(String varName, T decl,
      {bool override = false, bool throws = true}) {
    if (!symbols.containsKey(varName) || override) {
      symbols[varName] = decl;
      return true;
    } else {
      if (throws) {
        throw HTError.defined(varName, ErrorType.staticWarning);
      }
    }

    return false;
  }

  void delete(String varName, {bool throws = true}) {
    if (symbols.containsKey(varName)) {
      symbols.remove(varName);
    } else {
      if (throws) {
        throw HTError.undefined(varName);
      }
    }
  }

  /// Fetch a value from this namespace,
  /// Return declaration rather than actual values.
  /// If not found and [isRecursive] is true, will continue search in super namespaces.
  /// If [isRecursive] is true, means this is not a 'memberget operator' search.
  @override
  dynamic memberGet(String varName,
      {bool isPrivate = false,
      String? from,
      bool isRecursive = false,
      bool throws = true}) {
    if (symbols.containsKey(varName)) {
      final decl = symbols[varName];
      if (isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      return decl;
    } else if (importedSymbols.containsKey(varName)) {
      final decl = importedSymbols[varName];
      return decl;
    } else if (isRecursive && (closure != null)) {
      return closure!.memberGet(varName, from: from, isRecursive: true);
    }

    if (throws) {
      throw HTError.undefined(varName);
    }
  }

  void declareImport(UnresolvedImport decl) {
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

  void import(HTDeclarationNamespace<dynamic> other,
      {bool clone = false,
      bool export = false,
      Set<String> showList = const {},
      bool idOnly = false}) {
    for (final key in other.symbols.keys) {
      var decl = other.symbols[key]!;
      if (!other.willExportAll) {
        if (!other.exports.contains(decl.id)) {
          continue;
        }
      }
      if (lexicon.isPrivate(key)) {
        continue;
      }
      if (decl is HTDeclaration) {
        if (clone) {
          decl = decl.clone();
        }
      }
      if (idOnly) {
        defineImport(key, null as T);
      } else {
        defineImport(key, decl);
      }
      if (export) {
        declareExport(key);
      }
    }
    for (final key in other.importedSymbols.keys) {
      var decl = other.importedSymbols[key]!;
      if (!other.exports.contains(decl.id)) {
        continue;
      }
      if (lexicon.isPrivate(key)) {
        continue;
      }
      if (decl is HTDeclaration) {
        if (clone) {
          decl = decl.clone();
        }
      }
      if (idOnly) {
        defineImport(key, null as T);
      } else {
        defineImport(key, decl);
      }
      if (export) {
        declareExport(key);
      }
    }
  }

  @override
  HTDeclarationNamespace<T> clone() {
    final cloned = HTDeclarationNamespace<T>(
        lexicon: lexicon,
        id: id,
        classId: classId,
        closure: closure,
        source: source);
    cloned.symbols.addAll(symbols);
    cloned.imports.addAll(imports);
    cloned.exports.addAll(exports);
    cloned.importedSymbols.addAll(importedSymbols);
    return cloned;
  }
}
