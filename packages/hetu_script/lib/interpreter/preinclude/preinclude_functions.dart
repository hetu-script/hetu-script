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
    var sb = StringBuffer();
    for (final arg in positionalArgs.first) {
      sb.write('$arg ');
    }
    print(sb.toString().trimRight());
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
    // TODO: jsonify class
    final object = positionalArgs.first;
    if (object is HTStruct) {
      return HTStruct.jsonify(object);
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
  'prototype.contains': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.contains(positionalArgs.first);
  },
  'prototype.own': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.own(positionalArgs.first);
  },
  'object.toString': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return (object as HTInstance).getTypeString();
  },
};
