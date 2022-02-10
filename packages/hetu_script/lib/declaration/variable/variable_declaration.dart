import 'package:meta/meta.dart';

import '../../source/source.dart';
import '../../type/type.dart';
import '../declaration.dart';
import '../namespace/declaration_namespace.dart';

class HTVariableDeclaration extends HTDeclaration {
  final HTType? _declType;

  HTType? _resolvedDeclType;

  /// The declared [HTType] of this symbol, will be used to
  /// compare with the value type before compile to
  /// determine wether an value binding (assignment) is legal.
  HTType? get declType => _resolvedDeclType ?? _declType;

  bool _isResolved = false;
  @override
  bool get isResolved => _isResolved;

  final bool lateFinalize;

  HTVariableDeclaration(String id,
      {String? classId,
      HTDeclarationNamespace? closure,
      HTSource? source,
      HTType? declType,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isMutable = false,
      bool isTopLevel = false,
      this.lateFinalize = false})
      : _declType = declType,
        super(
            id: id,
            classId: classId,
            closure: closure,
            source: source,
            isExternal: isExternal,
            isStatic: isStatic,
            isConst: isConst,
            isMutable: isMutable,
            isTopLevel: isTopLevel) {
    if (_declType != null && _declType!.isResolved) {
      _resolvedDeclType = _declType!;
    }
  }

  @override
  @mustCallSuper
  void resolve() {
    // TODO: should move these code to compiler time
    // if (_isResolved) {
    //   return;
    // }
    // if (closure != null && _declType != null) {
    //   _resolvedDeclType = _declType!.resolve(closure!);
    // } else {
    //   _resolvedDeclType = HTType.any;
    // }
    _isResolved = true;
  }

  @override
  HTVariableDeclaration clone() => HTVariableDeclaration(id!,
      classId: classId,
      closure: closure,
      source: source,
      declType: declType,
      isExternal: isExternal,
      isStatic: isStatic,
      isMutable: isMutable,
      isTopLevel: isTopLevel);
}
