import '../../error/error.dart';
// import '../../source/source.dart';
import '../../declaration/declaration.dart';
import '../../value/object.dart';
import '../../value/unresolved_import.dart';
import '../../lexicon/lexicon.dart';

/// A semantic namespace that holds symbol for resolving.
class HTDeclarationNamespace<T> extends HTDeclaration with HTObject {
  /// TODO: remove lexicon, save private symbols into separate maps when defined instead.
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
  @override
  void define(String id, dynamic decl,
      {bool override = false, bool throws = true}) {
    if (!symbols.containsKey(id)) {
      symbols[id] = decl;
    } else {
      if (!override) {
        if (throws) {
          throw HTError.defined(id, HTErrorType.staticWarning);
        }
      } else {
        // final existedValue = symbols[id];
        // if (existedValue is HTDeclarationNamespace &&
        //     decl is HTDeclarationNamespace) {
        //   // TODO: merge namespace?
        // } else {
        //   symbols[id] = decl;
        // }
        symbols[id] = decl;
      }
    }
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
  ///
  /// TODO: remove isPrivate check;
  @override
  dynamic memberGet(
    String id, {
    String? from,
    bool isRecursive = false,
    bool ignoreUndefined = false,
    bool isPrivate = false,
  }) {
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

    if (!ignoreUndefined) {
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
    } else {
      if (importedSymbols[key] != decl) {
        throw HTError.defined(key, HTErrorType.runtimeError);
      }
    }
  }

  void import(HTDeclarationNamespace<dynamic> other,
      {bool clone = false,
      bool export = false,
      Set<String> showList = const {},
      bool idOnly = false}) {
    bool process(String key, dynamic decl) {
      if (!other.willExportAll) {
        if (!other.exports.contains(decl?.id)) {
          return false;
        }
      }
      if (lexicon.isPrivate(key)) {
        return false;
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
      return true;
    }

    for (final key in other.symbols.keys) {
      var decl = other.symbols[key]!;
      if (!process(key, decl)) continue;
    }
    for (final key in other.importedSymbols.keys) {
      var decl = other.importedSymbols[key]!;
      if (other.exports.contains(decl?.id)) {
        if (!process(key, decl)) continue;
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
