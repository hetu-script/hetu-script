import '../../declaration/namespace/declaration_namespace.dart';
import '../../declaration/declaration.dart';
import '../../source/source.dart';
import '../../error/error.dart';

/// A namespace that will return the actual value of the declaration.
class HTNamespace extends HTDeclarationNamespace<HTDeclaration> {
  final HTNamespace? _closure;

  @override
  HTNamespace? get closure => _closure;

  HTNamespace(
      {String? id,
      String? classId,
      HTNamespace? closure,
      HTSource? source,
      bool isTopLevel = false})
      : _closure = closure,
        super(
          id: id,
          classId: classId,
          closure: closure,
          source: source,
        );

  @override
  dynamic memberGet(String varName,
      {String? from, bool recursive = false, bool error = true}) {
    if (symbols.containsKey(varName)) {
      final decl = symbols[varName]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      return decl.value;
    }
    if (importedSymbols.containsKey(varName)) {
      final decl = importedSymbols[varName]!;
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
  bool memberSet(String varName, dynamic varValue,
      {String? from, bool recursive = false, bool error = true}) {
    if (symbols.containsKey(varName)) {
      final decl = symbols[varName]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      decl.value = varValue;
      return true;
    }
    if (importedSymbols.containsKey(varName)) {
      final decl = importedSymbols[varName]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      decl.value = varValue;
      return true;
    }
    if (recursive && (closure != null)) {
      return closure!
          .memberSet(varName, varValue, from: from, recursive: recursive);
    }
    if (error) {
      throw HTError.undefined(varName);
    } else {
      return false;
    }
  }

  @override
  void resolve() {
    for (final decl in symbols.values) {
      decl.resolve();
    }
  }

  @override
  HTDeclarationNamespace clone() {
    final cloned = HTDeclarationNamespace(
        id: id, classId: classId, closure: closure, source: source);
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
