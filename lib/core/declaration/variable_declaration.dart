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

  dynamic get value => this;

  set value(dynamic newVal) {
    if (!isMutable || isConst) {
      throw HTError.immutable(id);
    }
  }

  VariableDeclaration(this.id, this.moduleFullName, this.libraryName,
      {this.classId,
      this.isExternal = false,
      this.isStatic = false,
      this.isMutable = false,
      this.isConst = false});
}
