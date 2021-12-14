import 'dart:collection';

import 'package:quiver/core.dart';

import '../../error/error.dart';
import '../../grammar/semantic.dart';
import '../../type/type.dart';
import '../../type/nominal_type.dart';
import '../function/function.dart';
import '../class/class.dart';
import 'cast.dart';
import '../../declaration/namespace/namespace.dart';
import '../entity.dart';
import 'instance_namespace.dart';
import '../../interpreter/abstract_interpreter.dart';
import '../../grammar/lexicon.dart';

/// The Dart implementation of the instance in Hetu.
/// [HTInstance] carries all decl from its super classes.
/// [HTInstance] inherits all its super classes' [HTTypeID]s.
class HTInstance with HTEntity, InterpreterRef {
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
  HTInstance(HTClass klass, HTAbstractInterpreter interpreter,
      {List<HTType> typeArgs = const [], Map<String, dynamic>? jsonObject})
      : index = klass.instanceIndex,
        valueType = HTNominalType(klass, typeArgs: typeArgs) {
    this.interpreter = interpreter;

    HTClass? curKlass = klass;
    // final extended = <HTValueType>[];
    HTInstanceNamespace? curNamespace = HTInstanceNamespace(
        Semantic.instance, this,
        classId: curKlass.id, closure: klass.namespace);
    while (curKlass != null && curNamespace != null) {
      // 继承类成员，所有超类的成员都会分别保存
      for (final key in curKlass.namespace.declarations.keys) {
        final decl = curKlass.namespace.declarations[key]!;
        if (decl.isStatic) {
          continue;
        }
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
        curNamespace.next = HTInstanceNamespace(Semantic.instance, this,
            classId: curKlass.id, closure: curKlass.namespace);
      } else {
        curNamespace.next = null;
      }

      curNamespace = curNamespace.next;
    }
  }

  String getTypeString() {
    // TODO: type args
    return '${HTLexicon.instanceof} $classId';
  }

  @override
  String toString() {
    final func = memberGet('toString', error: false);
    if (func is HTFunction) {
      return func.call();
    } else if (func is Function) {
      return func();
    } else {
      return getTypeString();
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
  bool contains(String varName) {
    for (final space in _namespaces.values) {
      if (space.declarations.containsKey(varName) ||
          space.declarations.containsKey('${Semantic.getter}$varName') ||
          space.declarations.containsKey('${Semantic.setter}$varName')) {
        return true;
      }
    }
    return false;
  }

  /// [HTInstance] overrided [HTEntity]'s [memberGet],
  /// with a new named parameter [cast].
  /// If [cast] is provided, then the instance will
  /// only search that [cast]'s corresponed [HTInstanceNamespace].
  @override
  dynamic memberGet(String varName, {String? cast, bool error = true}) {
    final getter = '${Semantic.getter}$varName';

    if (cast == null) {
      for (final space in _namespaces.values) {
        if (space.declarations.containsKey(varName)) {
          final value = space.declarations[varName]!.value;
          if (value is HTFunction &&
              value.category != FunctionCategory.literal) {
            value.namespace = namespace;
            value.instance = this;
          }
          return value;
        } else if (space.declarations.containsKey(getter)) {
          HTFunction func = space.declarations[getter]!.value;
          func.namespace = namespace;
          return func.call();
        }
      }
    } else {
      final space = _namespaces[cast]!;
      if (space.declarations.containsKey(varName)) {
        final value = space.declarations[varName]!.value;
        if (value is HTFunction && value.category != FunctionCategory.literal) {
          value.namespace = _namespaces[classId];
        }
        return value;
      } else if (space.declarations.containsKey(getter)) {
        HTFunction func = space.declarations[getter]!.value;
        func.namespace = _namespaces[classId];
        return func.call();
      }
    }

    if (error) {
      throw HTError.undefined(varName);
    }
  }

  /// [HTInstance] overrided [HTEntity]'s [memberSet],
  /// with a new named parameter [cast].
  /// If [cast] is provided, then the instance will
  /// only search that [cast]'s corresponed [HTInstanceNamespace].
  @override
  void memberSet(String varName, dynamic varValue,
      {String? cast, bool error = true}) {
    final setter = '${Semantic.setter}$varName';

    if (cast == null) {
      for (final space in _namespaces.values) {
        if (space.declarations.containsKey(varName)) {
          var decl = space.declarations[varName]!;
          decl.value = varValue;
          return;
        } else if (space.declarations.containsKey(setter)) {
          HTFunction method = space.declarations[setter]!.value;
          method.namespace = namespace;
          method.call(positionalArgs: [varValue]);
          return;
        }
      }
    } else {
      if (!_namespaces.containsKey(cast)) {
        throw HTError.notSuper(cast, classId);
      }

      final space = _namespaces[cast]!;
      if (space.declarations.containsKey(varName)) {
        var decl = space.declarations[varName]!;
        decl.value = varValue;
        return;
      } else if (space.declarations.containsKey(setter)) {
        final method = space.declarations[setter]! as HTFunction;
        method.namespace = _namespaces[cast];
        method.call(positionalArgs: [varValue]);
        return;
      }
    }

    throw HTError.undefined(varName);
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
    } catch (error, stackTrace) {
      if (errorHandled) {
        rethrow;
      } else {
        interpreter.handleError(error, externalStackTrace: stackTrace);
      }
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is HTCast) {
      return this == other.object;
    } else {
      return hashCode == other.hashCode;
    }
  }

  @override
  int get hashCode {
    final hashList = <int>[];
    hashList.add(classId.hashCode);
    hashList.add(index.hashCode);
    final hash = hashObjects(hashList);
    return hash;
  }
}
