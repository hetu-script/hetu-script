import '../declaration.dart';
import 'ast.dart';
import '../type.dart';
import 'ast_interpreter.dart';
import '../errors.dart';

class HTAstDecl extends HTDeclaration with AstInterpreterRef {
  @override
  final bool isImmutable;

  var _isInitializing = false;
  var _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  late final HTTypeId? declType;

  ASTNode? initializer;

  HTAstDecl(
    String id,
    HTAstInterpreter interpreter, {
    dynamic value,
    HTTypeId? declType,
    this.initializer,
    Function? getter,
    Function? setter,
    bool typeInference = false,
    bool isExtern = false,
    this.isImmutable = false,
    bool isMember = false,
    bool isStatic = false,
  }) : super(id,
            value: value, getter: getter, setter: setter, isExtern: isExtern, isMember: isMember, isStatic: isStatic) {
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
  void initialize() {
    if (_isInitialized) return;

    if (initializer != null) {
      if (!_isInitializing) {
        _isInitializing = true;
        value = interpreter.visitASTNode(initializer!);
        _isInitialized = true;
      } else {
        throw HTErrorCircleInit(id);
      }
    }

    throw HTErrorInitialize();
  }

  @override
  HTAstDecl clone() => HTAstDecl(id, interpreter,
      initializer: initializer,
      getter: getter,
      setter: setter,
      declType: declType,
      isExtern: isExtern,
      isImmutable: isImmutable);
}
