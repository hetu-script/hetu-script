import '../../grammar/lexicon.dart';
import '../../grammar/semantic.dart';
import '../../error/error.dart';
import '../../source/source.dart';
import '../../interpreter/abstract_interpreter.dart';
import '../../type/type.dart';
// import '../declaration.dart';
import '../../declaration/namespace/namespace.dart';
import '../function/function.dart';
import '../../value/instance/instance.dart';
import '../../declaration/class/class_declaration.dart';
import '../entity.dart';
import '../../declaration/generic/generic_type_parameter.dart';

/// The Dart implementation of the class declaration in Hetu.
class HTClass extends HTClassDeclaration with HTEntity, InterpreterRef {
  @override
  String toString() => '${HTLexicon.CLASS} $id';

  var _instanceIndex = 0;
  int get instanceIndex => _instanceIndex++;

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

  /// Create a default [HTClass] instance.
  HTClass(HTAbstractInterpreter interpreter,
      {String? id,
      String? classId,
      HTNamespace? closure,
      HTSource? source,
      List<HTGenericTypeParameter> genericTypeParameters = const [],
      HTType? superType,
      Iterable<HTType> withTypes = const [],
      Iterable<HTType> implementsTypes = const [],
      bool isExternal = false,
      bool isAbstract = false,
      bool isEnum = false,
      bool isExported = false,
      this.superClass})
      : super(
            id: id,
            classId: classId,
            closure: closure,
            source: source,
            genericTypeParameters: genericTypeParameters,
            superType: superType,
            withTypes: withTypes,
            implementsTypes: implementsTypes,
            isExternal: isExternal,
            isAbstract: isAbstract,
            isEnum: isEnum,
            isExported: isExported) {
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
      genericTypeParameters: genericTypeParameters,
      superType: superType,
      withTypes: withTypes,
      implementsTypes: implementsTypes,
      isExternal: isExternal,
      isAbstract: isAbstract,
      isEnum: isEnum,
      isExported: isExported,
      superClass: superClass);

  /// Create a [HTInstance] of this [HTClass],
  /// will not call constructors
  // HTInstance createInstance({List<HTType> typeArgs = const []}) {
  //   return HTInstance(this, interpreter, typeArgs: typeArgs);
  // }

  // HTInstance createInstanceFromJson(Map<dynamic, dynamic> jsonObject,
  //     {List<HTType> typeArgs = const []}) {
  //   return HTInstance(this, interpreter,
  //       typeArgs: typeArgs,
  //       jsonObject:
  //           jsonObject.map((key, value) => MapEntry(key.toString(), value)));
  // }

  @override
  bool contains(String varName) {
    final getter = '${SemanticNames.getter}$varName';
    final setter = '${SemanticNames.setter}$varName';
    final constructor = varName != id
        ? '${SemanticNames.constructor}$varName'
        : SemanticNames.constructor;

    return namespace.declarations.containsKey(varName) ||
        namespace.declarations.containsKey(getter) ||
        namespace.declarations.containsKey(setter) ||
        namespace.declarations.containsKey(constructor);
  }

  /// Get a value of a static member from this [HTClass].
  @override
  dynamic memberGet(String varName,
      {bool recursive = true, bool error = true}) {
    final getter = '${SemanticNames.getter}$varName';
    final constructor = varName != id
        ? '${SemanticNames.constructor}$varName'
        : SemanticNames.constructor;

    if (namespace.declarations.containsKey(varName)) {
      final decl = namespace.declarations[varName]!;
      if (isExternal) {
        return decl.value;
      } else {
        if (decl.isStatic) {
          return decl.value;
        }
      }
    } else if (namespace.declarations.containsKey(getter)) {
      final decl = namespace.declarations[getter]!;
      final func = decl as HTFunction;
      if (isExternal) {
        return func.call();
      } else {
        if (decl.isStatic) {
          return func.call();
        }
      }
    } else if (namespace.declarations.containsKey(constructor)) {
      return namespace.declarations[constructor]!.value as HTFunction;
    }

    if (error) {
      throw HTError.undefined(varName,
          moduleFullName: interpreter.curModuleFullName,
          line: interpreter.curLine,
          column: interpreter.curColumn);
    }
  }

  /// Assign a value to a static member of this [HTClass].
  @override
  void memberSet(String varName, dynamic varValue) {
    final setter = '${SemanticNames.setter}$varName';

    if (isExternal) {
      final externClass = interpreter.fetchExternalClass(id!);
      externClass.memberSet('$id.$varName', varValue);
      return;
    } else {
      if (namespace.declarations.containsKey(varName)) {
        final decl = namespace.declarations[varName]!;
        if (decl.isStatic) {
          decl.value = varValue;
          return;
        }
      } else if (namespace.declarations.containsKey(setter)) {
        final decl = namespace.declarations[setter]!;
        if (decl.isStatic) {
          final setterFunc = decl as HTFunction;
          setterFunc.call(positionalArgs: [varValue]);
          return;
        }
      }
    }

    throw HTError.undefined(varName,
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
