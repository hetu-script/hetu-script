import '../../grammar/semantic.dart';
import 'variable_declaration.dart';

class FunctionDeclaration extends VariableDeclaration {
  final String? declId;

  final FunctionCategory category;

  Function? externalFunc;

  final String? externalTypeId;

  final bool isVariadic;

  final int minArity;

  final int maxArity;

  FunctionDeclaration(String id, String moduleFullName, String libraryName,
      {String? classId,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      this.declId,
      this.category = FunctionCategory.normal,
      this.externalFunc,
      this.externalTypeId,
      this.isVariadic = false,
      this.minArity = 0,
      this.maxArity = 0})
      : super(id, moduleFullName, libraryName,
            classId: classId,
            isExternal: isExternal,
            isStatic: isStatic,
            isConst: isConst);
}
