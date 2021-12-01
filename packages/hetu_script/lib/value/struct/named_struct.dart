import '../../source/source.dart';
import '../../declaration/declaration.dart';
import '../../declaration/namespace/namespace.dart';
import 'struct.dart';
import '../../error/error.dart';
import '../../grammar/lexicon.dart';
// import '../../grammar/semantic.dart';
import '../../interpreter/interpreter.dart';
import '../../interpreter/compiler.dart' show GotoInfo;

/// Unlike class and function, the declaration of a struct is a value
/// and struct object does not extends from this.
class HTNamedStruct extends HTDeclaration with HetuRef, GotoInfo {
  @override
  final String id;

  final String? prototypeId;

  HTStruct? _static;

  HTStruct? _self;

  var _isResolved = false;

  final int? staticDefinitionIp;

  HTNamedStruct(
    this.id,
    Hetu interpreter,
    String moduleFullName,
    String libraryName,
    HTNamespace closure, {
    this.prototypeId,
    HTSource? source,
    bool isTopLevel = false,
    this.staticDefinitionIp,
    int? definitionIp,
  }) : super(id: id, closure: closure, source: source, isTopLevel: isTopLevel) {
    this.interpreter = interpreter;
    this.moduleFullName = moduleFullName;
    this.libraryName = libraryName;
    this.definitionIp = definitionIp;
  }

  HTStruct createObject() {
    if (!_isResolved) {
      throw HTError.unresolvedNamedStruct(id);
    }

    HTStruct structObj = interpreter.execute(
        moduleFullName: moduleFullName,
        libraryName: libraryName,
        ip: definitionIp!,
        namespace: closure);

    return structObj;
  }

  @override
  void resolve() {
    if (_isResolved) {
      return;
    }

    _static = interpreter.execute(
        moduleFullName: moduleFullName,
        libraryName: libraryName,
        ip: staticDefinitionIp!,
        namespace: closure);

    _self = interpreter.execute(
        moduleFullName: moduleFullName,
        libraryName: libraryName,
        ip: definitionIp!,
        namespace: closure);

    _self!.import(_static!);

    if (closure != null) {
      if (prototypeId != null) {
        _self!.prototype = closure!.memberGet(prototypeId!);
      } else if (id != HTLexicon.prototype) {
        _self!.prototype = closure!.memberGet(HTLexicon.prototype);
      }
    }

    _isResolved = true;
  }

  @override
  HTStruct get value {
    if (_isResolved) {
      return _self!;
    } else {
      throw HTError.unresolvedNamedStruct(id);
    }
  }

  @override
  HTNamedStruct clone() => HTNamedStruct(
        id,
        interpreter,
        moduleFullName,
        libraryName,
        closure!,
        source: source,
        prototypeId: prototypeId,
        isTopLevel: isTopLevel,
        staticDefinitionIp: staticDefinitionIp,
        definitionIp: definitionIp,
      );
}
