import '../../source/source.dart';
import '../declaration.dart';
import '../namespace/namespace.dart';
import '../../object/struct/struct.dart';
import '../../object/variable/variable.dart';

class HTStructDeclaration extends HTDeclaration {
  @override
  final String id;

  final fields = <HTVariable>[];

  final String? _unresolvedPrototypeId;

  HTStruct? prototype;

  HTStruct? _self;

  var _isResolved = false;

  HTStructDeclaration(this.id,
      {String? classId,
      HTNamespace? closure,
      HTSource? source,
      String? prototypeId,
      this.prototype,
      bool isTopLevel = false,
      bool isExported = false})
      : _unresolvedPrototypeId = prototypeId,
        super(
            id: id,
            classId: classId,
            closure: closure,
            source: source,
            isTopLevel: isTopLevel,
            isExported: isExported);

  @override
  void resolve() {
    if (_isResolved) {
      return;
    }
    _isResolved = true;
    if (closure != null && _unresolvedPrototypeId != null) {
      prototype = closure!.memberGet(_unresolvedPrototypeId!);
    }
    _self = HTStruct(prototype: prototype);
    for (final decl in fields) {
      decl.resolve();
      final value = decl.value;
      _self!.define(decl.id, value);
    }
  }

  @override
  HTStruct get value => HTStruct(prototype: _self);

  @override
  HTStructDeclaration clone() => HTStructDeclaration(id,
      classId: classId,
      closure: closure,
      source: source,
      prototypeId: _unresolvedPrototypeId,
      prototype: prototype,
      isTopLevel: isTopLevel,
      isExported: isExported);
}
