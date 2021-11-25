import '../error/error.dart';
import '../grammar/lexicon.dart';
// import '../grammar/semantic.dart';
import '../source/source.dart';
import '../source/source_range.dart';
// import '../type/type.dart';
import 'namespace/namespace.dart';

/// Declaration is a semantic entity in the program that
/// represents things that are declared with a name
/// and hence can be referenced elsewhere in the code.
///
/// Declaration is not necessarily exists in actual source,
/// and is not necessarily exists in compiled bytecode
/// some declaration are generated purely for analysis purpose.
abstract class HTDeclaration {
  final String? id;

  String get displayName => id ?? '';

  final String? classId;

  final HTNamespace? closure;

  final HTSource? source;

  final SourceRange idRange;

  final SourceRange sourceRange;

  /// Wether this declaration is from outside of the script.
  final bool isExternal;

  /// Wether this declaration is static in a class.
  final bool isStatic;

  /// Wether this declaration is a compile time const value.
  final bool isConst;

  /// Wether this declaration's value can be assigned to another value.
  final bool isMutable;

  /// Wether this declaration is defined directly under a module.
  final bool isTopLevel;

  /// Wether this declaration is explicitly exported.
  final bool isExported;

  /// Wether this declaration is a member of a class.
  bool get isMember => classId != null;

  /// Wether this declaration is only accessible from a same class namespace.
  bool get isPrivate => displayName.startsWith(HTLexicon.privatePrefix);

  HTDeclaration(
      {this.id,
      this.classId,
      this.closure,
      this.source,
      this.idRange = SourceRange.EMPTY,
      this.sourceRange = SourceRange.EMPTY,
      this.isExternal = false,
      this.isStatic = false,
      this.isConst = false,
      this.isMutable = false,
      this.isTopLevel = false,
      this.isExported = false});

  dynamic get value => this;

  set value(dynamic newVal) {
    throw HTError.immutable(displayName);
  }

  void resolve() {}

  bool isOverrideOf(HTDeclaration decl) => false;

  /// Create a copy of this declaration,
  /// mainly used on class member inheritance and function arguments passing.
  dynamic clone();
}