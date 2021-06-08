import '../core/object.dart';
import 'type.dart';

abstract class HTValueType extends HTType with HTObject {
  const HTValueType(String id, String moduleFullName, String libraryName,
      {List<HTType> typeArgs = const []})
      : super(id, moduleFullName, libraryName, typeArgs: typeArgs);
}

class HTExternalType extends HTValueType {
  const HTExternalType(String id, String moduleFullName, String libraryName)
      : super(id, moduleFullName, libraryName);
}
