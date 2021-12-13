import 'package:meta/meta.dart';

import '../../source/source.dart';
import '../../type/type.dart';
import '../declaration.dart';
import '../namespace/namespace.dart';

class HTVariableDeclaration extends HTDeclaration {
  final String _id;

  @override
  String get id => _id;

  final HTType? _declType;

  HTType? _resolvedDeclType;

  /// The declared [HTType] of this symbol, will be used to
  /// compare with the value type before compile to
  /// determine wether an value binding (assignment) is legal.
  HTType? get declType => _resolvedDeclType ?? _declType;

  bool _isResolved = false;
  @override
  bool get isResolved => _isResolved;

  HTVariableDeclaration(this._id,
      {String? classId,
      HTNamespace? closure,
      HTSource? source,
      HTType? declType,
      bool isExternal = false,
      bool isStatic = false,
      bool isMutable = false,
      bool isTopLevel = false})
      : _declType = declType,
        super(
            id: _id,
            classId: classId,
            closure: closure,
            source: source,
            isExternal: isExternal,
            isStatic: isStatic,
            isMutable: isMutable,
            isTopLevel: isTopLevel) {
    if (_declType != null && _declType!.isResolved) {
      _resolvedDeclType = _declType!;
    }
  }

  @override
  @mustCallSuper
  void resolve() {
    if (closure != null && _declType != null) {
      _resolvedDeclType = _declType!.resolve(closure!);
    } else {
      _resolvedDeclType = HTType.any;
    }
    _isResolved = true;
  }

  @override
  HTVariableDeclaration clone() => HTVariableDeclaration(id,
      classId: classId,
      closure: closure,
      source: source,
      declType: declType,
      isExternal: isExternal,
      isStatic: isStatic,
      isMutable: isMutable,
      isTopLevel: isTopLevel);
}
