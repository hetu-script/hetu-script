import 'package:meta/meta.dart';

import 'namespace.dart';
import '../../error/error.dart';
import '../source/source.dart';
import '../source/source_range.dart';
// import '../type/type.dart';
// import 'object.dart';

/// Element is a semantic entity in the program that
/// represents things that are declared with a name
/// and hence can be referenced elsewhere in the code.
abstract class HTElement {
  final String id;

  final String? classId;

  final String moduleFullName;

  final String libraryName;

  final HTSource? source;

  final SourceRange idRange;

  bool get isMember => classId != null;

  final bool isExternal;

  final bool isStatic;

  final bool isConst;

  final bool isMutable;

  final HTNamespace? closure;

  const HTElement(this.id, this.moduleFullName, this.libraryName,
      {this.source,
      this.idRange = SourceRange.EMPTY,
      this.classId,
      this.isExternal = false,
      this.isStatic = false,
      this.isConst = false,
      this.isMutable = false,
      this.closure});

  dynamic get value => this;

  set value(dynamic newVal) {
    if (!isMutable || isConst) {
      throw HTError.immutable(id);
    }
  }

  @mustCallSuper
  void resolve() {}

  HTElement clone();
}
