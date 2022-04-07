import '../../source/source.dart';
import '../../declaration/declaration.dart';
import '../../value/namespace/namespace.dart';
import 'struct.dart';
import '../../error/error.dart';
import '../../grammar/constant.dart';
import '../../interpreter/interpreter.dart';
import '../../bytecode/goto_info.dart';
import '../function/function.dart';

/// Unlike class and function, the declaration of a struct is a value
/// and struct object does not extends from this.
class HTNamedStruct extends HTDeclaration with InterpreterRef, GotoInfo {
  final String? prototypeId;

  HTStruct? _self;

  final int? staticDefinitionIp;

  bool _isResolved = false;

  @override
  bool get isResolved => _isResolved;

  HTNamedStruct({
    required String id,
    required HTInterpreter interpreter,
    required String fileName,
    required String moduleName,
    HTNamespace? closure,
    this.prototypeId,
    HTSource? source,
    bool isTopLevel = false,
    this.staticDefinitionIp,
    int? definitionIp,
  }) : super(id: id, closure: closure, source: source, isTopLevel: isTopLevel) {
    this.interpreter = interpreter;
    this.fileName = fileName;
    this.moduleName = moduleName;
    this.definitionIp = definitionIp;
  }

  HTStruct createObject({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) {
    if (!isResolved) {
      throw HTError.unresolvedNamedStruct(id!);
    }
    HTStruct structObj = _self!.clone();
    if (structObj.containsKey(InternalIdentifier.defaultConstructor)) {
      final constructor = structObj
          .memberGet(InternalIdentifier.defaultConstructor) as HTFunction;
      constructor.call(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          construct: false);
    }
    return structObj;
  }

  @override
  void resolve() {
    super.resolve();
    HTStruct static = interpreter.execute(
        filename: fileName,
        moduleName: moduleName,
        ip: staticDefinitionIp!,
        namespace: closure != null ? closure as HTNamespace : null);
    if (closure != null) {
      if (prototypeId != null) {
        static.prototype = closure!
            .memberGet(prototypeId!, from: closure!.fullName, recursive: true);
      } else if (id != interpreter.lexicon.globalPrototypeId) {
        static.prototype = interpreter.globalNamespace
            .memberGet(interpreter.lexicon.globalPrototypeId);
      }
    }
    HTStruct self = interpreter.execute(
        filename: fileName,
        moduleName: moduleName,
        ip: definitionIp!,
        namespace: closure != null ? closure as HTNamespace : null);
    self.prototype = static;
    self.declaration = this;
    _self = self;
    _isResolved = true;
  }

  @override
  HTStruct get value {
    if (isResolved) {
      return _self!;
    } else {
      throw HTError.unresolvedNamedStruct(id!);
    }
  }

  @override
  HTNamedStruct clone() => HTNamedStruct(
      id: id!,
      interpreter: interpreter,
      fileName: fileName,
      moduleName: moduleName,
      closure: closure != null ? closure as HTNamespace : null,
      source: source,
      prototypeId: prototypeId,
      isTopLevel: isTopLevel,
      staticDefinitionIp: staticDefinitionIp,
      definitionIp: definitionIp);
}
