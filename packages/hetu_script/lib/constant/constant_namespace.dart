import '../declaration/constant.dart';
import '../value/unresolved_import_statement.dart';
import '../error/error.dart';

class HTConstantNamespace {
  /// The resource context key of this namespace
  final String fullName;

  final HTConstantNamespace? closure;

  final declarations = <String, HTConstantDeclaration>{};

  final importedDeclarations = <String, HTConstantDeclaration>{};

  final imports = <String, UnresolvedImportStatement>{};

  final exports = <String>[];

  bool get willExportAll => exports.isEmpty;

  HTConstantNamespace({
    required this.fullName,
    required this.closure,
  });

  /// define a declaration in this namespace,
  /// the defined id could be different from
  /// declaration's id
  void define(String varName, HTConstantDeclaration decl,
      {bool override = false, bool error = true}) {
    if (!declarations.containsKey(varName) || override) {
      declarations[varName] = decl;
    } else {
      if (error) {
        throw HTError.definedRuntime(varName);
      }
    }
  }

  /// Fetch a value from this namespace,
  /// if not found and [recursive] is true, will continue search in super namespaces.
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

  void declareImport(UnresolvedImportStatement decl) {
    imports[decl.fromPath] = decl;
  }

  void declareExport(String id) {
    exports.add(id);
  }

  void defineImport(String key, HTConstantDeclaration decl) {
    if (!importedDeclarations.containsKey(key)) {
      importedDeclarations[key] = decl;
    } else {
      throw HTError.definedRuntime(key);
    }
  }

  void import(HTConstantNamespace other,
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

  void resolve() {
    for (final decl in declarations.values) {
      decl.resolve();
    }
  }
}
