import 'package:hetu_script/parser/parser_hetu.dart';

import '../ast/ast.dart';
import '../lexicon/lexicon.dart';
import '../lexicon/lexicon_hetu.dart';
import '../lexer/lexer.dart';
import '../lexer/lexer_hetu.dart';
import '../parser/parser.dart';
import '../common/function_category.dart';

class FormatterConfig {
  final int pageWidth;
  final bool formatStringMark;
  final bool preferApostrophe;
  final bool removeTrailingComma;
  final bool removeSemicolon;
  final String indent;

  const FormatterConfig({
    this.pageWidth = 80,
    this.formatStringMark = true,
    this.preferApostrophe = true,
    this.removeTrailingComma = true,
    this.removeSemicolon = true,
    this.indent = '  ',
  });
}

/// Class for printing out formatted string content of a ast root
class HTFormatter implements AbstractASTVisitor<String> {
  late final HTLexicon _lexicon;
  late final HTLexer _lexer;
  late final HTParser _parser;

  var _curIndentCount = 0;

  ASTNode? _lastStmt;

  FormatterConfig config;

  HTFormatter(
      {this.config = const FormatterConfig(),
      HTLexicon? lexicon,
      HTLexer? lexer,
      HTParser? parser})
      : _lexicon = lexicon ?? HTLexiconHetu(),
        _parser = parser ?? HTParserHetu() {
    _lexer = lexer ?? HTLexerHetu(lexicon: _lexicon);
  }

  String get curIndent {
    final output = StringBuffer();
    var i = _curIndentCount;
    while (i > 0) {
      output.write(config.indent);
      --i;
    }
    return output.toString();
  }

  String format(List<ASTNode> nodes, {FormatterConfig? config}) {
    final savedConfig = this.config;
    if (config != null) {
      this.config = config;
    }
    final output = StringBuffer();
    for (var i = 0; i < nodes.length; ++i) {
      final stmt = nodes[i];
      final stmtString = formatAST(stmt);
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
    final tokens = _lexer.lex(content);
    final nodes = _parser.parseTokens(tokens);
    final result = format(nodes, config: config);
    return result;
  }

  void formatSource(ASTSource result, {FormatterConfig? config}) {
    result.source!.content = format(result.nodes, config: config);
  }

  void formatModule(ASTCompilation compilation, {FormatterConfig? config}) {
    for (final result in compilation.values.values) {
      result.source!.content = format(result.nodes, config: config);
    }
    for (final result in compilation.sources.values) {
      result.source!.content = format(result.nodes, config: config);
    }
  }

  String formatAST(ASTNode node) => node.accept(this);

  @override
  String visitCompilation(ASTCompilation node) {
    throw 'Use formatModule instead of this method.';
  }

  @override
  String visitSource(ASTSource node) {
    throw 'Use formatSource instead of this method.';
  }

  @override
  String visitComment(ASTComment node) {
    return node.content;
  }

  @override
  String visitEmptyLine(ASTEmptyLine expr) {
    return '\n';
  }

  @override
  String visitEmptyExpr(ASTEmpty expr) {
    return '';
  }

  @override
  String visitNullExpr(ASTLiteralNull expr) {
    return _lexicon.kNull;
  }

  @override
  String visitBooleanExpr(ASTLiteralBoolean expr) {
    return expr.value ? _lexicon.kTrue : _lexicon.kFalse;
  }

  @override
  String visitIntLiteralExpr(ASTLiteralInteger expr) {
    return expr.value.toString();
  }

  @override
  String visitFloatLiteralExpr(ASTLiteralFloat expr) {
    return expr.value.toString();
  }

  @override
  String visitStringLiteralExpr(ASTLiteralString expr) {
    return _lexicon.stringify(expr.value, asStringLiteral: true);
  }

  @override
  String visitStringInterpolationExpr(ASTStringInterpolation expr) {
    final interpolation = <String>[];
    for (final node in expr.interpolations) {
      final nodeString = formatAST(node);
      interpolation.add(nodeString);
    }
    var output = expr.text;
    for (var i = 0; i < interpolation.length; ++i) {
      output = output.replaceAll(
          '${_lexicon.stringInterpolationStart}$i${_lexicon.stringInterpolationEnd}',
          '${_lexicon.stringInterpolationStart}${interpolation[i]}${_lexicon.stringInterpolationEnd}');
    }
    return "'$output'";
  }

  @override
  String visitSpreadExpr(SpreadExpr expr) {
    final output = StringBuffer();
    output.write(_lexicon.spreadSyntax);
    final valueString = formatAST(expr.collection);
    output.write(valueString);
    return output.toString();
  }

  @override
  String visitCommaExpr(CommaExpr expr) {
    final output = StringBuffer();
    output.write(
        expr.list.map((item) => formatAST(item)).join('${_lexicon.comma} '));
    return output.toString();
  }

  @override
  String visitListExpr(ListExpr expr) {
    final output = StringBuffer();
    output.write(_lexicon.listStart);
    output.write(
        expr.list.map((item) => formatAST(item)).join('${_lexicon.comma} '));
    output.write(_lexicon.listEnd);
    return output.toString();
  }

  @override
  String visitInOfExpr(InOfExpr expr) {
    final collection = formatAST(expr.collection);
    return '${_lexicon.kIn} $collection';
  }

  @override
  String visitGroupExpr(GroupExpr expr) {
    final inner = formatAST(expr.inner);
    return '${_lexicon.groupExprStart}$inner${_lexicon.groupExprEnd}';
  }

  @override
  String visitIdentifierExpr(IdentifierExpr expr) {
    if (expr.isMarked) {
      return '${_lexicon.identifierStart}${expr.id}${_lexicon.identifierEnd}';
    } else {
      return expr.id;
    }
  }

  @override
  String visitUnaryPrefixExpr(UnaryPrefixExpr expr) {
    final valueString = formatAST(expr.object);
    return '${expr.op}$valueString';
  }

  @override
  String visitBinaryExpr(BinaryExpr expr) {
    final leftString = formatAST(expr.left);
    final rightString = formatAST(expr.right);
    return '$leftString ${expr.op} $rightString';
  }

  @override
  String visitTernaryExpr(TernaryExpr expr) {
    final condition = formatAST(expr.condition);
    final thenBranch = formatAST(expr.thenBranch);
    final elseBranch = formatAST(expr.elseBranch);
    return '$condition ${_lexicon.ternaryThen} $thenBranch ${_lexicon.ternaryElse} $elseBranch';
  }

  @override
  String visitIntrinsicTypeExpr(IntrinsicTypeExpr expr) {
    return expr.id.id;
  }

  @override
  String visitNominalTypeExpr(NominalTypeExpr expr) {
    final output = StringBuffer();
    output.write(expr.id);
    if (expr.arguments.isNotEmpty) {
      output.write(_lexicon.typeListStart);
      for (final type in expr.arguments) {
        final typeString = formatAST(type);
        output.write(typeString);
      }
      output.write(_lexicon.typeListEnd);
    }
    if (expr.isNullable) {
      output.write(_lexicon.nullableTypePostfix);
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
        output.write(_lexicon.functionNamedParameterStart);
      }
      output.write('${expr.id}${_lexicon.typeIndicator} ');
    }
    if (expr.isOptionalPositional && !isOptional) {
      isOptional = true;
      output.write(_lexicon.functionPositionalParameterStart);
    }
    final typeString = formatAST(expr.declType);
    output.write(typeString);
    return output.toString();
  }

  @override
  String visitFunctionTypeExpr(FuncTypeExpr expr) {
    final output = StringBuffer();
    output.write('${_lexicon.kFunction} ${_lexicon.groupExprStart}');
    output.write(expr.paramTypes
        .map((param) => visitParamTypeExpr(param))
        .join('${_lexicon.comma} '));
    if (expr.hasOptionalParam) {
      output.write(_lexicon.functionPositionalParameterEnd);
    } else if (expr.hasNamedParam) {
      output.write(_lexicon.blockEnd);
    }
    output.write('${_lexicon.groupExprEnd} ${_lexicon.returnTypeIndicator} ');
    final returnTypeString = formatAST(expr.returnType);
    output.write(returnTypeString);
    return output.toString();
  }

  @override
  String visitFieldTypeExpr(FieldTypeExpr expr) {
    final output = StringBuffer();
    output.write(expr.id);
    final typeString = formatAST(expr.fieldType);
    output.write('${_lexicon.typeIndicator} $typeString');
    return output.toString();
  }

  @override
  String visitStructuralTypeExpr(StructuralTypeExpr expr) {
    final output = StringBuffer();
    output.writeln(_lexicon.structStart);
    ++_curIndentCount;
    for (var i = 0; i < expr.fieldTypes.length; ++i) {
      final field = expr.fieldTypes[i];
      final fieldString = visitFieldTypeExpr(field);
      output.write(curIndent);
      output.write(fieldString);
      if (i < expr.fieldTypes.length - 1) {
        output.writeln(_lexicon.comma);
      }
    }
    --_curIndentCount;
    output.writeln(_lexicon.structEnd);
    return output.toString();
  }

  @override
  String visitGenericTypeParamExpr(GenericTypeParameterExpr expr) {
    return expr.id.id;
  }

  @override
  String visitCallExpr(CallExpr expr) {
    final output = StringBuffer();
    final calleeString = formatAST(expr.callee);
    output.write('$calleeString${_lexicon.groupExprStart}');
    for (var i = 0; i < expr.positionalArgs.length; ++i) {
      final arg = expr.positionalArgs[i];
      final argString = formatAST(arg);
      output.write(argString);
      if ((i < expr.positionalArgs.length - 1) || expr.namedArgs.isNotEmpty) {
        output.write('${_lexicon.comma} ');
      }
    }
    if (expr.namedArgs.isNotEmpty) {
      output.write(expr.namedArgs.entries
          .toList()
          .map((entry) =>
              '${entry.key}${_lexicon.namedArgumentValueIndicator} ${formatAST(entry.value)}')
          .join('${_lexicon.comma} '));
    }
    output.write(_lexicon.groupExprEnd);
    return output.toString();
  }

  @override
  String visitUnaryPostfixExpr(UnaryPostfixExpr expr) {
    final valueString = formatAST(expr.object);
    return '$valueString${expr.op}';
  }

  @override
  String visitAssignExpr(AssignExpr expr) {
    final leftString = formatAST(expr.left);
    final rightString = formatAST(expr.right);
    return '$leftString ${expr.op} $rightString';
  }

  @override
  String visitMemberExpr(MemberExpr expr) {
    final collectionString = formatAST(expr.object);
    final keyString = formatAST(expr.key);
    return '$collectionString${_lexicon.memberGet}$keyString';
  }

  // @override
  // String visitMemberAssignExpr(MemberAssignExpr expr) {
  //   final collectionString = formatAst(expr.object);
  //   final keyString = visitIdentifierExpr(expr.key);
  //   final valueString = formatAst(expr.assignValue);
  //   return '$collectionString${_lexicon.memberGet}$keyString ${_lexicon.assign} $valueString';
  // }

  @override
  String visitSubExpr(SubExpr expr) {
    final collectionString = formatAST(expr.object);
    final keyString = formatAST(expr.key);
    return '$collectionString${_lexicon.subGetStart}$keyString${_lexicon.subGetEnd}';
  }

  // @override
  // String visitSubAssignExpr(SubAssignExpr expr) {
  //   final collectionString = formatAst(expr.array);
  //   final keyString = formatAst(expr.key);
  //   final valueString = formatAst(expr.assignValue);
  //   return '$collectionString${_lexicon.subGetStart}$keyString${_lexicon.subGetEnd} ${_lexicon.assign} $valueString';
  // }

  @override
  String visitAssertStmt(AssertStmt stmt) {
    final output = StringBuffer();
    output.write('${_lexicon.kAssert} ');
    final exprString = formatAST(stmt.expr);
    output.write(exprString);
    if (stmt.hasEndOfStmtMark) {
      output.write(_lexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitThrowStmt(ThrowStmt stmt) {
    final output = StringBuffer();
    output.write('${_lexicon.kThrow} ');
    final messageString = formatAST(stmt.message);
    output.write(messageString);
    if (stmt.hasEndOfStmtMark) {
      output.write(_lexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitExprStmt(ExprStmt stmt) {
    final output = StringBuffer();
    final exprString = formatAST(stmt.expr);
    output.write(exprString);
    if (stmt.hasEndOfStmtMark) {
      output.write(_lexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitBlockStmt(BlockStmt block) {
    final output = StringBuffer();
    if (block.statements.isNotEmpty) {
      output.writeln(' ${_lexicon.blockStart}');
      ++_curIndentCount;
      for (final stmt in block.statements) {
        final stmtString = formatAST(stmt);
        if (stmtString.isNotEmpty) {
          output.write(curIndent);
          output.writeln(stmtString);
        }
      }
      --_curIndentCount;
      output.write(curIndent);
      output.write(_lexicon.blockEnd);
    } else {
      output.write(' ${_lexicon.blockStart}${_lexicon.blockEnd}');
    }
    return output.toString();
  }

  @override
  String visitReturnStmt(ReturnStmt stmt) {
    final output = StringBuffer();
    output.write(_lexicon.kReturn);
    if (stmt.returnValue != null) {
      final valueString = formatAST(stmt.returnValue!);
      output.write(' $valueString');
    }
    if (stmt.hasEndOfStmtMark) {
      output.write(_lexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitIf(IfExpr ifStmt) {
    final output = StringBuffer();
    output.write('${_lexicon.kIf} ${_lexicon.groupExprStart}');
    final conditionString = formatAST(ifStmt.condition);
    output.write('$conditionString${_lexicon.groupExprEnd} ');
    final thenBranchString = formatAST(ifStmt.thenBranch);
    output.write(thenBranchString);
    if ((ifStmt.elseBranch is IfExpr) || (ifStmt.elseBranch is BlockStmt)) {
      output.write(' ${_lexicon.kElse} ');
      final elseBranchString = formatAST(ifStmt.elseBranch!);
      output.write(elseBranchString);
    } else if (ifStmt.elseBranch != null) {
      output.writeln(' ${_lexicon.kElse} ${_lexicon.blockStart}');
      ++_curIndentCount;
      output.write(curIndent);
      final elseBranchString = formatAST(ifStmt.elseBranch!);
      output.writeln(elseBranchString);
      --_curIndentCount;
      output.write(curIndent);
      output.write(_lexicon.blockEnd);
    }
    return output.toString();
  }

  @override
  String visitWhileStmt(WhileStmt whileStmt) {
    final output = StringBuffer();
    output.write('${_lexicon.kWhile} ');
    final conditionString = formatAST(whileStmt.condition);
    output.write('$conditionString ');
    final loopString = formatAST(whileStmt.loop);
    output.write(loopString);
    return output.toString();
  }

  @override
  String visitDoStmt(DoStmt doStmt) {
    final output = StringBuffer();
    output.write(_lexicon.kDo);
    final loopString = formatAST(doStmt.loop);
    output.write(loopString);
    if (doStmt.condition != null) {
      final conditionString = formatAST(doStmt.condition!);
      output.write(' ${_lexicon.kWhile} ');
      output.write(conditionString);
    }
    if (doStmt.hasEndOfStmtMark) {
      output.write(_lexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitForStmt(ForExpr forStmt) {
    final output = StringBuffer();
    output.write('${_lexicon.kFor} ');
    if (forStmt.hasBracket) {
      output.write(_lexicon.groupExprStart);
    }
    final declString = forStmt.init != null ? formatAST(forStmt.init!) : '';
    final conditionString =
        forStmt.condition != null ? formatAST(forStmt.condition!) : '';
    final incrementString =
        forStmt.increment != null ? formatAST(forStmt.increment!) : '';
    output.write(
        '$declString${_lexicon.endOfStatementMark} $conditionString${_lexicon.endOfStatementMark} $incrementString');
    if (forStmt.hasBracket) {
      output.write('${_lexicon.groupExprEnd} ');
    }
    final loopString = formatAST(forStmt.loop);
    output.write(loopString);
    return output.toString();
  }

  @override
  String visitForRangeStmt(ForRangeExpr forRangeStmt) {
    final output = StringBuffer();
    output.write('${_lexicon.kFor} ');
    if (forRangeStmt.hasBracket) {
      output.write(_lexicon.groupExprStart);
    }
    final declString = formatAST(forRangeStmt.iterator);
    final collectionString = formatAST(forRangeStmt.collection);
    output.write('$declString ${_lexicon.kIn} $collectionString');
    if (forRangeStmt.hasBracket) {
      output.write('${_lexicon.groupExprEnd} ');
    }
    final stmtString = formatAST(forRangeStmt.loop);
    output.write(stmtString);
    return output.toString();
  }

  @override
  String visitSwitch(SwitchStmt stmt) {
    final output = StringBuffer();
    output.write(_lexicon.kSwitch);
    if (stmt.condition != null) {
      final conditionString = formatAST(stmt.condition!);
      output.write(
          ' ${_lexicon.groupExprStart}$conditionString${_lexicon.groupExprEnd}');
    }
    output.writeln(' ${_lexicon.blockStart}');
    ++_curIndentCount;
    for (final option in stmt.cases.keys) {
      output.write(curIndent);
      final optionString = formatAST(option);
      output.write('$optionString ${_lexicon.switchBranchIndicator} ');
      final branchString = formatAST(stmt.cases[option]!);
      output.writeln(branchString);
    }
    if (stmt.elseBranch != null) {
      final elseBranchString = formatAST(stmt.elseBranch!);
      output.write(curIndent);
      output.writeln(
          '${_lexicon.kElse} ${_lexicon.switchBranchIndicator} $elseBranchString');
    }
    --_curIndentCount;
    output.write(curIndent);
    output.write(_lexicon.blockEnd);
    return output.toString();
  }

  @override
  String visitBreakStmt(BreakStmt stmt) {
    final output = StringBuffer();
    output.write(stmt.keyword.lexeme);
    if (stmt.hasEndOfStmtMark) {
      output.write(_lexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitContinueStmt(ContinueStmt stmt) {
    final output = StringBuffer();
    output.write(stmt.keyword.lexeme);
    if (stmt.hasEndOfStmtMark) {
      output.write(_lexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitDeleteStmt(DeleteStmt stmt) {
    final output = StringBuffer();
    output.write('${_lexicon.kDelete} ${stmt.symbol}');
    if (stmt.hasEndOfStmtMark) {
      output.write(_lexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitDeleteMemberStmt(DeleteMemberStmt stmt) {
    final output = StringBuffer();
    output.write('${_lexicon.kDelete} ');
    final objectString = formatAST(stmt.object);
    output.write('$objectString${_lexicon.memberGet}${stmt.key}');
    if (stmt.hasEndOfStmtMark) {
      output.write(_lexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitDeleteSubStmt(DeleteSubStmt stmt) {
    final output = StringBuffer();
    output.write('${_lexicon.kDelete} ');
    final objectString = formatAST(stmt.object);
    final keyString = formatAST(stmt.key);
    output.write(
        '$objectString${_lexicon.subGetStart}$keyString${_lexicon.subGetEnd}');
    if (stmt.hasEndOfStmtMark) {
      output.write(_lexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitImportExportDecl(ImportExportDecl stmt) {
    final output = StringBuffer();
    if (!stmt.isExport) {
      output.write('${_lexicon.kImport} ');
      if (stmt.showList.isNotEmpty) {
        output.write('${_lexicon.importExportListStart} ');
        output.write(stmt.showList.join('${_lexicon.comma} '));
        output.write(' ${_lexicon.importExportListEnd} ${_lexicon.kFrom} ');
      }
      output.write(
          '${_lexicon.stringStart1}${stmt.fromPath}${_lexicon.stringEnd1}');
      if (stmt.alias != null) {
        output.write(' ${_lexicon.kAs} ${stmt.alias}');
      }
    } else {
      output.write('${_lexicon.kExport} ');
      if (stmt.fromPath == null) {
        output.write(stmt.showList.join('${_lexicon.comma} '));
      } else {
        if (stmt.showList.isNotEmpty) {
          output.write('${_lexicon.importExportListStart} ');
          output.write(stmt.showList.join('${_lexicon.comma} '));
          output.write(' ${_lexicon.importExportListEnd} ${_lexicon.kFrom} ');
        }
        output.write(
            '${_lexicon.stringStart1}${stmt.fromPath}${_lexicon.stringEnd1}');
      }
    }
    if (stmt.hasEndOfStmtMark) {
      output.write(_lexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitNamespaceDecl(NamespaceDecl stmt) {
    final output = StringBuffer();
    output.write('${_lexicon.kNamespace} ${stmt.id.id} ');
    final blockString = visitBlockStmt(stmt.definition);
    output.write(blockString);
    return output.toString();
  }

  @override
  String visitTypeAliasDecl(TypeAliasDecl stmt) {
    final output = StringBuffer();
    output.write('${_lexicon.kTypeDef} ${stmt.id.id} ${_lexicon.assign} ');
    final valueString = formatAST(stmt.typeValue);
    output.write(valueString);
    if (stmt.hasEndOfStmtMark) {
      output.write(_lexicon.endOfStatementMark);
    }
    return output.toString();
  }

  // @override
  // String visitConstDecl(ConstDecl stmt) {
  //   final output = StringBuffer();
  //   output.write('${_lexicon.kConst} ${stmt.id.id} ${_lexicon.assign} ');
  //   final valueString = formatAst(stmt.constExpr);
  //   output.write(valueString);
  //   if (stmt.hasEndOfStmtMark) {
  //     output.write(_lexicon.semicolon);
  //   }
  //   return output.toString();
  // }

  @override
  String visitVarDecl(VarDecl stmt) {
    final output = StringBuffer();
    if (stmt.isExternal) {
      output.write('${_lexicon.kExternal} ');
    }
    if (stmt.isStatic) {
      output.write('${_lexicon.kStatic} ');
    }
    if (stmt.isConst) {
      output.write('${_lexicon.kConst} ');
    } else if (!stmt.isMutable) {
      output.write('${_lexicon.kImmutable} ');
    } else {
      output.write('${_lexicon.kMutable} ');
    }
    output.write(stmt.id.id);
    if (stmt.declType != null) {
      final typeString = formatAST(stmt.declType!);
      output.write('${_lexicon.typeIndicator} $typeString');
    }
    if (stmt.initializer != null) {
      final initString = formatAST(stmt.initializer!);
      output.write(' ${_lexicon.assign} $initString');
    }
    if (stmt.hasEndOfStmtMark) {
      output.write(_lexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitDestructuringDecl(DestructuringDecl stmt) {
    final output = StringBuffer();
    if (!stmt.isMutable) {
      output.write('${_lexicon.kImmutable} ');
    } else {
      output.write('${_lexicon.kMutables.first} ');
    }
    if (stmt.isVector) {
      output.write(_lexicon.listStart);
    } else {
      output.write(_lexicon.structStart);
    }
    for (var i = 0; i < stmt.ids.length; ++i) {
      output.write(' ');
      final id = stmt.ids.keys.elementAt(i);
      output.write(id.id);
      final typeExpr = stmt.ids[id];
      if (typeExpr != null) {
        final typeString = formatAST(typeExpr);
        output.write('${_lexicon.typeIndicator} $typeString');
      }
      if (i < stmt.ids.length - 1) {
        output.writeln(_lexicon.comma);
      }
    }
    if (stmt.isVector) {
      output.write(' ${_lexicon.listStart} ${_lexicon.assign} ');
    } else {
      output.write(' ${_lexicon.structStart} ${_lexicon.assign} ');
    }
    final initString = formatAST(stmt.initializer);
    output.write(initString);
    if (stmt.hasEndOfStmtMark) {
      output.write(_lexicon.endOfStatementMark);
    }
    return output.toString();
  }

  @override
  String visitParamDecl(ParamDecl stmt) {
    final output = StringBuffer();
    output.write(stmt.id.id);
    if (stmt.declType != null) {
      final typeString = formatAST(stmt.declType!);
      output.write('${_lexicon.typeIndicator} $typeString');
    }
    if (stmt.initializer != null) {
      final initString = formatAST(stmt.initializer!);
      output.write(' ${_lexicon.assign} $initString');
    }
    return output.toString();
  }

  @override
  String visitReferConstructCallExpr(RedirectingConstructorCallExpr stmt) {
    final output = StringBuffer();
    output.write(stmt.callee.id);
    if (stmt.key != null) {
      output.write('${_lexicon.memberGet}${stmt.key}');
    }
    if (stmt.hasEndOfStmtMark) {
      output.write(_lexicon.endOfStatementMark);
    }
    return output.toString();
  }

  String printParamDecls(List<ParamDecl> params) {
    final output = StringBuffer();
    var isOptional = false;
    var isNamed = false;
    output.write(_lexicon.groupExprStart);
    for (var i = 0; i < params.length; ++i) {
      final param = params[i];
      if (param.isOptional) {
        if (!isOptional) {
          isOptional = true;
          output.write(_lexicon.functionPositionalParameterStart);
        }
        if (param.isVariadic) {
          output.write('${_lexicon.variadicArgs} ');
        }
      } else if (param.isNamed && !isNamed) {
        isNamed = true;
        output.write(_lexicon.functionPositionalParameterStart);
      }
      final paramString = visitParamDecl(param);
      output.write(paramString);
      if (i < params.length - 1) {
        output.write('${_lexicon.comma} ');
      }
    }
    output.write(_lexicon.groupExprEnd);
    return output.toString();
  }

  @override
  String visitFuncDecl(FuncDecl stmt) {
    final output = StringBuffer();
    if (stmt.isExternal) {
      output.write('${_lexicon.kExternal} ');
    }
    if (stmt.isStatic) {
      output.write('${_lexicon.kStatic} ');
    }
    switch (stmt.category) {
      case FunctionCategory.normal:
      case FunctionCategory.literal:
        output.write(_lexicon.kFunction);
      case FunctionCategory.constructor:
        output.write(_lexicon.kFactory);
      case FunctionCategory.factoryConstructor:
        output.write(_lexicon.kFactory);
      case FunctionCategory.getter:
        output.write(_lexicon.kGet);
      case FunctionCategory.setter:
        output.write(_lexicon.kSet);
      default:
        break;
    }
    if (stmt.externalTypeId != null) {
      output.write(
          ' ${_lexicon.externalFunctionTypeDefStart}${stmt.externalTypeId}${_lexicon.externalFunctionTypeDefEnd}');
    }
    if (stmt.id != null) {
      output.write(' ${stmt.id!.id}');
    }
    final paramDeclString = printParamDecls(stmt.paramDecls);
    output.write('$paramDeclString ');
    if (stmt.returnType != null) {
      output.write('${_lexicon.returnTypeIndicator} ');
      final returnTypeString = formatAST(stmt.returnType!);
      output.write('$returnTypeString ');
    } else if (stmt.redirectingConstructorCall != null) {
      output.write('${_lexicon.constructorInitializationListIndicator} ');
      final referCtorString =
          visitReferConstructCallExpr(stmt.redirectingConstructorCall!);
      output.write('$referCtorString ');
    }
    if (stmt.definition != null) {
      final blockString = formatAST(stmt.definition!);
      output.write(blockString);
    }
    return output.toString();
  }

  @override
  String visitClassDecl(ClassDecl stmt) {
    final output = StringBuffer();
    if (stmt.isExternal) {
      output.write('${_lexicon.kExternal} ');
    }
    if (stmt.isAbstract) {
      output.write('${_lexicon.kAbstract} ');
    }
    output.write('${_lexicon.kClass} ${stmt.id.id} ');
    if (stmt.superType != null) {
      final superClassTypeString = formatAST(stmt.superType!);
      output.write('${_lexicon.kExtends} $superClassTypeString ');
    }
    final blockString = visitBlockStmt(stmt.definition);
    output.write(blockString);
    return output.toString();
  }

  @override
  String visitEnumDecl(EnumDecl stmt) {
    final output = StringBuffer();
    if (stmt.isExternal) {
      output.write('${_lexicon.kExternal} ');
    }
    output.writeln('${_lexicon.kEnum} ${stmt.id.id} ${_lexicon.enumStart}');
    ++_curIndentCount;
    output.write(stmt.enumerations.join('${_lexicon.comma}\n'));
    output.writeln();
    --_curIndentCount;
    output.write(curIndent);
    output.write(_lexicon.enumEnd);
    return output.toString();
  }

  @override
  String visitStructDecl(StructDecl stmt) {
    final output = StringBuffer();
    output.writeln('${_lexicon.kStruct} ${stmt.id.id} ${_lexicon.structStart}');
    ++_curIndentCount;
    for (var i = 0; i < stmt.definition.length; ++i) {
      final valueString = formatAST(stmt.definition[i]);
      output.writeln(valueString);
    }
    --_curIndentCount;
    output.write(curIndent);
    output.write(_lexicon.structEnd);
    return output.toString();
  }

  @override
  String visitStructObjField(StructObjField field) {
    final output = StringBuffer();
    if (field.key != null) {
      output.write('${field.key}${_lexicon.structValueIndicator} ');
      final valueString = formatAST(field.fieldValue);
      output.write(valueString);
    } else if (field.isSpread) {
      output.write(_lexicon.spreadSyntax);
      final valueString = formatAST(field.fieldValue);
      output.write(valueString);
    } else {
      // for (final comment in field.precedings) {
      //   output.writeln(comment.content);
      // }
    }
    return output.toString();
  }

  @override
  String visitStructObjExpr(StructObjExpr obj) {
    final output = StringBuffer();
    output.writeln(_lexicon.structStart);
    ++_curIndentCount;
    for (var i = 0; i < obj.fields.length; ++i) {
      final field = obj.fields[i];
      final fieldString = visitStructObjField(field);
      output.write(fieldString);
      if (i < obj.fields.length - 1) {
        output.write(_lexicon.comma);
      }
      output.writeln();
    }
    --_curIndentCount;
    output.write(curIndent);
    output.write(_lexicon.structEnd);
    return output.toString();
  }
}
