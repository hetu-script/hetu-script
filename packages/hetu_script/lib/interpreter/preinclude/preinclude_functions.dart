part of '../abstract_interpreter.dart';

/// Core exernal functions for use globally in Hetu script.
final Map<String, Function> preIncludeFunctions = {
  // TODO: 读取注释
  'help': (HTNamespace context,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {},
  'print': (HTNamespace context,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    var sb = StringBuffer();
    for (final arg in positionalArgs.first) {
      sb.write('$arg ');
    }
    print(sb.toString().trimRight());
  },
  'stringify': (HTNamespace context,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return stringify(positionalArgs.first);
  },
  'jsonify': (HTNamespace context,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    // TODO: jsonify class
    final object = positionalArgs.first;
    if (object is HTStruct) {
      return HTStruct.jsonify(object);
    }
  },
  'prototype.keys': (HTNamespace context,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final object = positionalArgs.first;
    if (object is HTStruct) {
      return object.fields.keys.toList();
    }
  },
  'prototype.values': (HTNamespace context,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final object = positionalArgs.first;
    if (object is HTStruct) {
      return object.fields.values.toList();
    }
  },
  'prototype.fromJson': (HTNamespace context,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return HTStruct.fromJson(positionalArgs.first, context);
  },
  'object.toString': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return (object as HTInstance).getTypeString();
  },
};
