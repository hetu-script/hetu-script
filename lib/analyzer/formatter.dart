import 'package:hetu_script/grammar/semantic.dart';

import 'ast/ast.dart';
import '../grammar/lexicon.dart';
import 'ast_source.dart';

/// Class for printing out formatted string content of a ast root
class HTFormatter implements AbstractAstVisitor {
  var _curIndentCount = 0;

  late HTAstModule _curCode;

  AstNode? _lastStmt;

  String get curIndent {
    final output = StringBuffer();
    var i = _curIndentCount;
    while (i > 0) {
      output.write(HTLexicon.indentSpace);
      --i;
    }
    return output.toString();
  }

  Future<void> format(HTAstModule module) async {
    _curCode = module;
    final output = StringBuffer();
    for (final stmt in module.nodes) {
      final stmtString = visitAstNode(stmt);
      if (stmtString.isNotEmpty) {
        if (_lastStmt is ImportStmt && stmt is! ImportStmt) {
          output.writeln('');
        }
        output.writeln(stmtString);
        if (stmt is FuncDecl ||
            stmt is ClassDecl ||
            stmt is EnumDecl ||
            stmt is VarDecl) {
          output.writeln('');
        }
      }
      _lastStmt = stmt;
    }

    module.content = output.toString();
  }

  String visitAstNode(AstNode ast) => ast.accept(this);

  @override
  String visitNullExpr(NullExpr expr) {
    return HTLexicon.NULL;
  }

  @override
  String visitBooleanExpr(BooleanExpr expr) {
    return expr.value ? HTLexicon.TRUE : HTLexicon.FALSE;
  }

  @override
  String visitConstIntExpr(ConstIntExpr expr) {
    return _curCode.constTable.getInt64(expr.constIndex).toString();
  }

  @override
  String visitConstFloatExpr(ConstFloatExpr expr) {
    return _curCode.constTable.getFloat64(expr.constIndex).toString();
  }

  @override
  String visitConstStringExpr(ConstStringExpr expr) {
    var str = _curCode.constTable.getUtf8String(expr.constIndex);
    if (str.contains("'")) {
      str = str.replaceAll(r"'", r"\'");
    }
    return "\'$str\'";
  }

  @override
  String visitGroupExpr(GroupExpr expr) {
    final inner = visitAstNode(expr.inner);
    return '${HTLexicon.roundLeft}$inner${HTLexicon.roundRight}';
  }

  @override
  String visitLiteralListExpr(LiteralListExpr expr) {
    final output = StringBuffer();
    output.write(HTLexicon.squareLeft);
    for (var i = 0; i < expr.list.length; ++i) {
      final itemString = visitAstNode(expr.list[i]);
      output.write('$itemString');
      if (i < expr.list.length - 1) {
        output.write('${HTLexicon.comma} ');
      }
    }
    output.write(HTLexicon.squareRight);
    return output.toString();
  }

  @override
  String visitLiteralMapExpr(LiteralMapExpr expr) {
    final output = StringBuffer();
    output.write(HTLexicon.curlyLeft);
    if (expr.map.keys.isNotEmpty) {
      output.writeln('');
      ++_curIndentCount;
      final keyList = expr.map.keys.toList();
      for (var i = 0; i < expr.map.length; ++i) {
        final key = keyList[i];
        final keyString = visitAstNode(key);
        final valueString = visitAstNode(expr.map[key]!);
        output.write(curIndent);
        output.write('$keyString${HTLexicon.colon} $valueString');
        if (i < keyList.length - 1) {
          output.write('${HTLexicon.comma} ');
        }
        output.writeln('');
      }
      --_curIndentCount;
    }
    output.write(curIndent);
    output.write(HTLexicon.curlyRight);
    return output.toString();
  }

  @override
  String visitSymbolExpr(SymbolExpr expr) {
    return expr.id;
  }

  @override
  String visitUnaryPrefixExpr(UnaryPrefixExpr expr) {
    final valueString = visitAstNode(expr.value);
    return '${expr.op}$valueString';
  }

  @override
  String visitBinaryExpr(BinaryExpr expr) {
    final leftString = visitAstNode(expr.left);
    final rightString = visitAstNode(expr.right);
    return '$leftString ${expr.op} $rightString';
  }

  @override
  String visitTernaryExpr(TernaryExpr expr) {
    final condition = visitAstNode(expr.condition);
    final thenBranch = visitAstNode(expr.thenBranch);
    final elseBranch = visitAstNode(expr.elseBranch);
    return '$condition ${HTLexicon.condition} $thenBranch ${HTLexicon.elseBranch} $elseBranch';
  }

  @override
  String visitTypeExpr(TypeExpr expr) {
    final output = StringBuffer();
    if (expr is FunctionTypeExpr) {
    } else {
      output.write(expr.id);
      if (expr.arguments.isNotEmpty) {
        output.write(HTLexicon.typesBracketLeft);
        for (final type in expr.arguments) {
          final typeString = visitTypeExpr(type);
          output.write('$typeString');
        }
        output.write(HTLexicon.typesBracketRight);
      }
      if (expr.isNullable) {
        output.write(HTLexicon.nullable);
      }
    }
    return output.toString();
  }

  @override
  String visitFunctionTypeExpr(FunctionTypeExpr expr) {
    final output = StringBuffer();
    output.write('${HTLexicon.FUNCTION} ${HTLexicon.roundLeft}');
    var isOptional = false;
    var isNamed = false;
    for (var i = 0; i < expr.paramTypes.length; ++i) {
      final param = expr.paramTypes[i];
      if (param.id != null) {
        if (!isNamed) {
          isNamed = true;
          output.write(HTLexicon.curlyLeft);
        }
        output.write('${param.id}${HTLexicon.colon} ');
      }
      if (param.isOptional && !isOptional) {
        isOptional = true;
        output.write(HTLexicon.squareLeft);
      }
      if (param.paramType != null) {
        final typeString = visitTypeExpr(param.paramType!);
        output.write(typeString);
      } else {
        output.write(HTLexicon.ANY);
      }
      if (i < expr.paramTypes.length - 1) {
        output.write('${HTLexicon.comma} ');
      }
    }
    if (isOptional) {
      output.write(HTLexicon.squareRight);
    } else if (isNamed) {
      output.write(HTLexicon.curlyRight);
    }
    output.write('${HTLexicon.roundRight} ${HTLexicon.singleArrow} ');
    final returnTypeString = visitTypeExpr(expr.returnType);
    output.write('$returnTypeString');
    return output.toString();
  }

  @override
  String visitCallExpr(CallExpr expr) {
    final output = StringBuffer();
    final calleeString = visitAstNode(expr.callee);
    output.write('$calleeString${HTLexicon.roundLeft}');
    for (var i = 0; i < expr.positionalArgs.length; ++i) {
      final arg = expr.positionalArgs[i];
      final argString = visitAstNode(arg);
      output.write(argString);
      if ((i < expr.positionalArgs.length - 1) || expr.namedArgs.isNotEmpty) {
        output.write('${HTLexicon.comma} ');
      }
    }
    if (expr.namedArgs.isNotEmpty) {
      final nameList = expr.namedArgs.keys.toList();
      for (var i = 0; i < expr.namedArgs.length; ++i) {
        final name = nameList[i];
        output.write('$name${HTLexicon.colon} ');
        final argString = visitAstNode(expr.namedArgs[name]!);
        output.write(argString);
        if (i < expr.namedArgs.length - 1) {
          output.write('${HTLexicon.comma} ');
        }
      }
    }
    output.write(HTLexicon.roundRight);
    return output.toString();
  }

  @override
  String visitUnaryPostfixExpr(UnaryPostfixExpr expr) {
    final valueString = visitAstNode(expr.value);
    return '$valueString${expr.op}';
  }

  @override
  String visitSubGetExpr(SubGetExpr expr) {
    final collectionString = visitAstNode(expr.collection);
    final keyString = visitAstNode(expr.key);
    return '$collectionString${HTLexicon.squareLeft}$keyString${HTLexicon.squareRight}';
  }

  @override
  String visitMemberGetExpr(MemberGetExpr expr) {
    final collectionString = visitAstNode(expr.collection);
    return '$collectionString${HTLexicon.memberGet}${expr.key}';
  }

  @override
  String visitImportStmt(ImportStmt stmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.IMPORT} ');
    output.write(
        '${HTLexicon.singleQuotation}${stmt.key}${HTLexicon.singleQuotation}');
    if (stmt.alias != null) {
      output.write(' ${HTLexicon.AS} ${stmt.alias}');
    }
    if (stmt.showList != null && stmt.showList!.isNotEmpty) {
      final showList = stmt.showList!;
      output.write(' ${HTLexicon.SHOW} ');
      for (var i = 0; i < showList.length; ++i) {
        output.write(showList[i]);
        if (i < showList.length - 1) {
          output.write('${HTLexicon.comma} ');
        }
      }
    }
    return output.toString();
  }

  @override
  String visitExprStmt(ExprStmt stmt) {
    final output = StringBuffer();
    if (stmt.expr != null) {
      final exprString = visitAstNode(stmt.expr!);
      output.write(exprString);
    }
    return output.toString();
  }

  @override
  String visitBlockStmt(BlockStmt block) {
    final output = StringBuffer();
    if (block.statements.isNotEmpty) {
      output.writeln(HTLexicon.curlyLeft);
      ++_curIndentCount;
      for (final stmt in block.statements) {
        final stmtString = visitAstNode(stmt);
        if (stmtString.isNotEmpty) {
          output.write(curIndent);
          output.writeln(stmtString);
        }
      }
      --_curIndentCount;
      output.write(curIndent);
      output.write(HTLexicon.curlyRight);
    } else {
      output.write(' ${HTLexicon.curlyLeft}${HTLexicon.curlyRight}');
    }
    return output.toString();
  }

  @override
  String visitReturnStmt(ReturnStmt stmt) {
    final output = StringBuffer();
    output.write(HTLexicon.RETURN);
    if (stmt.value != null) {
      final valueString = visitAstNode(stmt.value!);
      output.write(' $valueString');
    }
    return output.toString();
  }

  @override
  String visitIfStmt(IfStmt ifStmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.IF} ${HTLexicon.roundLeft}');
    final conditionString = visitAstNode(ifStmt.condition);
    output.write('$conditionString${HTLexicon.roundRight} ');
    final thenBranchString = visitAstNode(ifStmt.thenBranch);
    output.write(thenBranchString);
    if ((ifStmt.elseBranch is IfStmt) || (ifStmt.elseBranch is BlockStmt)) {
      output.writeln(' ${HTLexicon.ELSE} ');
      final elseBranchString = visitAstNode(ifStmt.elseBranch!);
      output.write(elseBranchString);
    } else {
      output.writeln(' ${HTLexicon.ELSE} ${HTLexicon.curlyLeft}');
      ++_curIndentCount;
      output.write(curIndent);
      final elseBranchString = visitAstNode(ifStmt.elseBranch!);
      output.writeln(elseBranchString);
      --_curIndentCount;
      output.write(curIndent);
      output.write(HTLexicon.curlyRight);
    }
    return output.toString();
  }

  @override
  String visitWhileStmt(WhileStmt whileStmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.WHILE} ');
    if (whileStmt.condition != null) {
      output.write('${HTLexicon.roundLeft}');
      final conditionString = visitAstNode(whileStmt.condition!);
      output.write('$conditionString${HTLexicon.roundRight} ');
    }
    final loopString = visitAstNode(whileStmt.loop);
    output.write(loopString);
    return output.toString();
  }

  @override
  String visitDoStmt(DoStmt doStmt) {
    final output = StringBuffer();
    output.write(HTLexicon.DO);
    final loopString = visitAstNode(doStmt.loop);
    output.write(loopString);
    if (doStmt.condition != null) {
      final conditionString = visitAstNode(doStmt.condition!);
      output.write(' ${HTLexicon.WHILE} ${HTLexicon.roundLeft}');
      output.write(conditionString);
      output.write(HTLexicon.roundRight);
    }
    return output.toString();
  }

  @override
  String visitForInStmt(ForInStmt forInStmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.FOR} ${HTLexicon.roundLeft}');
    final declString = visitAstNode(forInStmt.declaration);
    final collectionString = visitAstNode(forInStmt.collection);
    output.write('$declString ${HTLexicon.IN} $collectionString');
    output.write('${HTLexicon.roundRight} ');
    final stmtString = visitAstNode(forInStmt.loop);
    output.writeln(stmtString);
    return output.toString();
  }

  @override
  String visitForStmt(ForStmt forStmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.FOR} ${HTLexicon.roundLeft}');
    final declString =
        forStmt.declaration != null ? visitAstNode(forStmt.declaration!) : '';
    final conditionString =
        forStmt.condition != null ? visitAstNode(forStmt.condition!) : '';
    final incrementString =
        forStmt.increment != null ? visitAstNode(forStmt.increment!) : '';
    output.write(
        '$declString${HTLexicon.semicolon} $conditionString${HTLexicon.semicolon} $incrementString${HTLexicon.roundRight} ');
    final loopString = visitAstNode(forStmt.loop);
    output.write(loopString);
    return output.toString();
  }

  @override
  String visitWhenStmt(WhenStmt stmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.WHEN}');
    if (stmt.condition != null) {
      final conditionString = visitAstNode(stmt.condition!);
      output.write(
          ' ${HTLexicon.roundLeft}$conditionString${HTLexicon.roundRight}');
    }
    output.writeln(' ${HTLexicon.curlyLeft}');
    ++_curIndentCount;
    for (final option in stmt.options.keys) {
      output.write(curIndent);
      final optionString = visitAstNode(option);
      output.write('$optionString ${HTLexicon.singleArrow} ');
      final branchString = visitAstNode(stmt.options[option]!);
      output.writeln(branchString);
    }
    if (stmt.elseBranch != null) {
      final elseBranchString = visitAstNode(stmt.elseBranch!);
      output.write(curIndent);
      output.writeln(
          '${HTLexicon.ELSE} ${HTLexicon.singleArrow} $elseBranchString');
    }
    --_curIndentCount;
    output.write(curIndent);
    output.write(HTLexicon.curlyRight);
    return output.toString();
  }

  @override
  String visitBreakStmt(BreakStmt stmt) {
    return '${stmt.keyword.lexeme}';
  }

  @override
  String visitContinueStmt(ContinueStmt stmt) {
    return '${stmt.keyword.lexeme}';
  }

  @override
  String visitVarDeclStmt(VarDecl stmt) {
    final output = StringBuffer();
    if (stmt.isExternal) {
      output.write('${HTLexicon.EXTERNAL} ');
    }
    if (stmt.isStatic) {
      output.write('${HTLexicon.STATIC} ');
    }
    if (stmt.isImmutable) {
      output.write('${HTLexicon.CONST} ');
    } else if (stmt.typeInferrence) {
      output.write('${HTLexicon.LET} ');
    } else {
      output.write('${HTLexicon.VAR} ');
    }
    output.write('${stmt.id}');
    if (stmt.declType != null) {
      final typeString = visitAstNode(stmt.declType!);
      output.write('${HTLexicon.colon} $typeString');
    }
    if (stmt.initializer != null) {
      final initString = visitAstNode(stmt.initializer!);
      output.write(' ${HTLexicon.assign} $initString');
    }
    return output.toString();
  }

  @override
  String visitParamDeclStmt(ParamDecl stmt) {
    final output = StringBuffer();
    output.write('${stmt.id}');
    if (stmt.declType != null) {
      final typeString = visitAstNode(stmt.declType!);
      output.write('${HTLexicon.colon} $typeString');
    }
    if (stmt.initializer != null) {
      final initString = visitAstNode(stmt.initializer!);
      output.write(' ${HTLexicon.assign} $initString');
    }
    return output.toString();
  }

  @override
  String visitReferConstructorExpr(ReferConstructorExpr stmt) {
    final output = StringBuffer();
    output.write(stmt.isSuper ? HTLexicon.SUPER : HTLexicon.THIS);
    if (stmt.name != null) {
      output.write('${HTLexicon.memberGet}${stmt.name}');
    }
    return output.toString();
  }

  @override
  String visitFuncDeclStmt(FuncDecl stmt) {
    final output = StringBuffer();
    if (stmt.isExternal) {
      output.write('${HTLexicon.EXTERNAL} ');
    }
    if (stmt.isStatic) {
      output.write('${HTLexicon.STATIC} ');
    }
    switch (stmt.category) {
      case FunctionCategory.normal:
      case FunctionCategory.method:
      case FunctionCategory.literal:
      case FunctionCategory.nested:
        output.write(HTLexicon.FUNCTION);
        break;
      case FunctionCategory.constructor:
        output.write(HTLexicon.CONSTRUCT);
        break;
      case FunctionCategory.getter:
        output.write(HTLexicon.GET);
        break;
      case FunctionCategory.setter:
        output.write(HTLexicon.SET);
        break;
    }
    if (stmt.externalTypedef != null) {
      output.write(
          ' ${HTLexicon.squareLeft}${stmt.externalTypedef}${HTLexicon.squareRight}');
    }
    if (stmt.declId.isNotEmpty) {
      output.write(' ${stmt.declId}${HTLexicon.roundLeft}');
    } else {
      output.write(HTLexicon.roundLeft);
    }
    final paramList = stmt.params.toList();
    var isOptional = false;
    var isNamed = false;
    for (var i = 0; i < paramList.length; ++i) {
      final param = paramList[i];
      if (param.isOptional) {
        if (!isOptional) {
          isOptional = true;
          output.write(HTLexicon.squareLeft);
        }

        if (param.isVariadic) {
          output.write('${HTLexicon.variadicArgs} ');
        }
      } else if (param.isNamed && !isNamed) {
        isNamed = true;
        output.write(HTLexicon.squareLeft);
      }

      final paramString = visitAstNode(param);
      output.write(paramString);

      if (i < paramList.length - 1) {
        output.write('${HTLexicon.comma} ');
      }
    }
    output.write('${HTLexicon.roundRight} ');

    if (stmt.returnType != null) {
      output.write('${HTLexicon.singleArrow} ');
      final returnTypeString = visitTypeExpr(stmt.returnType!);
      output.write('$returnTypeString ');
    } else if (stmt.referCtor != null) {
      output.write('${HTLexicon.colon} ');
      final referCtorString = visitCallExpr(stmt.referCtor!);
      output.write('$referCtorString ');
    }

    if (stmt.definition != null) {
      final blockString = visitBlockStmt(stmt.definition!);
      output.write(blockString);
    }

    return output.toString();
  }

  @override
  String visitClassDeclStmt(ClassDecl stmt) {
    final output = StringBuffer();
    if (stmt.isExternal) {
      output.write('${HTLexicon.EXTERNAL} ');
    }
    if (stmt.isAbstract) {
      output.write('${HTLexicon.ABSTRACT} ');
    }
    output.write('${HTLexicon.CLASS} ${stmt.id} ');
    if (stmt.superClassType != null) {
      final superClassTypeString = visitTypeExpr(stmt.superClassType!);
      output.write('${HTLexicon.EXTENDS} $superClassTypeString ');
    }
    final blockString = visitBlockStmt(stmt.definition);
    output.write(blockString);
    return output.toString();
  }

  @override
  String visitEnumDeclStmt(EnumDecl stmt) {
    final output = StringBuffer();
    if (stmt.isExternal) {
      output.write('${HTLexicon.EXTERNAL} ');
    }
    output.writeln('${HTLexicon.ENUM} ${stmt.id} ${HTLexicon.curlyLeft}');
    ++_curIndentCount;
    for (var i = 0; i < stmt.enumerations.length; ++i) {
      output.write(curIndent);
      output.write('${stmt.enumerations[i]}');
      if (i < stmt.enumerations.length - 1) {
        output.writeln('${HTLexicon.comma} ');
      } else {
        output.writeln('');
      }
    }
    --_curIndentCount;
    output.write(curIndent);
    output.write(HTLexicon.curlyRight);

    return output.toString();
  }
}
