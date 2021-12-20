part of '../abstract_interpreter.dart';

/// Core exernal functions for use globally in Hetu script.
final Map<String, Function> preIncludeFunctions = {
  // TODO: 读取注释
  'help': (HTEntity entity,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {},
  'print': (HTEntity entity,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    List args = positionalArgs.first;
    print(args.join(' '));
  },
  'stringify': (HTEntity entity,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return stringify(positionalArgs.first);
  },
  'jsonify': (HTEntity entity,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final object = positionalArgs.first;
    if (object is HTStruct) {
      return jsonifyStruct(object);
    } else if (object is List) {
      return jsonifyList(object);
    } else if (isJsonDataType(object)) {
      return stringify(object);
    } else {
      return null;
    }
  },
  'prototype.fromJson': (HTEntity entity,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final context = entity as HTNamespace;
    return HTStruct.fromJson(positionalArgs.first, context);
  },
  'prototype.keys': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.fields.keys.toList();
  },
  'prototype.values': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.fields.values.toList();
  },
  // TODO: all keys and all values for struct (includes prototype's keys and values)
  'prototype.contains': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.contains(positionalArgs.first);
  },
  'prototype.owns': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.owns(positionalArgs.first);
  },
  'prototype.clone': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.clone();
  },
  'object.toString': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return (object as HTInstance).getTypeString();
  },
};
