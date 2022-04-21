import 'dart:collection';

import 'package:quiver/core.dart';

import '../../error/error.dart';
import '../../grammar/constant.dart';
import '../../type/type.dart';
import '../../type/nominal.dart';
import '../function/function.dart';
import '../class/class.dart';
import 'cast.dart';
import '../../value/namespace/namespace.dart';
import '../entity.dart';
import 'instance_namespace.dart';
import '../../interpreter/interpreter.dart';

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
  HTInstance(HTClass klass, HTInterpreter interpreter,
      {List<HTType> typeArgs = const [], Map<String, dynamic>? jsonObject})
      : index = klass.instanceIndex,
        valueType = HTNominalType(klass, typeArgs: typeArgs) {
    this.interpreter = interpreter;

    HTClass? curKlass = klass;
    // final extended = <HTValueType>[];
    final myNsp = HTInstanceNamespace(
        id: InternalIdentifier.instance,
        instance: this,
        classId: curKlass.id,
        closure: klass.namespace);
    HTInstanceNamespace? curNamespace = myNsp;
    while (curKlass != null && curNamespace != null) {
      // 继承类成员，所有超类的成员都会分别保存
      for (final key in curKlass.namespace.symbols.keys) {
        final decl = curKlass.namespace.symbols[key]!;
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
        final next = HTInstanceNamespace(
            id: InternalIdentifier.instance,
            instance: this,
            runtimeInstanceNamespace: myNsp,
            classId: curKlass.id,
            closure: curKlass.namespace);
        curNamespace.next = next;
        // next.prev = curNamespace;
      } else {
        curNamespace.next = null;
      }

      curNamespace = curNamespace.next;
    }
  }

  String getTypeString() {
    // TODO: type args
    return '${InternalIdentifier.instanceOfDescription} $classId';
  }

  @override
  String toString() {
    final func = memberGet('toString', throws: false);
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
      for (final id in curNamespace.symbols.keys) {
        final decl = curNamespace.symbols[id]!;
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
      if (space.symbols.containsKey(varName) ||
          space.symbols.containsKey('${InternalIdentifier.getter}$varName') ||
          space.symbols.containsKey('${InternalIdentifier.setter}$varName')) {
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
  dynamic memberGet(String varName,
      {String? from, String? cast, bool throws = true}) {
    final getter = '${InternalIdentifier.getter}$varName';

    if (cast == null) {
      for (final space in _namespaces.values) {
        if (space.symbols.containsKey(varName)) {
          final decl = space.symbols[varName]!;
          if (decl.isPrivate &&
              from != null &&
              !from.startsWith(namespace.fullName)) {
            throw HTError.privateMember(varName);
          }
          decl.resolve();
          if (decl is HTFunction && decl.category != FunctionCategory.literal) {
            decl.namespace = namespace;
            decl.instance = this;
          }
          return decl.value;
        } else if (space.symbols.containsKey(getter)) {
          final decl = space.symbols[getter]!;
          if (decl.isPrivate &&
              from != null &&
              !from.startsWith(namespace.fullName)) {
            throw HTError.privateMember(varName);
          }
          decl.resolve();
          final func = decl as HTFunction;
          func.namespace = namespace;
          func.instance = this;
          return func.call();
        }
      }
    } else {
      final space = _namespaces[cast]!;
      if (space.symbols.containsKey(varName)) {
        final decl = space.symbols[varName]!;
        if (decl.isPrivate &&
            from != null &&
            !from.startsWith(namespace.fullName)) {
          throw HTError.privateMember(varName);
        }
        decl.resolve();
        if (decl is HTFunction && decl.category != FunctionCategory.literal) {
          decl.namespace = _namespaces[classId];
          decl.instance = this;
        }
        return decl.value;
      } else if (space.symbols.containsKey(getter)) {
        final decl = space.symbols[getter]!;
        if (decl.isPrivate &&
            from != null &&
            !from.startsWith(namespace.fullName)) {
          throw HTError.privateMember(varName);
        }
        decl.resolve();
        final func = decl as HTFunction;
        func.namespace = _namespaces[classId];
        func.instance = this;
        return func.call();
      }
    }

    if (throws) {
      throw HTError.undefined(varName);
    }
  }

  /// [HTInstance] overrided [HTEntity]'s [memberSet],
  /// with a new named parameter [cast].
  /// If [cast] is provided, then the instance will
  /// only search that [cast]'s corresponed [HTInstanceNamespace].
  @override
  void memberSet(String varName, dynamic varValue,
      {String? from, String? cast, bool throws = true}) {
    final setter = '${InternalIdentifier.setter}$varName';

    if (cast == null) {
      for (final space in _namespaces.values) {
        if (space.symbols.containsKey(varName)) {
          final decl = space.symbols[varName]!;
          if (decl.isPrivate &&
              from != null &&
              !from.startsWith(namespace.fullName)) {
            throw HTError.privateMember(varName);
          }
          decl.resolve();
          decl.value = varValue;
          return;
        } else if (space.symbols.containsKey(setter)) {
          final decl = space.symbols[setter]!;
          if (decl.isPrivate &&
              from != null &&
              !from.startsWith(namespace.fullName)) {
            throw HTError.privateMember(varName);
          }
          decl.resolve();
          final method = decl as HTFunction;
          method.namespace = namespace;
          method.instance = this;
          method.call(positionalArgs: [varValue]);
          return;
        }
      }
    } else {
      if (!_namespaces.containsKey(cast)) {
        throw HTError.notSuper(cast, classId);
      }

      final space = _namespaces[cast]!;
      if (space.symbols.containsKey(varName)) {
        var decl = space.symbols[varName]!;
        if (decl.isPrivate &&
            from != null &&
            !from.startsWith(namespace.fullName)) {
          throw HTError.privateMember(varName);
        }
        decl.resolve();
        decl.value = varValue;
        return;
      } else if (space.symbols.containsKey(setter)) {
        final decl = space.symbols[setter]!;
        if (decl.isPrivate &&
            from != null &&
            !from.startsWith(namespace.fullName)) {
          throw HTError.privateMember(varName);
        }
        decl.resolve();
        final method = decl as HTFunction;
        method.namespace = _namespaces[cast];
        method.instance = this;
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
      func.resolve();
      return func.call(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);
    } catch (error, stackTrace) {
      if (errorHandled) {
        rethrow;
      } else {
        interpreter.handleError(error, stackTrace);
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
    final hashList = [];
    hashList.add(classId);
    hashList.add(index);
    final hash = hashObjects(hashList);
    return hash;
  }
}
