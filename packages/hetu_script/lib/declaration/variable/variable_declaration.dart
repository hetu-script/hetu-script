import 'package:meta/meta.dart';

import '../../type/type.dart';
import '../declaration.dart';

class HTVariableDeclaration extends HTDeclaration {
  final HTType? _declType;

  HTType? _resolvedDeclType;

  /// The declared [HTType] of this symbol, will be used to
  /// compare with the value type before compile to
  /// determine wether an value binding (assignment) is legal.
  @override
  HTType? get declType => _resolvedDeclType ?? _declType;

  bool _isResolved = false;
  @override
  bool get isResolved => _isResolved;

  final bool lateFinalize;

  HTVariableDeclaration(
      {required String id,
      super.classId,
      super.closure,
      super.source,
      super.documentation,
      HTType? declType,
      super.isPrivate = false,
      super.isExternal = false,
      super.isStatic = false,
      super.isConst = false,
      super.isMutable = false,
      super.isTopLevel = false,
      super.isField = false,
      this.lateFinalize = false})
      : _declType = declType,
        super(id: id) {
    if (_declType != null && _declType!.isResolved) {
      _resolvedDeclType = _declType!;
    }
  }

  @override
  @mustCallSuper
  void resolve({bool resolveType = true}) {
    if (_isResolved) {
      return;
    }
    if (resolveType && closure != null) {
      if (_declType != null) {
        _resolvedDeclType = _declType!.resolve(closure!);
      }
    }
    _isResolved = true;
  }

  @override
  HTVariableDeclaration clone() => HTVariableDeclaration(
      id: id!,
      classId: classId,
      closure: closure,
      source: source,
      declType: declType,
      isExternal: isExternal,
      isStatic: isStatic,
      isMutable: isMutable,
      isTopLevel: isTopLevel);
}
