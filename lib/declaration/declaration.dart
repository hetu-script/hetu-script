import 'package:meta/meta.dart';

import 'namespace.dart';
import '../../error/error.dart';
import '../source/source.dart';
import '../source/source_range.dart';

class Declaration {
  final String id;

  final String? classId;

  final String libraryName;

  final String moduleFullName;

  final HTSource? source;

  final SourceRange idRange;

  bool get isMember => classId != null;

  final bool isExternal;

  final bool isStatic;

  final bool isMutable;

  final bool isConst;

  const Declaration(this.id, this.moduleFullName, this.libraryName,
      {this.source,
      this.idRange = SourceRange.EMPTY,
      this.classId,
      this.isExternal = false,
      this.isStatic = false,
      this.isMutable = false,
      this.isConst = false});

  dynamic get value => this;

  set value(dynamic newVal) {
    if (!isMutable || isConst) {
      throw HTError.immutable(id);
    }
  }

  @mustCallSuper
  void resolve(HTNamespace namespace) {}

  Declaration clone() => Declaration(id, moduleFullName, libraryName,
      classId: classId,
      isExternal: isExternal,
      isStatic: isStatic,
      isMutable: isMutable,
      isConst: isConst);
}
