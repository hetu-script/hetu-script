import '../implementation/variable.dart';
import '../implementation/type.dart';
import '../implementation/errors.dart';
import 'ast.dart';
import 'ast_analyzer.dart';

class HTAstVariable extends HTVariable with AnalyzerRef {
  final bool isDynamic;

  @override
  final bool isImmutable;

  var _isInitializing = false;

  HTType? _declType;
  HTType get declType => _declType!;

  AstNode? initializer;

  HTAstVariable(String id, HTAnalyzer interpreter,
      {String? classId,
      dynamic value,
      HTType? declType,
      this.initializer,
      Function? getter,
      Function? setter,
      this.isDynamic = false,
      bool isExtern = false,
      this.isImmutable = false,
      bool isMember = false,
      bool isStatic = false})
      : super(id,
            classId: classId,
            value: value,
            getter: getter,
            setter: setter,
            isExtern: isExtern,
            isStatic: isStatic) {
    this.interpreter = interpreter;
    if (initializer == null && declType == null) {
      _declType = HTType.ANY;
    }
  }

  @override
  void initialize() {
    if (isInitialized) return;

    if (initializer != null) {
      if (!_isInitializing) {
        _isInitializing = true;
        final initVal = interpreter.visitASTNode(initializer!);
        assign(initVal);
        _isInitializing = false;
      } else {
        throw HTError.circleInit(id);
      }
    } else {
      assign(null); // null 也要 assign 一下，因为需要类型检查
    }
  }

  @override
  void assign(dynamic value) {
    if (_declType != null) {
      final encapsulation = interpreter.encapsulate(value);
      final valueType = encapsulation.objectType;
      if (valueType.isNotA(_declType!)) {
        throw HTError.type(id, valueType.toString(), _declType.toString());
      }
    } else {
      if (!isDynamic && value != null) {
        _declType = interpreter.encapsulate(value).objectType;
      } else {
        _declType = HTType.ANY;
      }
    }

    super.assign(value);
  }

  @override
  HTAstVariable clone() => HTAstVariable(id, interpreter,
      classId: classId,
      value: value,
      initializer: initializer,
      getter: getter,
      setter: setter,
      declType: declType,
      isExtern: isExtern,
      isImmutable: isImmutable);
}
