import '../ast/ast.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../ast/ast_compilation.dart';

class FormatterConfig {
  final int pageWidth;
  final bool formatQuotationMark;
  final bool singleQuotationMark;
  final bool removeTrailingComma;

  const FormatterConfig(
      {this.pageWidth = 80,
      this.formatQuotationMark = true,
      this.singleQuotationMark = true,
      this.removeTrailingComma = true});
}

/// Class for printing out formatted string content of a ast root
class HTFormatter implements AbstractAstVisitor<String> {
  var _curIndentCount = 0;

  AstNode? _lastStmt;

  FormatterConfig config;

  HTFormatter({this.config = const FormatterConfig()});

  String get curIndent {
    final output = StringBuffer();
    var i = _curIndentCount;
    while (i > 0) {
      output.write(HTLexicon.indentSpace);
      --i;
    }
    return output.toString();
  }

  String format(List<AstNode> nodes, {FormatterConfig? config}) {
    final savedConfig = this.config;
    if (config != null) {
      this.config = config;
    }

    final output = StringBuffer();
    for (var i = 0; i < nodes.length; ++i) {
      final stmt = nodes[i];
      final stmtString = printAst(stmt);
      if (stmtString.isNotEmpty) {
        if (_lastStmt is ImportStmt && stmt is! ImportStmt) {
          output.writeln('');
        }
        output.writeln(stmtString);
        if ((i < nodes.length - 1) &&
            (stmt is FuncDeclExpr ||
                stmt is ClassDeclStmt ||
                stmt is EnumDeclStmt)) {
          output.writeln('');
        }
      }
      _lastStmt = stmt;
    }

    this.config = savedConfig;

    final result = output.toString();

    return result;
  }

  void formatModule(HTAstModule module) {
    module.source.content = format(module.nodes);
  }

  void formatLibrary(HTAstCompilation bundle) {
    for (final module in bundle.modules.values) {
      formatModule(module);
    }
  }

  String printAst(AstNode ast) => ast.accept(this);

  @override
  String visitEmptyExpr(EmptyExpr expr) {
    return '';
  }

  @override
  String visitCommentExpr(CommentExpr expr) {
    return expr.content;
  }

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
    return expr.value.toString();
  }

  @override
  String visitConstFloatExpr(ConstFloatExpr expr) {
    return expr.value.toString();
  }

  @override
  String visitConstStringExpr(ConstStringExpr expr) {
    var output = expr.value;
    if (output.contains("'")) {
      output = output.replaceAll(r"'", r"\'");
    }
    return "\'$output\'";
  }

  @override
  String visitStringInterpolationExpr(StringInterpolationExpr expr) {
    final interpolation = <String>[];
    for (final node in expr.interpolation) {
      final nodeString = printAst(node);
      interpolation.add(nodeString);
    }
    var output = expr.value;
    for (var i = 0; i < interpolation.length; ++i) {
      output = output.replaceAll(
          '${HTLexicon.curlyLeft}$i${HTLexicon.curlyRight}',
          '${HTLexicon.stringInterpolationStart}${interpolation[i]}${HTLexicon.stringInterpolationEnd}');
    }
    return "\'$output\'";
  }

  @override
  String visitGroupExpr(GroupExpr expr) {
    final inner = printAst(expr.inner);
    return '${HTLexicon.roundLeft}$inner${HTLexicon.roundRight}';
  }

  @override
  String visitListExpr(ListExpr expr) {
    final output = StringBuffer();
    output.write(HTLexicon.squareLeft);
    for (var i = 0; i < expr.list.length; ++i) {
      final itemString = printAst(expr.list[i]);
      output.write('$itemString');
      if (i < expr.list.length - 1) {
        output.write('${HTLexicon.comma} ');
      }
    }
    output.write(HTLexicon.squareRight);
    return output.toString();
  }

  @override
  String visitMapExpr(MapExpr expr) {
    final output = StringBuffer();
    output.write(HTLexicon.curlyLeft);
    if (expr.map.keys.isNotEmpty) {
      output.writeln('');
      ++_curIndentCount;
      final keyList = expr.map.keys.toList();
      for (var i = 0; i < expr.map.length; ++i) {
        final key = keyList[i];
        final keyString = printAst(key);
        final valueString = printAst(expr.map[key]!);
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
    final valueString = printAst(expr.value);
    return '${expr.op}$valueString';
  }

  @override
  String visitBinaryExpr(BinaryExpr expr) {
    final leftString = printAst(expr.left);
    final rightString = printAst(expr.right);
    return '$leftString ${expr.op} $rightString';
  }

  @override
  String visitTernaryExpr(TernaryExpr expr) {
    final condition = printAst(expr.condition);
    final thenBranch = printAst(expr.thenBranch);
    final elseBranch = printAst(expr.elseBranch);
    return '$condition ${HTLexicon.condition} $thenBranch ${HTLexicon.elseBranch} $elseBranch';
  }

  @override
  String visitTypeExpr(TypeExpr expr) {
    final output = StringBuffer();
    if (expr is FuncTypeExpr) {
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
  String visitParamTypeExpr(ParamTypeExpr expr) {
    final output = StringBuffer();
    var isOptional = false;
    var isNamed = false;
    if (expr.id != null) {
      if (!isNamed) {
        isNamed = true;
        output.write(HTLexicon.curlyLeft);
      }
      output.write('${expr.id}${HTLexicon.colon} ');
    }
    if (expr.isOptional && !isOptional) {
      isOptional = true;
      output.write(HTLexicon.squareLeft);
    }
    final typeString = visitTypeExpr(expr.declType);
    output.write(typeString);
    return output.toString();
  }

  @override
  String visitFunctionTypeExpr(FuncTypeExpr expr) {
    final output = StringBuffer();
    output.write('${HTLexicon.FUNCTION} ${HTLexicon.roundLeft}');
    for (var i = 0; i < expr.paramTypes.length; ++i) {
      final param = expr.paramTypes[i];
      final paramString = visitParamTypeExpr(param);
      output.write(paramString);
      if (i < expr.paramTypes.length - 1) {
        output.write('${HTLexicon.comma} ');
      }
    }
    if (expr.hasOptionalParam) {
      output.write(HTLexicon.squareRight);
    } else if (expr.hasNamedParam) {
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
    final calleeString = printAst(expr.callee);
    output.write('$calleeString${HTLexicon.roundLeft}');
    for (var i = 0; i < expr.positionalArgs.length; ++i) {
      final arg = expr.positionalArgs[i];
      final argString = printAst(arg);
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
        final argString = printAst(expr.namedArgs[name]!);
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
    final valueString = printAst(expr.value);
    return '$valueString${expr.op}';
  }

  @override
  String visitMemberExpr(MemberExpr expr) {
    final collectionString = printAst(expr.object);
    final keyString = printAst(expr.key);
    return '$collectionString${HTLexicon.memberGet}$keyString';
  }

  @override
  String visitMemberAssignExpr(MemberAssignExpr expr) {
    final collectionString = printAst(expr.object);
    //TODO: member assign
    return '$collectionString${HTLexicon.memberGet}${expr.key}';
  }

  @override
  String visitSubExpr(SubExpr expr) {
    final collectionString = printAst(expr.array);
    final keyString = printAst(expr.key);
    return '$collectionString${HTLexicon.squareLeft}$keyString${HTLexicon.squareRight}';
  }

  @override
  String visitSubAssignExpr(SubAssignExpr expr) {
    final collectionString = printAst(expr.array);
    final keyString = printAst(expr.key);
    //TODO: sub assign
    return '$collectionString${HTLexicon.squareLeft}$keyString${HTLexicon.squareRight} ';
  }

  @override
  String visitLibraryStmt(LibraryStmt stmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.LIBRARY} ');
    // TODO: library statement
    return output.toString();
  }

  @override
  String visitImportStmt(ImportStmt stmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.IMPORT} ');
    output.write(
        '${HTLexicon.singleQuotationLeft}${stmt.key}${HTLexicon.singleQuotationRight}');
    if (stmt.alias != null) {
      output.write(' ${HTLexicon.AS} ${stmt.alias}');
    }
    if (stmt.showList.isNotEmpty) {
      output.write(' ${HTLexicon.SHOW} ');
      for (var i = 0; i < stmt.showList.length; ++i) {
        output.write(stmt.showList[i]);
        if (i < stmt.showList.length - 1) {
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
      final exprString = printAst(stmt.expr!);
      output.write(exprString);
    }
    return output.toString();
  }

  @override
  String visitBlockStmt(BlockStmt block) {
    final output = StringBuffer();
    if (block.statements.isNotEmpty) {
      output.writeln(' ${HTLexicon.curlyLeft}');
      ++_curIndentCount;
      for (final stmt in block.statements) {
        final stmtString = printAst(stmt);
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
      final valueString = printAst(stmt.value!);
      output.write(' $valueString');
    }
    return output.toString();
  }

  @override
  String visitIfStmt(IfStmt ifStmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.IF} ${HTLexicon.roundLeft}');
    final conditionString = printAst(ifStmt.condition);
    output.write('$conditionString${HTLexicon.roundRight} ');
    final thenBranchString = printAst(ifStmt.thenBranch);
    output.write(thenBranchString);
    if ((ifStmt.elseBranch is IfStmt) || (ifStmt.elseBranch is BlockStmt)) {
      output.write(' ${HTLexicon.ELSE} ');
      final elseBranchString = printAst(ifStmt.elseBranch!);
      output.write(elseBranchString);
    } else if (ifStmt.elseBranch != null) {
      output.writeln(' ${HTLexicon.ELSE} ${HTLexicon.curlyLeft}');
      ++_curIndentCount;
      output.write(curIndent);
      final elseBranchString = printAst(ifStmt.elseBranch!);
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
    final conditionString = printAst(whileStmt.condition);
    output.write('$conditionString ');
    final loopString = printAst(whileStmt.loop);
    output.write(loopString);
    return output.toString();
  }

  @override
  String visitDoStmt(DoStmt doStmt) {
    final output = StringBuffer();
    output.write(HTLexicon.DO);
    final loopString = printAst(doStmt.loop);
    output.write(loopString);
    if (doStmt.condition != null) {
      final conditionString = printAst(doStmt.condition!);
      output.write(' ${HTLexicon.WHILE} ');
      output.write(conditionString);
    }
    return output.toString();
  }

  @override
  String visitForStmt(ForStmt forStmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.FOR} ');
    if (forStmt.hasBracket) {
      output.write(HTLexicon.roundLeft);
    }
    final declString =
        forStmt.declaration != null ? printAst(forStmt.declaration!) : '';
    final conditionString =
        forStmt.condition != null ? printAst(forStmt.condition!) : '';
    final incrementString =
        forStmt.increment != null ? printAst(forStmt.increment!) : '';
    output.write(
        '$declString${HTLexicon.semicolon} $conditionString${HTLexicon.semicolon} $incrementString');
    if (forStmt.hasBracket) {
      output.write('${HTLexicon.roundRight} ');
    }
    final loopString = printAst(forStmt.loop);
    output.write(loopString);
    return output.toString();
  }

  @override
  String visitForInStmt(ForInStmt forInStmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.FOR} ');
    if (forInStmt.hasBracket) {
      output.write(HTLexicon.roundLeft);
    }
    final declString = printAst(forInStmt.declaration);
    final collectionString = printAst(forInStmt.collection);
    output.write('$declString ${HTLexicon.IN} $collectionString');
    if (forInStmt.hasBracket) {
      output.write('${HTLexicon.roundRight} ');
    }
    final stmtString = printAst(forInStmt.loop);
    output.write(stmtString);
    return output.toString();
  }

  @override
  String visitWhenStmt(WhenStmt stmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.WHEN}');
    if (stmt.condition != null) {
      final conditionString = printAst(stmt.condition!);
      output.write(
          ' ${HTLexicon.roundLeft}$conditionString${HTLexicon.roundRight}');
    }
    output.writeln(' ${HTLexicon.curlyLeft}');
    ++_curIndentCount;
    for (final option in stmt.cases.keys) {
      output.write(curIndent);
      final optionString = printAst(option);
      output.write('$optionString ${HTLexicon.singleArrow} ');
      final branchString = printAst(stmt.cases[option]!);
      output.writeln(branchString);
    }
    if (stmt.elseBranch != null) {
      final elseBranchString = printAst(stmt.elseBranch!);
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
  String visitVarDeclStmt(VarDeclStmt stmt) {
    final output = StringBuffer();
    if (stmt.isExternal) {
      output.write('${HTLexicon.EXTERNAL} ');
    }
    if (stmt.isStatic) {
      output.write('${HTLexicon.STATIC} ');
    }
    if (!stmt.isMutable) {
      output.write('${HTLexicon.CONST} ');
    } else if (stmt.typeInferrence) {
      output.write('${HTLexicon.LET} ');
    } else {
      output.write('${HTLexicon.VAR} ');
    }
    output.write('${stmt.id}');
    if (stmt.declType != null) {
      final typeString = printAst(stmt.declType!);
      output.write('${HTLexicon.colon} $typeString');
    }
    if (stmt.initializer != null) {
      final initString = printAst(stmt.initializer!);
      output.write(' ${HTLexicon.assign} $initString');
    }
    return output.toString();
  }

  String printGenericTypes(List<TypeExpr> params) {
    final output = StringBuffer();
    if (params.isNotEmpty) {
      output.write(HTLexicon.typesBracketLeft);
      for (var i = 0; i < params.length; ++i) {
        final param = params[i];
        final paramString = printAst(param);
        output.write(paramString);

        if (i < params.length - 1) {
          output.write('${HTLexicon.comma} ');
        }
      }
      output.write(HTLexicon.typesBracketRight);
    }
    return output.toString();
  }

  @override
  String visitParamDeclStmt(ParamDeclExpr stmt) {
    final output = StringBuffer();
    output.write('${stmt.id}');
    if (stmt.declType != null) {
      final typeString = printAst(stmt.declType!);
      output.write('${HTLexicon.colon} $typeString');
    }
    if (stmt.initializer != null) {
      final initString = printAst(stmt.initializer!);
      output.write(' ${HTLexicon.assign} $initString');
    }
    return output.toString();
  }

  @override
  String visitReferConstructorExpr(ReferConstructorExpr stmt) {
    final output = StringBuffer();
    output.write(stmt.isSuper ? HTLexicon.SUPER : HTLexicon.THIS);
    if (stmt.key != null) {
      output.write('${HTLexicon.memberGet}${stmt.key}');
    }
    return output.toString();
  }

  String printParamDecls(List<ParamDeclExpr> params) {
    final output = StringBuffer();

    var isOptional = false;
    var isNamed = false;
    output.write(HTLexicon.roundLeft);
    for (var i = 0; i < params.length; ++i) {
      final param = params[i];
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

      final paramString = printAst(param);
      output.write(paramString);

      if (i < params.length - 1) {
        output.write('${HTLexicon.comma} ');
      }
    }
    output.write('${HTLexicon.roundRight}');

    return output.toString();
  }

  @override
  String visitFuncDeclStmt(FuncDeclExpr stmt) {
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
        output.write(HTLexicon.FACTORY);
        break;
      case FunctionCategory.factoryConstructor:
        output.write(HTLexicon.FACTORY);
        break;
      case FunctionCategory.getter:
        output.write(HTLexicon.GET);
        break;
      case FunctionCategory.setter:
        output.write(HTLexicon.SET);
        break;
    }
    if (stmt.externalTypeId != null) {
      output.write(
          ' ${HTLexicon.squareLeft}${stmt.externalTypeId}${HTLexicon.squareRight}');
    }
    if (stmt.id != null) {
      output.write(' ${stmt.id}');
    }
    final paramDeclString = printParamDecls(stmt.params);
    output.write(paramDeclString);

    output.write(' ');

    if (stmt.returnType != null) {
      output.write('${HTLexicon.singleArrow} ');
      final returnTypeString = visitTypeExpr(stmt.returnType!);
      output.write('$returnTypeString ');
    } else if (stmt.referConstructor != null) {
      output.write('${HTLexicon.colon} ');
      final referCtorString = visitReferConstructorExpr(stmt.referConstructor!);
      output.write('$referCtorString ');
    }

    if (stmt.definition != null) {
      final blockString = printAst(stmt.definition!);
      output.write(blockString);
    }
    return output.toString();
  }

  @override
  String visitClassDeclStmt(ClassDeclStmt stmt) {
    final output = StringBuffer();
    if (stmt.isExternal) {
      output.write('${HTLexicon.EXTERNAL} ');
    }
    if (stmt.isAbstract) {
      output.write('${HTLexicon.ABSTRACT} ');
    }
    output.write('${HTLexicon.CLASS} ${stmt.id} ');
    if (stmt.superType != null) {
      final superClassTypeString = visitTypeExpr(stmt.superType!);
      output.write('${HTLexicon.EXTENDS} $superClassTypeString ');
    }
    if (stmt.definition != null) {
      final blockString = visitBlockStmt(stmt.definition!);
      output.write(blockString);
    }
    return output.toString();
  }

  @override
  String visitEnumDeclStmt(EnumDeclStmt stmt) {
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

  @override
  String visitTypeAliasStmt(TypeAliasDeclStmt stmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.TYPE} ${stmt.id} ${HTLexicon.assign} ');
    final valueString = printAst(stmt.value);
    output.write(valueString);
    return output.toString();
  }
}
