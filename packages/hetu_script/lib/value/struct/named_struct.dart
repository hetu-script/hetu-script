import '../../source/source.dart';
import '../../declaration/declaration.dart';
import '../../value/namespace/namespace.dart';
import 'struct.dart';
import '../../error/error.dart';
import '../../grammar/lexicon.dart';
import '../../grammar/semantic.dart';
import '../../interpreter/interpreter.dart';
import '../../interpreter/compiler.dart' show GotoInfo;
import '../function/function.dart';

/// Unlike class and function, the declaration of a struct is a value
/// and struct object does not extends from this.
class HTNamedStruct extends HTDeclaration with HetuRef, GotoInfo {
  final String _id;

  @override
  String get id => _id;

  final String? prototypeId;

  HTStruct? _self;

  final int? staticDefinitionIp;

  HTNamedStruct(
    this._id,
    Hetu interpreter,
    String fileName,
    String moduleName,
    HTNamespace closure, {
    this.prototypeId,
    HTSource? source,
    bool isTopLevel = false,
    this.staticDefinitionIp,
    int? definitionIp,
  }) : super(
            id: _id, closure: closure, source: source, isTopLevel: isTopLevel) {
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
      throw HTError.unresolvedNamedStruct(id);
    }
    HTStruct structObj = _self!.clone();
    if (structObj.containsKey(Semantic.constructor)) {
      final constructor =
          structObj.memberGet(Semantic.constructor) as HTFunction;
      constructor.call(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          construct: false);
    }
    // TODO: even if there's none constructor, you can still create a struct through the named arguments
    return structObj;
  }

  @override
  void resolve() {
    super.resolve();
    HTStruct static = interpreter.execute(
        filename: fileName,
        moduleName: moduleName,
        ip: staticDefinitionIp!,
        namespace: closure);
    if (closure != null) {
      if (prototypeId != null) {
        static.prototype = closure!
            .memberGet(prototypeId!, from: closure!.fullName, recursive: true);
      } else if (id != HTLexicon.prototype) {
        static.prototype = closure!.memberGet(HTLexicon.prototype,
            from: closure!.fullName, recursive: true);
      }
    }
    HTStruct self = interpreter.execute(
        filename: fileName,
        moduleName: moduleName,
        ip: definitionIp!,
        namespace: closure);
    self.prototype = static;
    self.declaration = this;
    _self = self;
  }

  @override
  HTStruct get value {
    if (isResolved) {
      return _self!;
    } else {
      throw HTError.unresolvedNamedStruct(id);
    }
  }

  @override
  HTNamedStruct clone() => HTNamedStruct(
        id,
        interpreter,
        fileName,
        moduleName,
        closure!,
        source: source,
        prototypeId: prototypeId,
        isTopLevel: isTopLevel,
        staticDefinitionIp: staticDefinitionIp,
        definitionIp: definitionIp,
      );
}
