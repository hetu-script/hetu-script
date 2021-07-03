import 'package:meta/meta.dart';

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

  bool get isPrivate => displayName.startsWith(HTLexicon.privatePrefix);

  final String? classId;

  final HTNamespace? closure;

  final HTSource? source;

  final SourceRange idRange;

  final SourceRange sourceRange;

  final bool isExternal;

  final bool isStatic;

  final bool isConst;

  final bool isMutable;

  final bool isTopLevel;

  final bool isExported;

  bool get isMember => classId != null;

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

  @mustCallSuper
  void resolve() {}

  bool isOverrideOf(HTDeclaration decl) => false;

  /// Create a copy of this declaration,
  /// mainly used on class member inheritance and function arguments passing.
  dynamic clone();
}
