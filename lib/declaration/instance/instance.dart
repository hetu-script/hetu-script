import 'dart:collection';

import '../../error/error.dart';
import '../../grammar/semantic.dart';
import '../../interpreter/abstract_interpreter.dart';
import '../../type/type.dart';
import '../../type/nominal_type.dart';
import '../function/function.dart';
import '../class/class.dart';
import '../class/cast.dart';
import '../namespace.dart';
import '../../object/object.dart';
import 'instance_namespace.dart';

/// The Dart implementation of the instance in Hetu.
/// [HTInstance] carries all decl from its super classes.
/// [HTInstance] inherits all its super classes' [HTTypeID]s.
class HTInstance with HTObject, InterpreterRef {
  final String id;
  final int index;

  @override
  final HTNominalType valueType;

  String get classId => valueType.id;

  /// A [HTInstance] has all members inherited from all super classes,
  /// Key is the id of a super class.
  /// Value is the namespace of that class.
  /// This map keeps the sequence when insertion,
  /// this way when searches for members, the closest super class's
  /// member always found first.
  final LinkedHashMap<String, HTInstanceNamespace> _namespaces =
      LinkedHashMap();

  /// The [HTNamespace] for this instance.
  /// Variables will start from the lowest class,
  /// searching through all super classes.
  HTInstanceNamespace get namespace => _namespaces[classId]!;

  /// Create a default [HTInstance] instance.
  HTInstance(HTClass klass, AbstractInterpreter interpreter,
      {List<HTType> typeArgs = const [], Map<String, dynamic>? jsonObject})
      : id = SemanticNames.instance,
        index = klass.instanceIndex,
        valueType = HTNominalType(klass, typeArgs: typeArgs) {
    this.interpreter = interpreter;

    HTClass? curKlass = klass;
    // final extended = <HTValueType>[];
    HTInstanceNamespace? curNamespace = HTInstanceNamespace(id, this,
        classId: curKlass.id, closure: klass.namespace);
    while (curKlass != null && curNamespace != null) {
      // 继承类成员，所有超类的成员都会分别保存
      for (final key in curKlass.instanceMembers.keys) {
        final decl = curKlass.instanceMembers[key]!;
        // TODO: check if override, and if so, check the type wether fits super's type.
        final clone = decl.clone();
        curNamespace.define(key, clone);

        if (jsonObject != null && jsonObject.containsKey(clone.id)) {
          final value = jsonObject[clone.id];
          clone.value = value;
        }
      }

      _namespaces[curKlass.id!] = curNamespace;

      // if (curKlass.extendedType != null) {
      //   extended.add(curKlass.extendedType!);
      // }
      curKlass = curKlass.superClass;
      if (curKlass != null) {
        curNamespace.next = HTInstanceNamespace(id, this,
            classId: curKlass.id, closure: curKlass.namespace);
      } else {
        curNamespace.next = null;
      }

      curNamespace = curNamespace.next;
    }
  }

  @override
  String toString() {
    final func = memberGet('toString');
    if (func is HTFunction) {
      return func.call();
    } else if (func is Function) {
      return func();
    } else {
      return toJson().toString();
    }
  }

  Map<String, dynamic> toJson() {
    final jsonObject = <String, dynamic>{};

    HTInstanceNamespace? curNamespace = namespace;
    while (curNamespace != null) {
      for (final id in curNamespace.declarations.keys) {
        final decl = curNamespace.declarations[id]!;
        if (jsonObject.containsKey(id)) {
          continue;
        }
        jsonObject[id] = decl.value;
      }
      curNamespace = curNamespace.next;
    }
    return jsonObject;
  }

  @override
  bool contains(String field) {
    for (final space in _namespaces.values) {
      if (space.declarations.containsKey(field) ||
          space.declarations.containsKey('${SemanticNames.getter}$field') ||
          space.declarations.containsKey('${SemanticNames.setter}$field')) {
        return true;
      }
    }
    return false;
  }

  /// [HTInstance] overrided [HTObject]'s [memberGet],
  /// with a new named parameter [cast].
  /// If [cast] is provided, then the instance will
  /// only search that [cast]'s corresponed [HTInstanceNamespace].
  @override
  dynamic memberGet(String field, {String? cast, bool error = true}) {
    final getter = '${SemanticNames.getter}$field';

    if (cast == null) {
      for (final space in _namespaces.values) {
        if (space.declarations.containsKey(field)) {
          final value = space.declarations[field]!.value;
          if (value is HTFunction &&
              value.category != FunctionCategory.literal) {
            value.context = namespace;
          }
          return value;
        } else if (space.declarations.containsKey(getter)) {
          HTFunction func = space.declarations[getter]!.value;
          func.context = namespace;
          return func.call();
        }
      }
    } else {
      final space = _namespaces[cast]!;
      if (space.declarations.containsKey(field)) {
        final value = space.declarations[field]!.value;
        if (value is HTFunction && value.category != FunctionCategory.literal) {
          value.context = _namespaces[classId];
        }
        return value;
      } else if (space.declarations.containsKey(getter)) {
        HTFunction func = space.declarations[getter]!.value;
        func.context = _namespaces[classId];
        return func.call();
      }
    }

    if (error) {
      throw HTError.undefined(field);
    }
  }

  /// [HTInstance] overrided [HTObject]'s [memberSet],
  /// with a new named parameter [cast].
  /// If [cast] is provided, then the instance will
  /// only search that [cast]'s corresponed [HTInstanceNamespace].
  @override
  void memberSet(String field, dynamic varValue,
      {String? cast, bool error = true}) {
    final setter = '${SemanticNames.setter}$field';

    if (cast == null) {
      for (final space in _namespaces.values) {
        if (space.declarations.containsKey(field)) {
          var decl = space.declarations[field]!;
          decl.value = varValue;
          return;
        } else if (space.declarations.containsKey(setter)) {
          HTFunction method = space.declarations[setter]!.value;
          method.context = namespace;
          method.call(positionalArgs: [varValue]);
          return;
        }
      }
    } else {
      if (!_namespaces.containsKey(cast)) {
        throw HTError.notSuper(cast, classId);
      }

      final space = _namespaces[cast]!;
      if (space.declarations.containsKey(field)) {
        var decl = space.declarations[field]!;
        decl.value = varValue;
        return;
      } else if (space.declarations.containsKey(setter)) {
        final method = space.declarations[setter]! as HTFunction;
        method.context = _namespaces[cast];
        method.call(positionalArgs: [varValue]);
        return;
      }
    }

    throw HTError.undefined(field);
  }

  /// Call a member function of this [HTInstance].
  dynamic invoke(String funcName,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = true}) {
    try {
      HTFunction func = memberGet(funcName);
      return func.call(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);
    } catch (error, stack) {
      if (errorHandled) {
        rethrow;
      } else {
        interpreter.handleError(error, stack);
      }
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is HTCast) {
      return this == other.object;
    }
    return hashCode == other.hashCode;
  }
}
