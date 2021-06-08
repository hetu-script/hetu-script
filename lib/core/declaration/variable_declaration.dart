import 'package:meta/meta.dart';

import '../../core/namespace/namespace.dart';
import '../../error/errors.dart';

class VariableDeclaration {
  final String id;

  final String? classId;

  final String libraryName;

  final String moduleFullName;

  bool get isMember => classId != null;

  final bool isExternal;

  final bool isStatic;

  final bool isMutable;

  final bool isConst;

  const VariableDeclaration(this.id, this.moduleFullName, this.libraryName,
      {this.classId,
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

  VariableDeclaration clone() =>
      VariableDeclaration(id, moduleFullName, libraryName,
          classId: classId,
          isExternal: isExternal,
          isStatic: isStatic,
          isMutable: isMutable,
          isConst: isConst);
}
