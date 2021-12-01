// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/declarations.dart';

import 'protocol_common.dart';
import 'protocol_server.dart';

// Utilities for converting Hetu entities into analysis server's protocol entities.

/// Return a protocol [Element] corresponding to the given [AstNode].
Element convertDeclaration(HTDeclaration decl) {
  final kind = convertDeclarationToElementKind(decl);
  final name = getDeclarationDisplayName(decl);
  final elementTypeParameters = _getTypeParametersString(decl);
  final aliasedType = getAliasedTypeString(decl);
  final elementParameters = _getParametersString(decl);
  final elementReturnType = getReturnTypeString(decl);
  return Element(
    kind,
    name,
    Element.makeFlags(
      isPrivate: _isPrivate(decl),
      isDeprecated: _isDeprecated(decl),
      isAbstract: _isAbstract(decl),
      isConst: _isConst(decl),
      isFinal: _isFinal(decl),
      isStatic: _isStatic(decl),
    ),
    location: newLocation_fromDeclaration(decl),
    typeParameters: elementTypeParameters,
    aliasedType: aliasedType,
    parameters: elementParameters,
    returnType: elementReturnType,
  );
}

ElementKind convertDeclarationToElementKind(HTDeclaration decl) {
  if (decl is HTVariableDeclaration) {
    if (decl.isTopLevel) {
      return ElementKind.TOP_LEVEL_VARIABLE;
    } else if (decl.isMember) {
      return ElementKind.FIELD;
    } else {
      return ElementKind.LOCAL_VARIABLE;
    }
  } else if (decl is HTParameterDeclaration) {
    return ElementKind.PARAMETER;
  } else if (decl is HTFunctionDeclaration) {
    switch (decl.category) {
      case FunctionCategory.normal:
      case FunctionCategory.factoryConstructor:
        return ElementKind.FUNCTION;
      case FunctionCategory.method:
        return ElementKind.METHOD;
      case FunctionCategory.constructor:
        return ElementKind.CONSTRUCTOR;
      case FunctionCategory.getter:
        return ElementKind.GETTER;
      case FunctionCategory.setter:
        return ElementKind.SETTER;
      case FunctionCategory.literal:
        return ElementKind.UNKNOWN;
    }
  } else if (decl is HTClassDeclaration) {
    if (decl.isEnum) {
      return ElementKind.ENUM;
    } else {
      return ElementKind.CLASS;
    }
  } else if (decl is HTTypeAliasDeclaration) {
    return ElementKind.TYPE_ALIAS;
  } else {
    return ElementKind.UNKNOWN;
  }
}

String getDeclarationDisplayName(HTDeclaration decl) {
  return decl.displayName;
}

String? getAliasedTypeString(HTDeclaration decl) {
  if (decl is HTTypeAliasDeclaration) {
    return decl.declType.toString();
  }
  return null;
}

String? getReturnTypeString(HTDeclaration decl) {
  if (decl is HTFunctionDeclaration) {
    return decl.returnType.toString();
  } else if (decl is HTVariableDeclaration) {
    if (decl.declType != null) {
      return decl.declType.toString();
    } else {
      return HTLexicon.any;
    }
  } else if (decl is HTTypeAliasDeclaration) {
    return decl.declType.toString();
  }
  return null;
}

String? _getParametersString(HTDeclaration decl) {
  if (decl is HTFunctionDeclaration) {
    if (!decl.hasParamDecls) {
      return null;
    }
    return '(${decl.paramDecls.values.join(', ')})';
  } else {
    return null;
  }
}

String? _getTypeParametersString(HTDeclaration decl) {
  var genericTypeParameters = <HTGenericTypeParameter>[];
  if (decl is HTClassDeclaration) {
    genericTypeParameters = decl.genericTypeParameters;
  } else if (decl is HTFunctionDeclaration) {
    genericTypeParameters = decl.genericTypeParameters;
  } else if (decl is HTTypeAliasDeclaration) {
    genericTypeParameters = decl.genericTypeParameters;
  }
  return '<${genericTypeParameters.map((param) => param.id).join(', ')}>';
}

bool _isPrivate(HTDeclaration decl) {
  return decl.isPrivate;
}

bool _isDeprecated(HTDeclaration decl) {
  return false;
}

bool _isAbstract(HTDeclaration decl) {
  if (decl is HTFunctionDeclaration) {
    return decl.isAbstract;
  } else if (decl is HTClassDeclaration) {
    return decl.isAbstract;
  }
  return false;
}

bool _isConst(HTDeclaration decl) {
  return decl.isConst;
}

bool _isFinal(HTDeclaration decl) {
  if (decl is HTVariableDeclaration) {
    return !decl.isMutable;
  }
  return false;
}

bool _isStatic(HTDeclaration decl) {
  return decl.isStatic;
}
