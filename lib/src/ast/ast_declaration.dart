import '../declaration.dart';
import 'ast.dart';
import '../type.dart';
import 'ast_interpreter.dart';
import '../errors.dart';

class HTAstDeclaration extends HTDeclaration with AstInterpreterRef {
  @override
  late final HTTypeId? declType;

  ASTNode? initializer;

  HTAstDeclaration(String id, HTAstInterpreter interpreter,
      {dynamic value,
      HTTypeId? declType,
      this.initializer,
      Function? getter,
      Function? setter,
      bool typeInference = false,
      bool isExtern = false,
      bool isNullable = false,
      bool isImmutable = false})
      : super(
          id,
          value: value,
          getter: getter,
          setter: setter,
          isExtern: isExtern,
          isNullable: isNullable,
          isImmutable: isImmutable,
        ) {
    this.interpreter = interpreter;
    var valType = interpreter.typeof(value);
    if (declType == null) {
      if ((typeInference) && (value != null)) {
        this.declType = valType;
      } else {
        this.declType = HTTypeId.ANY;
      }
    } else {
      if (valType.isA(declType) || value == null) {
        this.declType = declType;
      } else {
        throw HTErrorTypeCheck(id, valType.toString(), declType.toString());
      }
    }
  }

  @override
  HTAstDeclaration clone() {
    return HTAstDeclaration(id, interpreter,
        initializer: initializer,
        getter: getter,
        setter: setter,
        declType: declType,
        isExtern: isExtern,
        isNullable: isNullable,
        isImmutable: isImmutable);
  }

  @override
  void initialize() {
    value = interpreter.visitASTNode(initializer!);
  }
}
