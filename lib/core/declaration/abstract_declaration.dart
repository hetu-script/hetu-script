abstract class AbstractDeclaration {
  final String id;

  final String? classId;

  bool get isMember => classId != null;

  final bool isExternal;

  dynamic get value;

  set value(dynamic newVal);

  AbstractDeclaration(this.id, {this.classId, this.isExternal = false});
}
