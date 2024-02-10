import '../../error/error.dart';
// import '../../source/source.dart';
import '../../declaration/declaration.dart';
import '../../value/entity.dart';
import '../../value/unresolved_import.dart';
import '../../lexicon/lexicon.dart';

/// A semantic namespace that holds symbol for resolving.
class HTDeclarationNamespace<T> extends HTDeclaration with HTEntity {
  final HTLexicon lexicon;

  late String _fullName;

  /// The full closure path of this namespace
  String get fullName => _fullName;

  final symbols = <String, T>{};

  final importedSymbols = <String, T>{};

  final importedSymbolsPath = <String, String>{};

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
    super.isPrivate,
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
  bool contains(String id,
      {bool isPrivate = false, String? from, bool recursive = false}) {
    if (symbols.containsKey(id)) {
      if (isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(id);
      }
      return true;
    } else if (importedSymbols.containsKey(id)) {
      return true;
    } else if (recursive && (closure != null)) {
      return closure!.contains(id, from: from, recursive: recursive);
    }
    return false;
  }

  /// define a declaration in this namespace,
  /// the defined id could be different from declaration's id
  bool define(String id, T decl, {bool override = false, bool throws = true}) {
    if (!symbols.containsKey(id) || override) {
      symbols[id] = decl;
      return true;
    } else {
      if (throws) {
        throw HTError.defined(id, ErrorType.staticWarning);
      }
    }

    return false;
  }

  void delete(String id, {bool throws = true}) {
    if (symbols.containsKey(id)) {
      symbols.remove(id);
    } else {
      if (throws) {
        throw HTError.undefined(id);
      }
    }
  }

  /// Fetch a value from this namespace,
  /// Return declaration rather than actual values.
  /// If not found and [isRecursive] is true, will continue search in super namespaces.
  /// If [isRecursive] is true, means this is not a 'memberget operator' search.
  @override
  dynamic memberGet(String id,
      {bool isPrivate = false,
      String? from,
      bool isRecursive = false,
      bool throws = true}) {
    if (symbols.containsKey(id)) {
      final decl = symbols[id];
      if (isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(id);
      }
      return decl;
    } else if (importedSymbols.containsKey(id)) {
      final decl = importedSymbols[id];
      return decl;
    } else if (isRecursive && (closure != null)) {
      return closure!.memberGet(id, from: from, isRecursive: true);
    }

    if (throws) {
      throw HTError.undefined(id);
    }
  }

  void declareImport(UnresolvedImport decl) {
    imports[decl.fromPath] = decl;
  }

  void declareExport(String id) {
    exports.add(id);
  }

  void defineImport(String key, T decl, String from) {
    if (!importedSymbols.containsKey(key)) {
      importedSymbols[key] = decl;
      importedSymbolsPath[key] = from;
    } else {
      if (importedSymbolsPath[key] != from) {
        throw HTError.defined(key, ErrorType.runtimeError);
      }
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
        defineImport(key, null as T, other.fullName);
      } else {
        defineImport(key, decl, other.fullName);
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
        defineImport(key, null as T, other.fullName);
      } else {
        defineImport(key, decl, other.fullName);
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
