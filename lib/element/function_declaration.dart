import '../../grammar/semantic.dart';
import 'declaration.dart';

class FunctionDeclaration extends Declaration {
  final String declId;

  final FunctionCategory category;

  Function? externalFunc;

  final String? externalTypeId;

  final bool isVariadic;

  final int minArity;

  final int maxArity;

  FunctionDeclaration(String id, String moduleFullName, String libraryName,
      {this.declId = '',
      String? classId,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
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

  @override
  FunctionDeclaration clone() =>
      FunctionDeclaration(id, moduleFullName, libraryName,
          declId: declId,
          classId: classId,
          isExternal: isExternal,
          isStatic: isStatic,
          isConst: isConst,
          category: category,
          externalFunc: externalFunc,
          externalTypeId: externalTypeId,
          isVariadic: isVariadic,
          minArity: minArity,
          maxArity: maxArity);
}
