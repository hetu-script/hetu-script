import 'package:quiver/iterables.dart';

import '../../value/entity.dart';
import '../../type/type.dart';
import '../../value/struct/struct.dart';
import '../../value/instance/instance.dart';

/// Core exernal functions for use globally in Hetu script.
final Map<String, Function> preincludeFunctions = {
  '_print': (HTEntity entity,
          {List<dynamic> positionalArgs = const [],
          Map<String, dynamic> namedArgs = const {},
          List<HTType> typeArgs = const []}) =>
      print(positionalArgs.first),
  'range': (HTEntity entity,
          {List<dynamic> positionalArgs = const [],
          Map<String, dynamic> namedArgs = const {},
          List<HTType> typeArgs = const []}) =>
      range(positionalArgs[0], positionalArgs[1], positionalArgs[2]),
  'prototype.keys': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.keys;
  },
  'prototype.values': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.values;
  },
  'prototype.contains': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.contains(positionalArgs.first);
  },
  'prototype.containsKey': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.containsKey(positionalArgs.first);
  },
  'prototype.isEmpty': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.isEmpty;
  },
  'prototype.isNotEmpty': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.isNotEmpty;
  },
  'prototype.length': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.length;
  },
  'prototype.clone': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    return obj.clone();
  },
  'prototype.assign': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final obj = object as HTStruct;
    final other = positionalArgs.first as HTStruct;
    obj.assign(other);
  },
  'object.toString': (HTEntity object,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    return (object as HTInstance).getTypeString();
  },
};
