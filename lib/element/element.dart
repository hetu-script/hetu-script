import 'package:meta/meta.dart';

import '../error/error.dart';
import '../grammar/semantic.dart';
import '../source/source.dart';
import '../source/source_range.dart';
// import '../type/type.dart';
import 'object.dart';
import 'namespace.dart';

/// Element is a semantic entity in the program that
/// represents things that are declared with a name
/// and hence can be referenced elsewhere in the code.
abstract class HTElement with HTObject {
  final String? id;

  String get name => id ?? (SemanticNames.anonymous + valueType.toString());

  final String? classId;

  final HTNamespace? closure;

  final String? moduleFullName;

  final String? libraryName;

  final HTSource? source;

  final SourceRange idRange;

  final SourceRange sourceRange;

  bool get isMember => classId != null;

  final bool isExternal;

  final bool isStatic;

  final bool isConst;

  final bool isMutable;

  const HTElement(
      {this.id,
      this.classId,
      this.closure,
      this.moduleFullName,
      this.libraryName,
      this.source,
      this.idRange = SourceRange.EMPTY,
      this.sourceRange = SourceRange.EMPTY,
      this.isExternal = false,
      this.isStatic = false,
      this.isConst = false,
      this.isMutable = false});

  dynamic get value => this;

  set value(dynamic newVal) {
    if (!isMutable || isConst) {
      throw HTError.immutable(name);
    }
  }

  @mustCallSuper
  void resolve() {}

  HTElement clone();
}
