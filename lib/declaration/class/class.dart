import '../../grammar/lexicon.dart';
import '../../grammar/semantic.dart';
import '../../error/error.dart';
import '../../source/source.dart';
import '../../interpreter/interpreter.dart';
import '../../type/type.dart';
// import '../declaration.dart';
import '../namespace.dart';
import '../function/function.dart';
import '../instance/instance.dart';
import 'class_declaration.dart';
import 'class_namespace.dart';

/// The Dart implementation of the class declaration in Hetu.
class HTClass extends HTClassDeclaration with HetuRef {
  @override
  String toString() => '${HTLexicon.CLASS} $id';

  var _instanceIndex = 0;
  int get instanceIndex => _instanceIndex++;

  /// The [HTNamespace] for this class,
  /// for searching for static variables.
  final HTClassNamespace namespace;

  /// Super class of this class.
  /// If a class is not extends from any super class, then it is extended of class `Object`
  HTClass? superClass;

  /// Mixined class of this class.
  /// Those mixined class can not have any constructors.
  // final Iterable<HTClass> mixinedClass;
  // final Iterable<HTType> mixinedType;

  /// Implemented classes of this class.
  /// Implements only inherits methods declaration,
  /// and the child must re-define all implements methods,
  /// and the re-definition must be of the same function signature.
  // final Iterable<HTClass> implementedClass;
  // final Iterable<HTType> implementedType;

  /// The instance member variables defined in class definition.
  // final instanceMembers = <String, HTDeclaration>{};

  /// Create a default [HTClass] instance.
  HTClass(Hetu interpreter,
      {String? id,
      String? classId,
      HTNamespace? closure,
      HTSource? source,
      Iterable<HTType> genericParameters = const [],
      HTType? superType,
      Iterable<HTType> withTypes = const [],
      Iterable<HTType> implementsTypes = const [],
      bool isExternal = false,
      bool isAbstract = false,
      this.superClass})
      : namespace = HTClassNamespace(
            id: id, classId: classId, closure: closure, source: source),
        super(
            id: id,
            classId: classId,
            closure: closure,
            source: source,
            genericParameters: genericParameters,
            superType: superType,
            withTypes: withTypes,
            implementsTypes: implementsTypes,
            isExternal: isExternal,
            isAbstract: isAbstract) {
    this.interpreter = interpreter;
  }

  @override
  void resolve() {
    super.resolve();

    if (superType != null) {
      superClass = namespace.memberGet(superType!.id);
    }

    for (final decl in namespace.declarations.values) {
      decl.resolve();
    }

    // for (final decl in instanceMembers.values) {
    //   decl.resolve();
    // }
  }

  @override
  HTClass clone() => HTClass(interpreter,
      id: id,
      classId: classId,
      closure: closure,
      source: source,
      genericParameters: genericParameters,
      superType: superType,
      withTypes: withTypes,
      implementsTypes: implementsTypes,
      isExternal: isExternal,
      isAbstract: isAbstract,
      superClass: superClass);

  /// Create a [HTInstance] of this [HTClass],
  /// will not call constructors
  HTInstance createInstance({List<HTType> typeArgs = const []}) {
    return HTInstance(this, interpreter, typeArgs: typeArgs);
  }

  HTInstance createInstanceFromJson(Map<dynamic, dynamic> jsonObject,
      {List<HTType> typeArgs = const []}) {
    return HTInstance(this, interpreter,
        typeArgs: typeArgs,
        jsonObject:
            jsonObject.map((key, value) => MapEntry(key.toString(), value)));
  }

  @override
  bool contains(String field) {
    final getter = '${SemanticNames.getter}$field';
    final setter = '${SemanticNames.setter}$field';
    final constructor = field != id
        ? '${SemanticNames.constructor}$field'
        : SemanticNames.constructor;

    return namespace.declarations.containsKey(field) ||
        namespace.declarations.containsKey(getter) ||
        namespace.declarations.containsKey(setter) ||
        namespace.declarations.containsKey(constructor);
  }

  /// Get a value of a static member from this [HTClass].
  @override
  dynamic memberGet(String field, {bool recursive = true, bool error = true}) {
    final getter = '${SemanticNames.getter}$field';
    final constructor = field != id
        ? '${SemanticNames.constructor}$field'
        : SemanticNames.constructor;

    // if (isExternal) {
    //   if (namespace.declarations.containsKey(field)) {
    //     final decl = namespace.declarations[field]!;
    //     return decl.value;
    //   } else if (namespace.declarations.containsKey(getter)) {
    //     HTFunction func = namespace.declarations[getter]!.value;
    //     return func.call();
    //   } else if (namespace.declarations.containsKey(constructor)) {
    //     HTFunction func = namespace.declarations[constructor]!.value;
    //     return func;
    //   }
    // } else {
    if (namespace.declarations.containsKey(field)) {
      final decl = namespace.declarations[field]!;
      return decl.value;
    } else if (namespace.declarations.containsKey(getter)) {
      HTFunction func = namespace.declarations[getter]!.value;
      return func.call();
    } else if (namespace.declarations.containsKey(constructor)) {
      return namespace.declarations[constructor]!.value as HTFunction;
    }
    // }

    if (error) {
      throw HTError.undefined(field,
          moduleFullName: interpreter.curModuleFullName,
          line: interpreter.curLine,
          column: interpreter.curColumn);
    }
  }

  /// Assign a value to a static member of this [HTClass].
  @override
  void memberSet(String field, dynamic varValue, {bool error = true}) {
    final setter = '${SemanticNames.setter}$field';

    if (isExternal) {
      final externClass = interpreter.fetchExternalClass(id!);
      externClass.memberSet('$id.$field', varValue);
      return;
    } else if (namespace.declarations.containsKey(field)) {
      final decl = namespace.declarations[field]!;
      decl.value = varValue;
      return;
    } else if (namespace.declarations.containsKey(setter)) {
      final setterFunc = namespace.declarations[setter] as HTFunction;
      setterFunc.call(positionalArgs: [varValue]);
      return;
    }

    throw HTError.undefined(field,
        moduleFullName: interpreter.curModuleFullName,
        line: interpreter.curLine,
        column: interpreter.curColumn);
  }

  /// Call a static function of this [HTClass].
  dynamic invoke(String funcName,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = true}) {
    try {
      final func = memberGet(funcName);

      if (func is HTFunction) {
        return func.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        throw HTError.notCallable(funcName,
            moduleFullName: interpreter.curModuleFullName,
            line: interpreter.curLine,
            column: interpreter.curColumn);
      }
    } catch (error, stackTrace) {
      if (errorHandled) {
        rethrow;
      } else {
        interpreter.handleError(error, externalStackTrace: stackTrace);
      }
    }
  }

  /// Add a instance member declaration to this [HTClass].
  // void defineInstanceMember(String id, HTDeclaration decl,
  //     {bool override = false, bool error = true}) {
  //   if ((!instanceMembers.containsKey(id)) || override) {
  //     instanceMembers[id] = decl;
  //   } else {
  //     if (error) throw HTError.definedRuntime(id);
  //   }
  // }
}
