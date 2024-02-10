import '../error/error.dart';
// import '../grammar/HTLocale.current.dart';
import '../source/source.dart';
import '../source/source_range.dart';
import '../type/type.dart';
import 'namespace/declaration_namespace.dart';

/// Declaration is a semantic entity in the program that
/// represents things that are declared with a name
/// and hence can be referenced elsewhere in the code.
/// Declaration is not necessarily exists in actual namespaces,
/// some declaration are generated purely for analysis purpose.
abstract class HTDeclaration {
  final String? id;

  String get displayName => id ?? '';

  final bool _isPrivate;

  /// Wether this declaration is only accessible from the same namespace.
  bool get isPrivate => _isPrivate || (id == null);

  HTType? get declType => null;

  final String? classId;

  final HTDeclarationNamespace? closure;

  final HTSource? source;

  final SourceRange idRange;

  final SourceRange sourceRange;

  /// Wether this declaration is from outside of the script.
  final bool isExternal;

  /// Wether this declaration is static in a class.
  final bool isStatic;

  /// Wether this declaration is a const value.
  final bool isConst;

  /// Wether this declaration's value can be assigned to another value.
  final bool isMutable;

  /// Wether this declaration is defined on top level of a source.
  final bool isTopLevel;

  /// Wether this declaration is a member of a class or struct.
  // bool get isMember => classId != null;

  final bool isField;

  bool get isResolved => true;

  final String? documentation;

  const HTDeclaration({
    this.id,
    this.classId,
    this.closure,
    this.source,
    this.idRange = SourceRange.empty,
    this.sourceRange = SourceRange.empty,
    bool isPrivate = false,
    this.isExternal = false,
    this.isStatic = false,
    this.isConst = false,
    this.isMutable = false,
    this.isTopLevel = false,
    this.isField = false,
    this.documentation,
  }) : _isPrivate = isPrivate;

  void resolve() {}

  dynamic get value => this;

  set value(dynamic newVal) {
    throw HTError.immutable(displayName);
  }

  /// Create a copy of this declaration,
  /// mainly used on class member inheritance and function arguments passing.
  dynamic clone();
}
