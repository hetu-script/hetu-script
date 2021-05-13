import '../core/variable.dart';
import '../type_system/type.dart';
import '../error/errors.dart';
import 'ast.dart';
import 'analyzer.dart';

class HTAstVariable extends HTVariable {
  @override
  final HTAnalyzer interpreter;

  @override
  final bool isImmutable;

  HTType? _declType;

  @override
  HTType get declType => _declType ?? HTType.ANY;

  final bool isDynamic;

  var _isInitializing = false;

  AstNode? initializer;

  HTAstVariable(String id, this.interpreter,
      {String? classId,
      dynamic value,
      HTType? declType,
      this.initializer,
      Function? getter,
      Function? setter,
      this.isDynamic = false,
      bool isExternal = false,
      this.isImmutable = false,
      bool isMember = false,
      bool isStatic = false})
      : super(id, interpreter,
            classId: classId,
            value: value,
            getter: getter,
            setter: setter,
            isExternal: isExternal,
            isStatic: isStatic) {
    _declType = declType;
  }

  @override
  void initialize() {
    if (isInitialized) return;

    if (initializer != null) {
      if (!_isInitializing) {
        _isInitializing = true;
        final initVal = interpreter.visitASTNode(initializer!);
        value = initVal;
        _isInitializing = false;
      } else {
        throw HTError.circleInit(id);
      }
    } else {
      value = null; // null 也要 assign 一下，因为需要类型检查
    }
  }

  @override
  set value(dynamic value) {
    if (_declType != null) {
      final encapsulation = interpreter.encapsulate(value);
      final valueType = encapsulation.valueType;
      if (valueType.isNotA(_declType)) {
        throw HTError.type(id, valueType.toString(), declType.toString());
      }
    } else {
      if (!isDynamic && value != null) {
        _declType = interpreter.encapsulate(value).valueType;
      } else {
        _declType = HTType.ANY;
      }
    }

    super.value = value;
  }

  @override
  HTAstVariable clone() => HTAstVariable(id, interpreter,
      classId: classId,
      value: value,
      initializer: initializer,
      getter: getter,
      setter: setter,
      declType: declType,
      isExternal: isExternal,
      isImmutable: isImmutable);
}
