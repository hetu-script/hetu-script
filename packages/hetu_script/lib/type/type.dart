import 'package:quiver/core.dart';

import '../grammar/lexicon.dart';
import '../value/entity.dart';
import '../declaration/namespace/declaration_namespace.dart';
import 'unresolved_type.dart';
import '../ast/ast.dart' show TypeExpr, FuncTypeExpr;
import 'function_type.dart';
import '../declaration/generic/generic_type_parameter.dart';

abstract class HTType with HTEntity {
  static const type = _BuiltinType(HTLexicon.kType);
  static const nullType = _BuiltinType(HTLexicon.kNull);
  static const any = _BuiltinType(HTLexicon.typeAny);
  static const voidType = _BuiltinType(HTLexicon.typeVoid);
  static const unknown = _BuiltinType(HTLexicon.typeUnknown);
  static const never = _BuiltinType(HTLexicon.typeNever);
  static const function = _BuiltinType(HTLexicon.typeFunction);

  static const Map<String, HTType> primitiveTypes = {
    HTLexicon.kType: type,
    HTLexicon.typeAny: any,
    HTLexicon.kNull: nullType,
    HTLexicon.typeVoid: voidType,
    HTLexicon.typeUnknown: unknown,
    HTLexicon.typeNever: never,
    HTLexicon.typeFunction: function,
  };

  static String parseBaseType(String typeString) {
    final argsStart = typeString.indexOf(HTLexicon.typeParameterStart);
    if (argsStart != -1) {
      final id = typeString.substring(0, argsStart);
      return id;
    } else {
      return typeString;
    }
  }

  bool get isResolved => true;

  HTType resolve(HTDeclarationNamespace namespace) => this;

  @override
  HTType get valueType => HTType.type;

  final String id;
  final List<HTType> typeArgs;
  final bool isNullable;

  const HTType(this.id, {this.typeArgs = const [], this.isNullable = false});

  factory HTType.fromAst(TypeExpr? ast) {
    if (ast != null) {
      if (ast is FuncTypeExpr) {
        return HTFunctionType(
            genericTypeParameters: ast.genericTypeParameters
                .map((param) => HTGenericTypeParameter(param.id.id,
                    superType: HTType.fromAst(param.superType)))
                .toList(),
            parameterTypes: ast.paramTypes
                .map((param) => HTParameterType(HTType.fromAst(param.declType),
                    isOptional: param.isOptional,
                    isVariadic: param.isVariadic,
                    id: param.id?.id))
                .toList(),
            returnType: HTType.fromAst(ast.returnType));
      } else {
        if (HTType.primitiveTypes.containsKey(ast.id)) {
          return HTType.primitiveTypes[ast.id]!;
        } else {
          return HTUnresolvedType(ast.id!.id,
              typeArgs:
                  ast.arguments.map((expr) => HTType.fromAst(expr)).toList(),
              isNullable: ast.isNullable);
        }
      }
    } else {
      return HTType.any;
    }
  }

  @override
  int get hashCode {
    final hashList = [];
    hashList.add(id);
    hashList.add(isNullable);
    for (final typeArg in typeArgs) {
      hashList.add(typeArg);
    }
    final hash = hashObjects(hashList);
    return hash;
  }

  @override
  bool operator ==(Object other) =>
      other is HTType && hashCode == other.hashCode;

  @override
  String toString() {
    var typeString = StringBuffer();
    typeString.write(id);
    if (typeArgs.isNotEmpty) {
      typeString.write(HTLexicon.typeParameterStart);
      for (var i = 0; i < typeArgs.length; ++i) {
        typeString.write(typeArgs[i]);
        if ((typeArgs.length > 1) && (i != typeArgs.length - 1)) {
          typeString.write('${HTLexicon.comma} ');
        }
      }
      typeString.write(HTLexicon.typeParameterEnd);
    }
    if (isNullable) {
      typeString.write(HTLexicon.nullable);
    }
    return typeString.toString();
  }

  /// Wether object of this [HTType] can be assigned to other [HTType]
  bool isA(HTType? other) {
    if (other == null) {
      return true;
    } else if (this == HTType.unknown) {
      if (other == HTType.any || other == HTType.unknown) {
        return true;
      } else {
        return false;
      }
    } else if (other == HTType.any) {
      return true;
    } else {
      if (this == HTType.nullType) {
        if (other.isNullable) {
          return true;
        } else {
          return false;
        }
      } else if (id != other.id) {
        return false;
      }
      // else if (typeArgs.length != other.typeArgs.length) {
      //   return false;
      // }
      else {
        // for (var i = 0; i < typeArgs.length; ++i) {
        //   if (!typeArgs[i].isA(typeArgs[i])) {
        //     return false;
        //   }
        // }
        return true;
      }
    }
  }

  /// Wether object of this [HTType] cannot be assigned to other [HTType]
  bool isNotA(HTType? other) => !isA(other);
}

class _BuiltinType extends HTType {
  const _BuiltinType(String id) : super(id);
}
