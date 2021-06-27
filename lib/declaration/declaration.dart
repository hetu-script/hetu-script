import 'package:meta/meta.dart';

import '../error/error.dart';
import '../grammar/lexicon.dart';
// import '../grammar/semantic.dart';
import '../source/source.dart';
import '../source/source_range.dart';
// import '../type/type.dart';
import '../object/object.dart';
import 'namespace.dart';

/// Element is a semantic entity in the program that
/// represents things that are declared with a name
/// and hence can be referenced elsewhere in the code.
abstract class HTDeclaration with HTObject {
  final String? id;

  // ('${SemanticNames.anonymous} $valueType')
  String get displayName => id ?? '';

  bool get isPrivate => displayName.startsWith(HTLexicon.privatePrefix);

  final String? classId;

  final HTNamespace? closure;

  final HTSource? source;

  final SourceRange idRange;

  final SourceRange sourceRange;

  bool get isMember => classId != null;

  final bool isExternal;

  final bool isStatic;

  final bool isConst;

  final bool isMutable;

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
      this.isMutable = false});

  dynamic get value => this;

  set value(dynamic newVal) {
    throw HTError.immutable(displayName);
  }

  @mustCallSuper
  void resolve() {}

  bool isOverrideOf(HTDeclaration decl) => false;

  dynamic clone();
}
