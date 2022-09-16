import '../../declaration/namespace/declaration_namespace.dart';
import '../../declaration/declaration.dart';
import '../../error/error.dart';
import '../../type/type.dart';

/// A namespace that will return the actual value of the declaration.
class HTNamespace extends HTDeclarationNamespace<HTDeclaration> {
  @override
  HTType? get valueType => HTTypeNamespace(lexicon.kNamespace);

  final HTNamespace? _closure;

  @override
  HTNamespace? get closure => _closure;

  HTNamespace(
      {required super.lexicon,
      super.id,
      super.classId,
      HTNamespace? closure,
      super.source,
      super.documentation,
      bool isTopLevel = false})
      : _closure = closure,
        super(closure: closure);

  String? help(String varName) {
    if (symbols.containsKey(varName)) {
      final decl = symbols[varName]!;
      return decl.documentation;
    } else if (importedSymbols.containsKey(varName)) {
      final decl = importedSymbols[varName]!;
      return decl.documentation;
    } else if (closure != null) {
      final decl =
          closure!.memberGet(varName, isRecursive: true, throws: false);
      if (decl != null) {
        return (decl as HTDeclaration).documentation;
      }
    }
    throw HTError.undefined(varName);
  }

  @override
  dynamic memberGet(String varName,
      {bool isPrivate = false,
      String? from,
      bool isRecursive = false,
      bool throws = true}) {
    if (symbols.containsKey(varName)) {
      final decl = symbols[varName]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      decl.resolve();
      return decl.value;
    } else if (importedSymbols.containsKey(varName)) {
      final decl = importedSymbols[varName]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      decl.resolve();
      return decl.value;
    } else if (isRecursive && (closure != null)) {
      return closure!.memberGet(varName,
          from: from, isRecursive: isRecursive, throws: throws);
    }
    if (throws) {
      throw HTError.undefined(varName);
    }
  }

  /// Fetch a declaration from this namespace,
  /// if not found and [isRecursive] is true, will continue search in super namespaces,
  /// then assign the value to that declaration.
  /// If [isRecursive] is true, means this is not a 'memberset operator' search.
  @override
  bool memberSet(
    String varName,
    dynamic varValue, {
    String? from,
    bool isRecursive = false,
    bool throws = true,
  }) {
    if (symbols.containsKey(varName)) {
      final decl = symbols[varName]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      decl.resolve();
      decl.value = varValue;
      return true;
    } else if (importedSymbols.containsKey(varName)) {
      final decl = importedSymbols[varName]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      decl.resolve();
      decl.value = varValue;
      return true;
    } else if (isRecursive && (closure != null)) {
      return closure!
          .memberSet(varName, varValue, from: from, isRecursive: true);
    } else {
      if (throws) {
        throw HTError.undefined(varName);
      }
    }

    return false;
  }

  @override
  HTDeclarationNamespace<HTDeclaration> clone() {
    final cloned = HTDeclarationNamespace<HTDeclaration>(
      lexicon: lexicon,
      id: id,
      classId: classId,
      closure: closure,
      source: source,
    );
    for (final decl in symbols.values) {
      cloned.symbols[decl.id!] = decl.clone();
    }
    for (final decl in imports.values) {
      cloned.imports[decl.fromPath] = decl;
    }
    cloned.exports.addAll(exports);
    for (final decl in importedSymbols.values) {
      cloned.importedSymbols[decl.id!] = decl.clone();
    }
    return cloned;
  }
}
