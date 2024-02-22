import 'package:quiver/iterables.dart';

// import '../../value/object.dart';
// import '../../type/type.dart';
// import '../../value/struct/struct.dart';
// import '../../value/instance/instance.dart';

/// Core exernal functions for use globally in Hetu script.
final Map<String, Function> preincludeFunctions = {
  '_print': ({positionalArgs, namedArgs}) => print(positionalArgs.first),
  'range': ({positionalArgs, namedArgs}) =>
      range(positionalArgs[0], positionalArgs[1], positionalArgs[2]),
  // 'Prototype.keys': ({positionalArgs, namedArgs}) {
  //   final obj = instance as HTStruct;
  //   return obj.keys;
  // },
  // 'Prototype.values': ({positionalArgs, namedArgs}) {
  //   final obj = instance as HTStruct;
  //   return obj.values;
  // },
  // 'Prototype.contains': ({positionalArgs, namedArgs}) {
  //   final obj = instance as HTStruct;
  //   return obj.contains(positionalArgs.first);
  // },
  // 'Prototype.containsKey': ({positionalArgs, namedArgs}) {
  //   final obj = instance as HTStruct;
  //   return obj.containsKey(positionalArgs.first);
  // },
  // 'Prototype.isEmpty': ({positionalArgs, namedArgs}) {
  //   final obj = instance as HTStruct;
  //   return obj.isEmpty;
  // },
  // 'Prototype.isNotEmpty': ({positionalArgs, namedArgs}) {
  //   final obj = instance as HTStruct;
  //   return obj.isNotEmpty;
  // },
  // 'Prototype.length': ({positionalArgs, namedArgs}) {
  //   final obj = instance as HTStruct;
  //   return obj.length;
  // },
  // 'Prototype.clone': ({positionalArgs, namedArgs}) {
  //   final obj = instance as HTStruct;
  //   return obj.clone();
  // },
  // 'Prototype.assign': ({positionalArgs, namedArgs}) {
  //   final obj = instance as HTStruct;
  //   final other = positionalArgs.first as HTStruct;
  //   obj.assign(other);
  // },
  // 'Object.toString': ({positionalArgs, namedArgs}) {
  //   return (instance as HTInstance).getTypeString();
  // },
};
