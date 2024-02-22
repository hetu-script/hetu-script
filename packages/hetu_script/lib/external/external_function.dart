// import '../type/type.dart';
import '../value/function/function.dart';
import '../value/object.dart';
// import '../value/namespace/namespace.dart';

/// Typedef of external function for binding.
/// Can be used on normal external function or external method of a script class,
typedef HTExternalFunction = dynamic Function({
  HTObject? instance,
  List<dynamic> positionalArgs,
  Map<String, dynamic> namedArgs,
});

/// Accept a hetu function object, then return a dart function
/// for use in Dart code. This is for usage where you want to
/// write a function in script. and want to pass it to a
/// external dart function where it accepts only a pure Dart
/// native function as parameter.
typedef HTExternalFunctionTypedef = Function Function(HTFunction hetuFunction);

/// Accept an object and return the type name of it in the form of String.
/// This is normally used to check the type of a Dart Object, and return the human-friendly type name of it.
/// For example, the underlying typename of the Map could be LinkedHashMap, however we tend to call it a Map instead.
typedef HTExternalTypeReflection = String? Function(Object object);
