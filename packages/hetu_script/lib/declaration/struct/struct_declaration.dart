import '../../source/source.dart';
import '../declaration.dart';
import '../namespace/namespace.dart';
import '../../object/struct/struct.dart';
import '../../error/error.dart';

/// A prototype based dynamic object type.
/// You can define and delete members in runtime.
/// Use prototype to create and extends from other object.
/// Can be named or anonymous.
/// Unlike class, you have to use 'this' to
/// access struct member within its own methods
class HTStructDeclaration extends HTDeclaration {
  @override
  final String? id;

  final String? _unresolvedPrototypeId;

  HTNamespace namespace;

  HTStruct? _self;

  var _isResolved = false;

  HTStructDeclaration(this.namespace,
      {this.id,
      String? classId,
      HTNamespace? closure,
      HTSource? source,
      String? prototypeId,
      bool isTopLevel = false,
      bool isExported = false})
      : _unresolvedPrototypeId = prototypeId,
        super(
            id: id,
            classId: classId,
            closure: namespace.closure,
            source: source,
            isTopLevel: isTopLevel,
            isExported: isExported);

  @override
  void resolve() {
    if (_isResolved) {
      return;
    }
    _isResolved = true;
    HTStruct? prototype;
    if (closure != null && _unresolvedPrototypeId != null) {
      prototype = closure!.memberGet(_unresolvedPrototypeId!);
    }
    _self = HTStruct(id: id, prototype: prototype);
    for (final decl in namespace.declarations.values) {
      decl.resolve();
      final value = decl.value;
      _self!.define(decl.id!, value);
    }
  }

  @override
  HTStruct get value {
    if (_isResolved) {
      return _self!;
    } else {
      throw HTError.unresolvedNamedStruct();
    }
  }

  @override
  HTStructDeclaration clone() => HTStructDeclaration(namespace.clone(),
      id: id,
      classId: classId,
      closure: closure,
      source: source,
      prototypeId: _unresolvedPrototypeId,
      isTopLevel: isTopLevel,
      isExported: isExported);
}
