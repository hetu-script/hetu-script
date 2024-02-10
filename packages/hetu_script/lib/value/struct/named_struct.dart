// import '../../source/source.dart';
import '../../declaration/declaration.dart';
import '../../value/namespace/namespace.dart';
import 'struct.dart';
import '../../error/error.dart';
import '../../interpreter/interpreter.dart';
import '../../bytecode/goto_info.dart';
import '../function/function.dart';
import '../../type/type.dart';
import '../../common/internal_identifier.dart';

/// Unlike class and function, the declaration of a struct is a value
/// and struct object does not extends from this.
class HTNamedStruct extends HTDeclaration with InterpreterRef, GotoInfo {
  final String? prototypeId;
  final List<String> mixinIds;

  HTStruct? _self;

  final int? staticDefinitionIp;

  bool _isResolved = false;
  @override
  bool get isResolved => _isResolved;

  HTNamedStruct({
    required String id,
    required HTInterpreter interpreter,
    required String file,
    required String module,
    super.closure,
    super.documentation,
    this.prototypeId,
    this.mixinIds = const [],
    super.source,
    super.isPrivate,
    super.isTopLevel = false,
    this.staticDefinitionIp,
    int? definitionIp,
  }) : super(id: id) {
    this.interpreter = interpreter;
    this.file = file;
    this.module = module;
    ip = definitionIp;
  }

  HTStruct createObject({
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const [],
  }) {
    if (!isResolved) {
      throw HTError.unresolvedNamedStruct(id!);
    }
    if (_self!.containsKey(InternalIdentifier.defaultConstructor)) {
      final constructor =
          _self!.memberGet(InternalIdentifier.defaultConstructor) as HTFunction;
      return constructor.call(
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs,
      );
    } else {
      return _self!.clone();
    }
  }

  @override
  void resolve() {
    if (_isResolved) return;
    HTStruct static = interpreter.execute(
      context: HTContext(
        file: file,
        module: module,
        ip: staticDefinitionIp!,
        namespace: closure != null ? closure as HTNamespace : null,
      ),
    );
    if (closure != null) {
      if (prototypeId != null) {
        static.prototype = closure!.memberGet(prototypeId!,
            from: closure!.fullName, isRecursive: true);
      } else if (id != interpreter.lexicon.globalPrototypeId) {
        static.prototype = interpreter.globalNamespace
            .memberGet(interpreter.lexicon.globalPrototypeId);
      }
    }
    _self = interpreter.execute(
      context: HTContext(
        file: file,
        module: module,
        ip: ip!,
        namespace: closure != null ? closure as HTNamespace : null,
      ),
    );
    _self!.prototype = static;
    _self!.declaration = this;

    if (closure != null) {
      if (mixinIds.isNotEmpty) {
        for (final mixinId in mixinIds) {
          final mixinObj = closure!
              .memberGet(mixinId, from: closure!.fullName, isRecursive: true);
          static.assign(mixinObj);
        }
      }
    }
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
      file: file,
      module: module,
      closure: closure != null ? closure as HTNamespace : null,
      source: source,
      prototypeId: prototypeId,
      isTopLevel: isTopLevel,
      staticDefinitionIp: staticDefinitionIp,
      definitionIp: ip);
}
