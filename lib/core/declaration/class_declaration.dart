import 'variable_declaration.dart';

class ClassDeclaration extends VariableDeclaration {
  final bool isAbstract;

  ClassDeclaration(String id, String moduleFullName, String libraryName,
      {String? classId, bool isExternal = false, this.isAbstract = false})
      : super(id, moduleFullName, libraryName,
            classId: classId, isExternal: isExternal);
}
