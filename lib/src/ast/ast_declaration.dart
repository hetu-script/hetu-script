import '../declaration.dart';
import 'ast.dart';
import '../type.dart';
import 'ast_interpreter.dart';
import '../errors.dart';

class HTAstDecl extends HTDeclaration with AstInterpreterRef {
  final bool isDynamic;

  @override
  final bool isImmutable;

  var _isInitializing = false;
  var _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  late final HTTypeId? declType;

  ASTNode? initializer;

  HTAstDecl(String id, HTAstInterpreter interpreter,
      {dynamic value,
      HTTypeId? declType,
      this.initializer,
      Function? getter,
      Function? setter,
      this.isDynamic = false,
      bool isExtern = false,
      this.isImmutable = false,
      bool isMember = false,
      bool isStatic = false})
      : super(id,
            value: value, getter: getter, setter: setter, isExtern: isExtern, isMember: isMember, isStatic: isStatic) {
    this.interpreter = interpreter;
    if (initializer == null && declType == null) {
      declType = HTTypeId.ANY;
    }
  }

  @override
  void initialize() {
    if (_isInitialized) return;

    if (initializer != null) {
      if (!_isInitializing) {
        _isInitializing = true;
        final initVal = interpreter.visitASTNode(initializer!);
        assign(initVal);
        _isInitializing = false;
      } else {
        throw HTErrorCircleInit(id);
      }
    } else {
      assign(null); // null 也要 assign 一下，因为需要类型检查
    }
  }

  @override
  void assign(dynamic value) {
    if (isImmutable) {
      throw HTErrorImmutable(id);
    }

    var valType = interpreter.typeof(value);
    if (declType == null) {
      if (!isDynamic && value != null) {
        declType = valType;
      } else {
        declType = HTTypeId.ANY;
      }
      if (!_isInitialized) {
        _isInitialized = true;
      }
    } else if (valType.isNotA(declType)) {
      throw HTErrorTypeCheck(id, valType.toString(), declType.toString());
    }
    this.value = value;
  }

  @override
  HTAstDecl clone() => HTAstDecl(id, interpreter,
      value: value,
      initializer: initializer,
      getter: getter,
      setter: setter,
      declType: declType,
      isExtern: isExtern,
      isImmutable: isImmutable);
}
