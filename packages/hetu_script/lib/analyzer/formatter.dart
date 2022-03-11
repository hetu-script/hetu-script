import '../ast/ast.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../lexer/lexer.dart';
import '../parser/parser.dart';
import '../shared/stringify.dart';

class FormatterConfig {
  final int pageWidth;
  final bool formatStringMark;
  final bool useApostrophe;
  final bool removeTrailingComma;
  final bool removeSemicolon;

  const FormatterConfig(
      {this.pageWidth = 80,
      this.formatStringMark = true,
      this.useApostrophe = true,
      this.removeTrailingComma = true,
      this.removeSemicolon = true});
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
      output.write(HTLexicon.indentSpaces);
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
      final stmtString = formatAst(stmt);
      if (stmtString.isNotEmpty) {
        if (_lastStmt is ImportExportDecl && stmt is! ImportExportDecl) {
          output.writeln('');
        }
        output.writeln(stmtString);
        if ((i < nodes.length - 1) &&
            (stmt is FuncDecl || stmt is ClassDecl || stmt is EnumDecl)) {
          output.writeln('');
        }
      }
      _lastStmt = stmt;
    }
    final result = output.toString();
    this.config = savedConfig;
    return result;
  }

  String formatString(String content, {FormatterConfig? config}) {
    final tokens = HTLexer().lex(content);
    final nodes = HTParser().parseToken(tokens);
    final result = format(nodes, config: config);
    return result;
  }

  void formatSource(AstSource result, {FormatterConfig? config}) {
    result.source!.content = format(result.nodes, config: config);
  }

  void formatModule(AstCompilation compilation, {FormatterConfig? config}) {
    for (final result in compilation.values.values) {
      result.source!.content = format(result.nodes, config: config);
    }
    for (final result in compilation.sources.values) {
      result.source!.content = format(result.nodes, config: config);
    }
  }

  String formatAst(AstNode node) => node.accept(this);

  @override
  String visitCompilation(AstCompilation node) {
    throw 'Use formatModule instead of this method.';
  }

  @override
  String visitCompilationUnit(AstSource node) {
    throw 'Use formatSource instead of this method.';
  }

  @override
  String visitEmptyExpr(EmptyLine expr) {
    return '';
  }

  @override
  String visitNullExpr(NullExpr expr) {
    return HTLexicon.kNull;
  }

  @override
  String visitBooleanExpr(BooleanLiteralExpr expr) {
    return expr.value ? HTLexicon.kTrue : HTLexicon.kFalse;
  }

  @override
  String visitIntLiteralExpr(IntegerLiteralExpr expr) {
    return expr.value.toString();
  }

  @override
  String visitFloatLiteralExpr(FloatLiteralExpr expr) {
    return expr.value.toString();
  }

  @override
  String visitStringLiteralExpr(StringLiteralExpr expr) {
    return stringify(expr.value, asStringLiteral: true);
  }

  @override
  String visitStringInterpolationExpr(StringInterpolationExpr expr) {
    final interpolation = <String>[];
    for (final node in expr.interpolations) {
      final nodeString = formatAst(node);
      interpolation.add(nodeString);
    }
    var output = expr.text;
    for (var i = 0; i < interpolation.length; ++i) {
      output = output.replaceAll(
          '${HTLexicon.functionBlockStart}$i${HTLexicon.functionBlockEnd}',
          '${HTLexicon.stringInterpolationStart}${interpolation[i]}${HTLexicon.stringInterpolationEnd}');
    }
    return "'$output'";
  }

  @override
  String visitSpreadExpr(SpreadExpr expr) {
    final output = StringBuffer();
    output.write(HTLexicon.spreadSyntax);
    final valueString = formatAst(expr.collection);
    output.write(valueString);
    return output.toString();
  }

  @override
  String visitCommaExpr(CommaExpr expr) {
    final output = StringBuffer();
    output.write(
        expr.list.map((item) => formatAst(item)).join('${HTLexicon.comma} '));
    return output.toString();
  }

  @override
  String visitListExpr(ListExpr expr) {
    final output = StringBuffer();
    output.write(HTLexicon.listStart);
    output.write(
        expr.list.map((item) => formatAst(item)).join('${HTLexicon.comma} '));
    output.write(HTLexicon.listEnd);
    return output.toString();
  }

  @override
  String visitInOfExpr(InOfExpr expr) {
    final collection = formatAst(expr.collection);
    return '${HTLexicon.kIn} $collection';
  }

  @override
  String visitGroupExpr(GroupExpr expr) {
    final inner = formatAst(expr.inner);
    return '${HTLexicon.groupExprStart}$inner${HTLexicon.groupExprEnd}';
  }

  @override
  String visitIdentifierExpr(IdentifierExpr expr) {
    return expr.id;
  }

  @override
  String visitUnaryPrefixExpr(UnaryPrefixExpr expr) {
    final valueString = formatAst(expr.object);
    return '${expr.op}$valueString';
  }

  @override
  String visitBinaryExpr(BinaryExpr expr) {
    final leftString = formatAst(expr.left);
    final rightString = formatAst(expr.right);
    return '$leftString ${expr.op} $rightString';
  }

  @override
  String visitTernaryExpr(TernaryExpr expr) {
    final condition = formatAst(expr.condition);
    final thenBranch = formatAst(expr.thenBranch);
    final elseBranch = formatAst(expr.elseBranch);
    return '$condition ${HTLexicon.condition} $thenBranch ${HTLexicon.elseBranch} $elseBranch';
  }

  @override
  String visitTypeExpr(TypeExpr expr) {
    final output = StringBuffer();
    output.write(expr.id);
    if (expr.arguments.isNotEmpty) {
      output.write(HTLexicon.typeParameterStart);
      for (final type in expr.arguments) {
        final typeString = visitTypeExpr(type);
        output.write(typeString);
      }
      output.write(HTLexicon.typeParameterEnd);
    }
    if (expr.isNullable) {
      output.write(HTLexicon.nullable);
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
        output.write(HTLexicon.functionBlockStart);
      }
      output.write('${expr.id}${HTLexicon.colon} ');
    }
    if (expr.isOptional && !isOptional) {
      isOptional = true;
      output.write(HTLexicon.optionalPositionalParameterStart);
    }
    final typeString = visitTypeExpr(expr.declType);
    output.write(typeString);
    return output.toString();
  }

  @override
  String visitFunctionTypeExpr(FuncTypeExpr expr) {
    final output = StringBuffer();
    output.write('${HTLexicon.kFun} ${HTLexicon.groupExprStart}');
    output.write(expr.paramTypes
        .map((param) => visitParamTypeExpr(param))
        .join('${HTLexicon.comma} '));
    if (expr.hasOptionalParam) {
      output.write(HTLexicon.optionalPositionalParameterEnd);
    } else if (expr.hasNamedParam) {
      output.write(HTLexicon.functionBlockEnd);
    }
    output.write(
        '${HTLexicon.groupExprEnd} ${HTLexicon.functionReturnTypeIndicator} ');
    final returnTypeString = visitTypeExpr(expr.returnType);
    output.write(returnTypeString);
    return output.toString();
  }

  @override
  String visitFieldTypeExpr(FieldTypeExpr expr) {
    final output = StringBuffer();
    output.write(expr.id);
    final typeString = visitTypeExpr(expr.fieldType);
    output.write('${HTLexicon.colon} $typeString');
    return output.toString();
  }

  @override
  String visitStructuralTypeExpr(StructuralTypeExpr expr) {
    final output = StringBuffer();
    output.writeln(HTLexicon.functionBlockStart);
    ++_curIndentCount;
    for (var i = 0; i < expr.fieldTypes.length; ++i) {
      final field = expr.fieldTypes[i];
      final fieldString = visitFieldTypeExpr(field);
      output.write(curIndent);
      output.write(fieldString);
      if (i < expr.fieldTypes.length - 1) {
        output.writeln(HTLexicon.comma);
      }
    }
    --_curIndentCount;
    output.writeln(HTLexicon.functionBlockEnd);
    return output.toString();
  }

  @override
  String visitGenericTypeParamExpr(GenericTypeParameterExpr expr) {
    return expr.id.id;
  }

  @override
  String visitCallExpr(CallExpr expr) {
    final output = StringBuffer();
    final calleeString = formatAst(expr.callee);
    output.write('$calleeString${HTLexicon.groupExprStart}');
    for (var i = 0; i < expr.positionalArgs.length; ++i) {
      final arg = expr.positionalArgs[i];
      final argString = formatAst(arg);
      output.write(argString);
      if ((i < expr.positionalArgs.length - 1) || expr.namedArgs.isNotEmpty) {
        output.write('${HTLexicon.comma} ');
      }
    }
    if (expr.namedArgs.isNotEmpty) {
      output.write(expr.namedArgs.entries
          .toList()
          .map((entry) =>
              '${entry.key}${HTLexicon.colon} ${formatAst(entry.value)}')
          .join('${HTLexicon.comma} '));
    }
    output.write(HTLexicon.groupExprEnd);
    return output.toString();
  }

  @override
  String visitUnaryPostfixExpr(UnaryPostfixExpr expr) {
    final valueString = formatAst(expr.object);
    return '$valueString${expr.op}';
  }

  @override
  String visitMemberExpr(MemberExpr expr) {
    final collectionString = formatAst(expr.object);
    final keyString = formatAst(expr.key);
    return '$collectionString${HTLexicon.memberGet}$keyString';
  }

  @override
  String visitMemberAssignExpr(MemberAssignExpr expr) {
    final collectionString = formatAst(expr.object);
    final keyString = visitIdentifierExpr(expr.key);
    final valueString = formatAst(expr.assignValue);
    return '$collectionString${HTLexicon.memberGet}$keyString ${HTLexicon.assign} $valueString';
  }

  @override
  String visitSubExpr(SubExpr expr) {
    final collectionString = formatAst(expr.object);
    final keyString = formatAst(expr.key);
    return '$collectionString${HTLexicon.subGetStart}$keyString${HTLexicon.subGetEnd}';
  }

  @override
  String visitSubAssignExpr(SubAssignExpr expr) {
    final collectionString = formatAst(expr.array);
    final keyString = formatAst(expr.key);
    final valueString = formatAst(expr.assignValue);
    return '$collectionString${HTLexicon.subGetStart}$keyString${HTLexicon.subGetEnd} ${HTLexicon.assign} $valueString';
  }

  @override
  String visitAssertStmt(AssertStmt stmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kAssert} ');
    final exprString = formatAst(stmt.expr);
    output.write(exprString);
    if (stmt.hasEndOfStmtMark) {
      output.write(HTLexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitThrowStmt(ThrowStmt stmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kThrow} ');
    final messageString = formatAst(stmt.message);
    output.write(messageString);
    if (stmt.hasEndOfStmtMark) {
      output.write(HTLexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitExprStmt(ExprStmt stmt) {
    final output = StringBuffer();
    final exprString = formatAst(stmt.expr);
    output.write(exprString);
    if (stmt.hasEndOfStmtMark) {
      output.write(HTLexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitBlockStmt(BlockStmt block) {
    final output = StringBuffer();
    if (block.statements.isNotEmpty) {
      output.writeln(' ${HTLexicon.functionBlockStart}');
      ++_curIndentCount;
      for (final stmt in block.statements) {
        final stmtString = formatAst(stmt);
        if (stmtString.isNotEmpty) {
          output.write(curIndent);
          output.writeln(stmtString);
        }
      }
      --_curIndentCount;
      output.write(curIndent);
      output.write(HTLexicon.functionBlockEnd);
    } else {
      output.write(
          ' ${HTLexicon.functionBlockStart}${HTLexicon.functionBlockEnd}');
    }
    return output.toString();
  }

  @override
  String visitReturnStmt(ReturnStmt stmt) {
    final output = StringBuffer();
    output.write(HTLexicon.kReturn);
    if (stmt.returnValue != null) {
      final valueString = formatAst(stmt.returnValue!);
      output.write(' $valueString');
    }
    if (stmt.hasEndOfStmtMark) {
      output.write(HTLexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitIf(IfStmt ifStmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kIf} ${HTLexicon.groupExprStart}');
    final conditionString = formatAst(ifStmt.condition);
    output.write('$conditionString${HTLexicon.groupExprEnd} ');
    final thenBranchString = formatAst(ifStmt.thenBranch);
    output.write(thenBranchString);
    if ((ifStmt.elseBranch is IfStmt) || (ifStmt.elseBranch is BlockStmt)) {
      output.write(' ${HTLexicon.kElse} ');
      final elseBranchString = formatAst(ifStmt.elseBranch!);
      output.write(elseBranchString);
    } else if (ifStmt.elseBranch != null) {
      output.writeln(' ${HTLexicon.kElse} ${HTLexicon.functionBlockStart}');
      ++_curIndentCount;
      output.write(curIndent);
      final elseBranchString = formatAst(ifStmt.elseBranch!);
      output.writeln(elseBranchString);
      --_curIndentCount;
      output.write(curIndent);
      output.write(HTLexicon.functionBlockEnd);
    }
    return output.toString();
  }

  @override
  String visitWhileStmt(WhileStmt whileStmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kWhile} ');
    final conditionString = formatAst(whileStmt.condition);
    output.write('$conditionString ');
    final loopString = formatAst(whileStmt.loop);
    output.write(loopString);
    return output.toString();
  }

  @override
  String visitDoStmt(DoStmt doStmt) {
    final output = StringBuffer();
    output.write(HTLexicon.kDo);
    final loopString = formatAst(doStmt.loop);
    output.write(loopString);
    if (doStmt.condition != null) {
      final conditionString = formatAst(doStmt.condition!);
      output.write(' ${HTLexicon.kWhile} ');
      output.write(conditionString);
    }
    return output.toString();
  }

  @override
  String visitForStmt(ForStmt forStmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kFor} ');
    if (forStmt.hasBracket) {
      output.write(HTLexicon.groupExprStart);
    }
    final declString = forStmt.init != null ? formatAst(forStmt.init!) : '';
    final conditionString =
        forStmt.condition != null ? formatAst(forStmt.condition!) : '';
    final incrementString =
        forStmt.increment != null ? formatAst(forStmt.increment!) : '';
    output.write(
        '$declString${HTLexicon.endOfStatementMark} $conditionString${HTLexicon.endOfStatementMark} $incrementString');
    if (forStmt.hasBracket) {
      output.write('${HTLexicon.groupExprEnd} ');
    }
    final loopString = formatAst(forStmt.loop);
    output.write(loopString);
    return output.toString();
  }

  @override
  String visitForRangeStmt(ForRangeStmt forRangeStmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kFor} ');
    if (forRangeStmt.hasBracket) {
      output.write(HTLexicon.groupExprStart);
    }
    final declString = formatAst(forRangeStmt.iterator);
    final collectionString = formatAst(forRangeStmt.collection);
    output.write('$declString ${HTLexicon.kIn} $collectionString');
    if (forRangeStmt.hasBracket) {
      output.write('${HTLexicon.groupExprEnd} ');
    }
    final stmtString = formatAst(forRangeStmt.loop);
    output.write(stmtString);
    return output.toString();
  }

  @override
  String visitWhen(WhenStmt stmt) {
    final output = StringBuffer();
    output.write(HTLexicon.kWhen);
    if (stmt.condition != null) {
      final conditionString = formatAst(stmt.condition!);
      output.write(
          ' ${HTLexicon.groupExprStart}$conditionString${HTLexicon.groupExprEnd}');
    }
    output.writeln(' ${HTLexicon.functionBlockStart}');
    ++_curIndentCount;
    for (final option in stmt.cases.keys) {
      output.write(curIndent);
      final optionString = formatAst(option);
      output.write('$optionString ${HTLexicon.whenBranchIndicator} ');
      final branchString = formatAst(stmt.cases[option]!);
      output.writeln(branchString);
    }
    if (stmt.elseBranch != null) {
      final elseBranchString = formatAst(stmt.elseBranch!);
      output.write(curIndent);
      output.writeln(
          '${HTLexicon.kElse} ${HTLexicon.whenBranchIndicator} $elseBranchString');
    }
    --_curIndentCount;
    output.write(curIndent);
    output.write(HTLexicon.functionBlockEnd);
    return output.toString();
  }

  @override
  String visitBreakStmt(BreakStmt stmt) {
    final output = StringBuffer();
    output.write(stmt.keyword.lexeme);
    if (stmt.hasEndOfStmtMark) {
      output.write(HTLexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitContinueStmt(ContinueStmt stmt) {
    final output = StringBuffer();
    output.write(stmt.keyword.lexeme);
    if (stmt.hasEndOfStmtMark) {
      output.write(HTLexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitDeleteStmt(DeleteStmt stmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kDelete} ${stmt.symbol}');
    if (stmt.hasEndOfStmtMark) {
      output.write(HTLexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitDeleteMemberStmt(DeleteMemberStmt stmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kDelete} ');
    final objectString = formatAst(stmt.object);
    output.write('$objectString${HTLexicon.memberGet}${stmt.key}');
    if (stmt.hasEndOfStmtMark) {
      output.write(HTLexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitDeleteSubStmt(DeleteSubStmt stmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kDelete} ');
    final objectString = formatAst(stmt.object);
    final keyString = formatAst(stmt.key);
    output.write(
        '$objectString${HTLexicon.subGetStart}$keyString${HTLexicon.subGetEnd}');
    if (stmt.hasEndOfStmtMark) {
      output.write(HTLexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitImportExportDecl(ImportExportDecl stmt) {
    final output = StringBuffer();
    if (!stmt.isExport) {
      output.write('${HTLexicon.kImport} ');
      if (stmt.showList.isNotEmpty) {
        output.write('${HTLexicon.functionBlockStart} ');
        output.write(stmt.showList.join('${HTLexicon.comma} '));
        output.write(' ${HTLexicon.functionBlockEnd} ${HTLexicon.kFrom} ');
      }
      output.write(
          '${HTLexicon.apostropheStringLeft}${stmt.fromPath}${HTLexicon.apostropheStringRight}');
      if (stmt.alias != null) {
        output.write(' ${HTLexicon.kAs} ${stmt.alias}');
      }
    } else {
      output.write('${HTLexicon.kExport} ');
      if (stmt.fromPath == null) {
        output.write(stmt.showList.join('${HTLexicon.comma} '));
      } else {
        if (stmt.showList.isNotEmpty) {
          output.write('${HTLexicon.functionBlockStart} ');
          output.write(stmt.showList.join('${HTLexicon.comma} '));
          output.write(' ${HTLexicon.functionBlockEnd} ${HTLexicon.kFrom} ');
        }
        output.write(
            '${HTLexicon.apostropheStringLeft}${stmt.fromPath}${HTLexicon.apostropheStringRight}');
      }
    }
    if (stmt.hasEndOfStmtMark) {
      output.write(HTLexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitNamespaceDecl(NamespaceDecl stmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kNamespace} ${stmt.id.id} ');
    final blockString = visitBlockStmt(stmt.definition);
    output.write(blockString);
    return output.toString();
  }

  @override
  String visitTypeAliasDecl(TypeAliasDecl stmt) {
    final output = StringBuffer();
    output.write('${HTLexicon.kType} ${stmt.id.id} ${HTLexicon.assign} ');
    final valueString = formatAst(stmt.typeValue);
    output.write(valueString);
    if (stmt.hasEndOfStmtMark) {
      output.write(HTLexicon.endOfStatementMark);
    }
    return output.toString();
  }

  // @override
  // String visitConstDecl(ConstDecl stmt) {
  //   final output = StringBuffer();
  //   output.write('${HTLexicon.kConst} ${stmt.id.id} ${HTLexicon.assign} ');
  //   final valueString = formatAst(stmt.constExpr);
  //   output.write(valueString);
  //   if (stmt.hasEndOfStmtMark) {
  //     output.write(HTLexicon.semicolon);
  //   }
  //   return output.toString();
  // }

  @override
  String visitVarDecl(VarDecl stmt) {
    final output = StringBuffer();
    if (stmt.isExternal) {
      output.write('${HTLexicon.kExternal} ');
    }
    if (stmt.isStatic) {
      output.write('${HTLexicon.kStatic} ');
    }
    if (stmt.isConst) {
      output.write('${HTLexicon.kConst} ');
    } else if (!stmt.isMutable) {
      output.write('${HTLexicon.kFinal} ');
    } else {
      output.write('${HTLexicon.kVar} ');
    }
    output.write(stmt.id.id);
    if (stmt.declType != null) {
      final typeString = formatAst(stmt.declType!);
      output.write('${HTLexicon.colon} $typeString');
    }
    if (stmt.initializer != null) {
      final initString = formatAst(stmt.initializer!);
      output.write(' ${HTLexicon.assign} $initString');
    }
    if (stmt.hasEndOfStmtMark) {
      output.write(HTLexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitDestructuringDecl(DestructuringDecl stmt) {
    final output = StringBuffer();
    if (!stmt.isMutable) {
      output.write('${HTLexicon.kFinal} ');
    } else {
      output.write('${HTLexicon.kVar} ');
    }
    if (stmt.isVector) {
      output.write(HTLexicon.listStart);
    } else {
      output.write(HTLexicon.functionBlockStart);
    }
    for (var i = 0; i < stmt.ids.length; ++i) {
      output.write(' ');
      final id = stmt.ids.keys.elementAt(i);
      output.write(id.id);
      final typeExpr = stmt.ids[id];
      if (typeExpr != null) {
        final typeString = visitTypeExpr(typeExpr);
        output.write('${HTLexicon.colon} $typeString');
      }
      if (i < stmt.ids.length - 1) {
        output.writeln(HTLexicon.comma);
      }
    }
    if (stmt.isVector) {
      output.write(' ${HTLexicon.listStart} ${HTLexicon.assign} ');
    } else {
      output.write(' ${HTLexicon.functionBlockStart} ${HTLexicon.assign} ');
    }
    final initString = formatAst(stmt.initializer);
    output.write(initString);
    if (stmt.hasEndOfStmtMark) {
      output.write(HTLexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitParamDecl(ParamDecl stmt) {
    final output = StringBuffer();
    output.write(stmt.id.id);
    if (stmt.declType != null) {
      final typeString = formatAst(stmt.declType!);
      output.write('${HTLexicon.colon} $typeString');
    }
    if (stmt.initializer != null) {
      final initString = formatAst(stmt.initializer!);
      output.write(' ${HTLexicon.assign} $initString');
    }
    return output.toString();
  }

  @override
  String visitReferConstructCallExpr(RedirectingConstructorCallExpr stmt) {
    final output = StringBuffer();
    output.write(stmt.callee.id);
    if (stmt.key != null) {
      output.write('${HTLexicon.memberGet}${stmt.key}');
    }
    if (stmt.hasEndOfStmtMark) {
      output.write(HTLexicon.endOfStatementMark);
    }
    return output.toString();
  }

  String printParamDecls(List<ParamDecl> params) {
    final output = StringBuffer();
    var isOptional = false;
    var isNamed = false;
    output.write(HTLexicon.groupExprStart);
    for (var i = 0; i < params.length; ++i) {
      final param = params[i];
      if (param.isOptional) {
        if (!isOptional) {
          isOptional = true;
          output.write(HTLexicon.optionalPositionalParameterStart);
        }
        if (param.isVariadic) {
          output.write('${HTLexicon.variadicArgs} ');
        }
      } else if (param.isNamed && !isNamed) {
        isNamed = true;
        output.write(HTLexicon.optionalPositionalParameterStart);
      }
      final paramString = visitParamDecl(param);
      output.write(paramString);
      if (i < params.length - 1) {
        output.write('${HTLexicon.comma} ');
      }
    }
    output.write(HTLexicon.groupExprEnd);
    return output.toString();
  }

  @override
  String visitFuncDecl(FuncDecl stmt) {
    final output = StringBuffer();
    if (stmt.isExternal) {
      output.write('${HTLexicon.kExternal} ');
    }
    if (stmt.isStatic) {
      output.write('${HTLexicon.kStatic} ');
    }
    switch (stmt.category) {
      case FunctionCategory.normal:
      case FunctionCategory.method:
      case FunctionCategory.literal:
        output.write(HTLexicon.kFun);
        break;
      case FunctionCategory.constructor:
        output.write(HTLexicon.kFactory);
        break;
      case FunctionCategory.factoryConstructor:
        output.write(HTLexicon.kFactory);
        break;
      case FunctionCategory.getter:
        output.write(HTLexicon.kGet);
        break;
      case FunctionCategory.setter:
        output.write(HTLexicon.kSet);
        break;
      default:
        break;
    }
    if (stmt.externalTypeId != null) {
      output.write(
          ' ${HTLexicon.externalFunctionTypeDefStart}${stmt.externalTypeId}${HTLexicon.externalFunctionTypeDefEnd}');
    }
    if (stmt.id != null) {
      output.write(' ${stmt.id!.id}');
    }
    final paramDeclString = printParamDecls(stmt.paramDecls);
    output.write('$paramDeclString ');
    if (stmt.returnType != null) {
      output.write('${HTLexicon.functionReturnTypeIndicator} ');
      final returnTypeString = visitTypeExpr(stmt.returnType!);
      output.write('$returnTypeString ');
    } else if (stmt.redirectingCtorCallExpr != null) {
      output.write('${HTLexicon.colon} ');
      final referCtorString =
          visitReferConstructCallExpr(stmt.redirectingCtorCallExpr!);
      output.write('$referCtorString ');
    }
    if (stmt.definition != null) {
      final blockString = formatAst(stmt.definition!);
      output.write(blockString);
    }
    return output.toString();
  }

  @override
  String visitClassDecl(ClassDecl stmt) {
    final output = StringBuffer();
    if (stmt.isExternal) {
      output.write('${HTLexicon.kExternal} ');
    }
    if (stmt.isAbstract) {
      output.write('${HTLexicon.kAbstract} ');
    }
    output.write('${HTLexicon.kClass} ${stmt.id.id} ');
    if (stmt.superType != null) {
      final superClassTypeString = visitTypeExpr(stmt.superType!);
      output.write('${HTLexicon.kExtends} $superClassTypeString ');
    }
    final blockString = visitBlockStmt(stmt.definition);
    output.write(blockString);
    return output.toString();
  }

  @override
  String visitEnumDecl(EnumDecl stmt) {
    final output = StringBuffer();
    if (stmt.isExternal) {
      output.write('${HTLexicon.kExternal} ');
    }
    output.writeln(
        '${HTLexicon.kEnum} ${stmt.id.id} ${HTLexicon.functionBlockStart}');
    ++_curIndentCount;
    output.write(stmt.enumerations.join('${HTLexicon.comma}\n'));
    output.writeln();
    --_curIndentCount;
    output.write(curIndent);
    output.write(HTLexicon.functionBlockEnd);
    return output.toString();
  }

  @override
  String visitStructDecl(StructDecl stmt) {
    final output = StringBuffer();
    output.writeln(
        '${HTLexicon.kStruct} ${stmt.id.id} ${HTLexicon.functionBlockStart}');
    ++_curIndentCount;
    for (var i = 0; i < stmt.definition.length; ++i) {
      final valueString = formatAst(stmt.definition[i]);
      output.writeln(valueString);
    }
    --_curIndentCount;
    output.write(curIndent);
    output.write(HTLexicon.functionBlockEnd);
    return output.toString();
  }

  @override
  String visitStructObjField(StructObjField field) {
    final output = StringBuffer();
    if (field.key != null) {
      output.write('${field.key}${HTLexicon.colon} ');
      final valueString = formatAst(field.fieldValue!);
      output.write(valueString);
    } else if (field.isSpread) {
      output.write(HTLexicon.spreadSyntax);
      final valueString = formatAst(field.fieldValue!);
      output.write(valueString);
    } else {
      for (final comment in field.precedingComments) {
        output.writeln(comment.content);
      }
    }
    return output.toString();
  }

  @override
  String visitStructObjExpr(StructObjExpr obj) {
    final output = StringBuffer();
    output.writeln(HTLexicon.functionBlockStart);
    ++_curIndentCount;
    for (var i = 0; i < obj.fields.length; ++i) {
      final field = obj.fields[i];
      final fieldString = visitStructObjField(field);
      output.write(fieldString);
      if (i < obj.fields.length - 1) {
        output.write(HTLexicon.comma);
      }
      output.writeln();
    }
    --_curIndentCount;
    output.write(curIndent);
    output.write(HTLexicon.functionBlockEnd);
    return output.toString();
  }
}
