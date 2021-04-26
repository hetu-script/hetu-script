import 'errors.dart';
import 'variable.dart';
import 'function.dart';
import 'interpreter.dart';
import 'constants.dart';

/// A [HTDeclaration] could be a [HTVariable], a [HTClass] or a [HTFunction]
abstract class HTDeclaration {
  /// fetch the value of this declaration
  static dynamic fetch(HTDeclaration decl, Interpreter interpreter) {
    if (decl is HTFunction) {
      if (decl.externalTypedef != null) {
        final externalFunc =
            interpreter.unwrapExternalFunctionType(decl.externalTypedef!, decl);
        return externalFunc;
      } else if (decl.funcType == FunctionType.getter) {
        return decl.call();
      } else {
        return decl;
      }
    } else if (decl is HTVariable) {
      if (!decl.isExtern) {
        if (!decl.isInitialized) {
          decl.initialize();
        }
        return decl.value;
      } else {
        final externClass = interpreter.fetchExternalClass(decl.classId!);
        return externClass.memberGet(decl.id);
      }
    } else {
      return decl;
    }
  }

  static dynamic assign(HTDeclaration decl, dynamic value) {
    if (decl is HTVariable) {
      decl.assign(value);
      return;
    } else {
      throw HTError.immutable(decl.id);
    }
  }

  late final String id;
  String? classId;

  /// A [HTDeclaration] is uncloneable by default.
  HTDeclaration clone() => throw HTError.clone(id);
}
