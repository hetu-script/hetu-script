import 'package:path/path.dart' as path;

import '../context/context.dart';
import '../grammar/lexicon.dart';
import '../lexer/token.dart';
import '../grammar/semantic.dart';
import '../source/source.dart';
import '../declaration/class/class_declaration.dart';
import '../error/error.dart';
import '../ast/ast.dart';
import 'parse_result.dart';
import 'parse_result_collection.dart';
// import '../error/error_handler.dart';
import 'abstract_parser.dart';
import '../lexer/lexer.dart';

/// Scans a token list and generates a abstract syntax tree.
class HTParser extends HTAbstractParser {
  final _curModuleImports = <ImportDecl>[];

  String? _curModuleFullName;
  @override
  String? get curModuleFullName => _curModuleFullName;

  late String _curLibraryName;
  @override
  String? get curLibraryName => _curLibraryName;

  HTClassDeclaration? _curClass;
  FunctionCategory? _curFuncCategory;

  var _leftValueLegality = false;
  final List<Map<String, String>> _markedSymbolsList = [];

  bool _isLibraryEntry = false;

  bool _hasUserDefinedConstructor = false;

  HTSource? _curSource;

  final _cachedResults = <String, HTModuleParseResult>{};

  @override
  final HTContext context;

  HTParser({HTContext? context}) : context = context ?? HTContext.fileSystem();

  /// Will use [type] when possible, then [source.type], then [SourceType.module]
  List<AstNode> parse(List<Token> tokens,
      {HTSource? source, SourceType? type, ParserConfig? config}) {
    final nodes = <AstNode>[];
    _curSource = source;
    _curModuleFullName = source?.fullName;
    errors.clear();
    setTokens(tokens);
    while (curTok.type != SemanticNames.endOfFile) {
      if (curTok.type == SemanticNames.emptyLine) {
        advance(1);
        // final empty = advance(1);
        // final stmt = EmptyExpr(
        //     line: empty.line, column: empty.column, offset: empty.offset);
        // nodes.add(stmt);
      } else {
        final stmt = _parseStmt(
            sourceType: type ?? _curSource?.type ?? SourceType.module);
        if (stmt != null) {
          nodes.add(stmt);
        }
      }
    }
    if (nodes.isEmpty) {
      // tokens can not be empty, lexer will insert a empty line token anyway
      final empty = EmptyExpr(
          source: _curSource,
          line: tokens.first.line,
          column: tokens.first.column,
          offset: tokens.first.offset,
          length: tokens.last.end - tokens.first.offset);
      nodes.add(empty);
    }
    return nodes;
  }

  List<AstNode> parseString(String content, {HTSource? source}) {
    final tokens = HTLexer().lex(content);
    final nodes = parse(tokens, source: source);
    return nodes;
  }

  HTModuleParseResult parseToModule(HTSource source, {String? libraryName}) {
    _curLibraryName = libraryName ?? source.fullName;
    _curModuleFullName = source.fullName;
    _curClass = null;
    _curFuncCategory = null;
    final nodes = parseString(source.content, source: source);
    final module = HTModuleParseResult(source, nodes,
        isLibraryEntry: _isLibraryEntry,
        libraryName: libraryName,
        imports: _curModuleImports.toList(),
        errors: errors); // copy the list);
    _curModuleImports.clear();
    return module;
  }

  /// Parse a string content and generate a library,
  /// will import other files.
  HTModuleParseResultCompilation parseToCompilation(HTSource source,
      {String? libraryName}) {
    final module = parseToModule(source, libraryName: libraryName);
    final results = <String, HTModuleParseResult>{};

    void handleImport(HTModuleParseResult module) {
      for (final decl in module.imports) {
        try {
          late final HTModuleParseResult importModule;
          final importFullName = HTContext.getAbsolutePath(
              key: decl.key, dirName: path.dirname(module.fullName));
          decl.fullName = importFullName;
          if (_cachedResults.containsKey(importFullName)) {
            importModule = _cachedResults[importFullName]!;
          } else {
            final source2 = context.getSource(importFullName);
            importModule = parseToModule(source2, libraryName: _curLibraryName);
            _cachedResults[importFullName] = importModule;
          }
          results[importFullName] = importModule;
          handleImport(importModule);
        } catch (error) {
          final sourceProviderError = HTError.sourceProviderError(decl.key,
              moduleFullName: source.fullName,
              line: decl.line,
              column: decl.column,
              offset: decl.offset,
              length: decl.length);
          errors.add(sourceProviderError);
        }
      }
    }

    handleImport(module);
    results[module.fullName] = module;
    final compilation = HTModuleParseResultCompilation(results);
    return compilation;
  }

  AstNode? _parseStmt({SourceType sourceType = SourceType.function}) {
    switch (sourceType) {
      case SourceType.script:
        if (curTok.lexeme == HTLexicon.IMPORT) {
          return _parseImportDecl();
        } else if (curTok.lexeme == HTLexicon.TYPE) {
          return _parseTypeAliasDecl();
        } else {
          switch (curTok.type) {
            case SemanticNames.singleLineComment:
            case SemanticNames.multiLineComment:
              return _parseExprStmt();
            case HTLexicon.EXPORT:
              advance(1);
              switch (curTok.type) {
                case HTLexicon.ABSTRACT:
                  advance(1);
                  return _parseClassDecl(
                      isAbstract: true,
                      isExternal: true,
                      isExported: true,
                      isTopLevel: true);
                case HTLexicon.CLASS:
                  return _parseClassDecl(
                      isExternal: true, isExported: true, isTopLevel: true);
                case HTLexicon.ENUM:
                  return _parseEnumDecl(
                      isExternal: true, isExported: true, isTopLevel: true);
                case HTLexicon.VAR:
                  return _parseVarDecl(
                      isMutable: true, isExported: true, isTopLevel: true);
                case HTLexicon.FINAL:
                  return _parseVarDecl(isExported: true, isTopLevel: true);
                case HTLexicon.FUNCTION:
                  return _parseFuncDecl(
                      isExternal: true, isExported: true, isTopLevel: true);
                default:
                  final err = HTError.unexpected(
                      SemanticNames.declStmt, curTok.lexeme,
                      moduleFullName: _curModuleFullName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors.add(err);
                  advance(1);
                  return null;
              }
            case HTLexicon.EXTERNAL:
              advance(1);
              switch (curTok.type) {
                case HTLexicon.ABSTRACT:
                  advance(1);
                  return _parseClassDecl(
                      isAbstract: true, isExternal: true, isTopLevel: true);
                case HTLexicon.CLASS:
                  return _parseClassDecl(isExternal: true, isTopLevel: true);
                case HTLexicon.ENUM:
                  return _parseEnumDecl(isExternal: true, isTopLevel: true);
                case HTLexicon.VAR:
                case HTLexicon.FINAL:
                  final err = HTError.externalVar(
                      moduleFullName: _curModuleFullName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors.add(err);
                  advance(1);
                  return null;
                case HTLexicon.FUNCTION:
                  return _parseFuncDecl(isExternal: true, isTopLevel: true);
                default:
                  final err = HTError.unexpected(
                      SemanticNames.declStmt, curTok.lexeme,
                      moduleFullName: _curModuleFullName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors.add(err);
                  advance(1);
                  return null;
              }
            case HTLexicon.ABSTRACT:
              advance(1);
              return _parseClassDecl(isAbstract: true, isTopLevel: true);
            case HTLexicon.ENUM:
              return _parseEnumDecl(isTopLevel: true);
            case HTLexicon.CLASS:
              return _parseClassDecl(isTopLevel: true);
            case HTLexicon.VAR:
              return _parseVarDecl(isMutable: true, isTopLevel: true);
            case HTLexicon.FINAL:
              return _parseVarDecl(isTopLevel: true);
            case HTLexicon.FUNCTION:
              if (expect([HTLexicon.FUNCTION, SemanticNames.identifier]) ||
                  expect([
                    HTLexicon.FUNCTION,
                    HTLexicon.squareLeft,
                    SemanticNames.identifier,
                    HTLexicon.squareRight,
                    SemanticNames.identifier
                  ])) {
                return _parseFuncDecl(isTopLevel: true);
              } else {
                return _parseFuncDecl(
                    category: FunctionCategory.literal, isTopLevel: true);
              }
            case HTLexicon.IF:
              return _parseIf();
            case HTLexicon.WHILE:
              return _parseWhileStmt();
            case HTLexicon.DO:
              return _parseDoStmt();
            case HTLexicon.FOR:
              return _parseForStmt();
            case HTLexicon.WHEN:
              return _parseWhenStmt();
            default:
              return _parseExprStmt();
          }
        }
      case SourceType.module:
        if (curTok.lexeme == HTLexicon.LIBRARY) {
          return _parseLibraryDecl();
        } else if (curTok.lexeme == HTLexicon.IMPORT) {
          return _parseImportDecl();
        } else if (curTok.lexeme == HTLexicon.TYPE) {
          return _parseTypeAliasDecl();
        } else {
          switch (curTok.type) {
            case SemanticNames.singleLineComment:
            case SemanticNames.multiLineComment:
              return _parseExprStmt();
            case HTLexicon.EXPORT:
              advance(1);
              switch (curTok.type) {
                case HTLexicon.ABSTRACT:
                  advance(1);
                  return _parseClassDecl(
                      isAbstract: true, isExternal: true, isExported: true);
                case HTLexicon.CLASS:
                  return _parseClassDecl(isExternal: true, isExported: true);
                case HTLexicon.ENUM:
                  return _parseEnumDecl(isExternal: true, isExported: true);
                case HTLexicon.VAR:
                  return _parseVarDecl(isMutable: true, isExported: true);
                case HTLexicon.FINAL:
                  return _parseVarDecl(isExported: true);
                case HTLexicon.FUNCTION:
                  return _parseFuncDecl(isExternal: true, isExported: true);
                default:
                  final err = HTError.unexpected(
                      SemanticNames.declStmt, curTok.lexeme,
                      moduleFullName: _curModuleFullName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors.add(err);
                  advance(1);
                  return null;
              }
            case HTLexicon.EXTERNAL:
              advance(1);
              switch (curTok.type) {
                case HTLexicon.ABSTRACT:
                  advance(1);
                  if (curTok.type != HTLexicon.CLASS) {
                    final err = HTError.unexpected(
                        SemanticNames.classDeclaration, curTok.lexeme,
                        moduleFullName: _curModuleFullName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors.add(err);
                    advance(1);
                    return null;
                  } else {
                    return _parseClassDecl(isAbstract: true, isExternal: true);
                  }
                case HTLexicon.CLASS:
                  return _parseClassDecl(isExternal: true);
                case HTLexicon.ENUM:
                  return _parseEnumDecl(isExternal: true);
                case HTLexicon.FUNCTION:
                  if (!expect([HTLexicon.FUNCTION, SemanticNames.identifier])) {
                    final err = HTError.unexpected(
                        SemanticNames.functionDeclaration, peek(1).lexeme,
                        moduleFullName: _curModuleFullName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors.add(err);
                    advance(1);
                    return null;
                  } else {
                    return _parseFuncDecl(isExternal: true);
                  }
                case HTLexicon.VAR:
                // case HTLexicon.LET:
                case HTLexicon.FINAL:
                  final err = HTError.externalVar(
                      moduleFullName: _curModuleFullName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors.add(err);
                  advance(1);
                  return null;
                default:
                  final err = HTError.unexpected(
                      SemanticNames.declStmt, curTok.lexeme,
                      moduleFullName: _curModuleFullName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors.add(err);
                  advance(1);
                  return null;
              }
            case HTLexicon.ABSTRACT:
              advance(1);
              return _parseClassDecl(isAbstract: true);
            case HTLexicon.ENUM:
              return _parseEnumDecl();
            case HTLexicon.CLASS:
              return _parseClassDecl();
            case HTLexicon.VAR:
              return _parseVarDecl(isMutable: true, lateInitialize: true);
            case HTLexicon.FINAL:
              return _parseVarDecl(lateInitialize: true);
            case HTLexicon.FUNCTION:
              return _parseFuncDecl();
            default:
              final err = HTError.unexpected(
                  SemanticNames.declStmt, curTok.lexeme,
                  moduleFullName: _curModuleFullName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors.add(err);
              advance(1);
              return null;
          }
        }
      case SourceType.klass:
        final isOverrided = expect([HTLexicon.OVERRIDE], consume: true);
        final isExternal = expect([HTLexicon.EXTERNAL], consume: true) ||
            (_curClass?.isExternal ?? false);
        final isStatic = expect([HTLexicon.STATIC], consume: true);
        if (curTok.lexeme == HTLexicon.TYPE) {
          if (isExternal) {
            final err = HTError.externalType(
                moduleFullName: _curModuleFullName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors.add(err);
            advance(1);
            return null;
          } else {
            return _parseTypeAliasDecl();
          }
        } else {
          switch (curTok.type) {
            case SemanticNames.singleLineComment:
            case SemanticNames.multiLineComment:
              return _parseExprStmt();
            case HTLexicon.VAR:
              return _parseVarDecl(
                  classId: _curClass?.id,
                  isOverrided: isOverrided,
                  isExternal: isExternal,
                  isMutable: true,
                  isStatic: isStatic,
                  lateInitialize: true);
            case HTLexicon.FINAL:
              return _parseVarDecl(
                  classId: _curClass?.id,
                  isOverrided: isOverrided,
                  isExternal: isExternal,
                  isStatic: isStatic,
                  lateInitialize: true);
            case HTLexicon.FUNCTION:
              return _parseFuncDecl(
                  category: FunctionCategory.method,
                  classId: _curClass?.id,
                  isOverrided: isOverrided,
                  isExternal: isExternal,
                  isStatic: isStatic);
            case HTLexicon.GET:
              return _parseFuncDecl(
                  category: FunctionCategory.getter,
                  classId: _curClass?.id,
                  isOverrided: isOverrided,
                  isExternal: isExternal,
                  isStatic: isStatic);
            case HTLexicon.SET:
              return _parseFuncDecl(
                  category: FunctionCategory.setter,
                  classId: _curClass?.id,
                  isOverrided: isOverrided,
                  isExternal: isExternal,
                  isStatic: isStatic);
            case HTLexicon.CONSTRUCT:
              if (isStatic) {
                final err = HTError.unexpected(
                    SemanticNames.declStmt, HTLexicon.CONSTRUCT,
                    moduleFullName: _curModuleFullName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors.add(err);
                advance(1);
                return null;
              } else {
                return _parseFuncDecl(
                  category: FunctionCategory.constructor,
                  classId: _curClass?.id,
                  isExternal: isExternal,
                );
              }
            case HTLexicon.FACTORY:
              if (isStatic) {
                final err = HTError.unexpected(
                    SemanticNames.declStmt, HTLexicon.CONSTRUCT,
                    moduleFullName: _curModuleFullName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors.add(err);
                advance(1);
                return null;
              } else {
                return _parseFuncDecl(
                  category: FunctionCategory.factoryConstructor,
                  classId: _curClass?.id,
                  isExternal: isExternal,
                );
              }
            default:
              final err = HTError.unexpected(
                  SemanticNames.declStmt, curTok.lexeme,
                  moduleFullName: _curModuleFullName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors.add(err);
              advance(1);
              return null;
          }
        }
      case SourceType.function:
        if (curTok.lexeme == HTLexicon.TYPE) {
          return _parseTypeAliasDecl();
        } else {
          switch (curTok.type) {
            case HTLexicon.ABSTRACT:
              advance(1);
              return _parseClassDecl(isAbstract: true);
            case HTLexicon.ENUM:
              return _parseEnumDecl();
            case HTLexicon.CLASS:
              return _parseClassDecl();
            case HTLexicon.VAR:
              return _parseVarDecl(isMutable: true);
            case HTLexicon.FINAL:
              return _parseVarDecl();
            case HTLexicon.FUNCTION:
              if (expect([HTLexicon.FUNCTION, SemanticNames.identifier]) ||
                  expect([
                    HTLexicon.FUNCTION,
                    HTLexicon.squareLeft,
                    SemanticNames.identifier,
                    HTLexicon.squareRight,
                    SemanticNames.identifier
                  ])) {
                return _parseFuncDecl();
              } else {
                return _parseFuncDecl(category: FunctionCategory.literal);
              }
            case HTLexicon.IF:
              return _parseIf();
            case HTLexicon.WHILE:
              return _parseWhileStmt();
            case HTLexicon.DO:
              return _parseDoStmt();
            case HTLexicon.FOR:
              return _parseForStmt();
            case HTLexicon.WHEN:
              return _parseWhenStmt();
            case HTLexicon.BREAK:
              final keyword = advance(1);
              return BreakStmt(keyword,
                  source: _curSource,
                  line: keyword.line,
                  column: keyword.column,
                  offset: keyword.offset,
                  length: keyword.length);
            case HTLexicon.CONTINUE:
              final keyword = advance(1);
              return ContinueStmt(keyword,
                  source: _curSource,
                  line: keyword.line,
                  column: keyword.column,
                  offset: keyword.offset,
                  length: keyword.length);
            case HTLexicon.RETURN:
              if (_curFuncCategory != null &&
                  _curFuncCategory != FunctionCategory.constructor) {
                return _parseReturnStmt();
              } else {
                final err = HTError.outsideReturn(
                    moduleFullName: _curModuleFullName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors.add(err);
                advance(1);
                return null;
              }
            default:
              return _parseExprStmt();
          }
        }
      case SourceType.struct:
        throw HTError.unsupported('struct parsing');
      case SourceType.expression:
        return _parseExpr();
    }
  }

  /// 使用递归向下的方法生成表达式, 不断调用更底层的, 优先级更高的子Parser
  ///
  /// 赋值 = , 优先级 1, 右合并
  ///
  /// 需要判断嵌套赋值、取属性、取下标的叠加
  AstNode _parseExpr() {
    if (curTok.type == SemanticNames.singleLineComment) {
      final comment = advance(1);
      return CommentExpr(comment.literal,
          isMultiline: false,
          source: _curSource,
          line: comment.line,
          column: comment.column,
          offset: comment.offset,
          length: comment.length);
    } else if (curTok.type == SemanticNames.multiLineComment) {
      final comment = advance(1);
      return CommentExpr(comment.literal,
          isMultiline: true,
          source: _curSource,
          line: comment.line,
          column: comment.column,
          offset: comment.offset,
          length: comment.length);
    } else {
      final left = _parserTernaryExpr();
      if (HTLexicon.assignments.contains(curTok.type)) {
        if (!_leftValueLegality) {
          final err = HTError.invalidLeftValue(
              moduleFullName: _curModuleFullName,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: left.length);
          errors.add(err);
        }
        final op = advance(1);
        final right = _parseExpr();
        if (left is MemberExpr) {
          return MemberAssignExpr(left.object, left.key, right,
              source: _curSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        } else if (left is SubExpr) {
          return SubAssignExpr(left.array, left.key, right,
              source: _curSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        } else {
          return BinaryExpr(left, op.lexeme, right,
              source: _curSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        }
      } else {
        return left;
      }
    }
  }

  AstNode _parserTernaryExpr() {
    var condition = _parseLogicalOrExpr();
    if (expect([HTLexicon.condition], consume: true)) {
      _leftValueLegality = false;
      final thenBranch = _parserTernaryExpr();
      match(HTLexicon.colon);
      final elseBranch = _parserTernaryExpr();
      condition = TernaryExpr(condition, thenBranch, elseBranch,
          source: _curSource,
          line: condition.line,
          column: condition.column,
          offset: condition.offset,
          length: curTok.offset - condition.offset);
    }
    return condition;
  }

  /// 逻辑或 || , 优先级 5, 左合并
  AstNode _parseLogicalOrExpr() {
    var left = _parseLogicalAndExpr();
    if (curTok.type == HTLexicon.logicalOr) {
      _leftValueLegality = false;
      while (curTok.type == HTLexicon.logicalOr) {
        final op = advance(1); // and operator
        final right = _parseLogicalAndExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: _curSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// 逻辑和 && , 优先级 6, 左合并
  AstNode _parseLogicalAndExpr() {
    var left = _parseEqualityExpr();
    if (curTok.type == HTLexicon.logicalAnd) {
      _leftValueLegality = false;
      while (curTok.type == HTLexicon.logicalAnd) {
        final op = advance(1); // and operator
        final right = _parseEqualityExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: _curSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// 逻辑相等 ==, !=, 优先级 7, 不合并
  AstNode _parseEqualityExpr() {
    var left = _parseRelationalExpr();
    if (HTLexicon.equalitys.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance(1);
      final right = _parseRelationalExpr();
      left = BinaryExpr(left, op.lexeme, right,
          source: _curSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    }
    return left;
  }

  /// 逻辑比较 <, >, <=, >=, as, is, is! 优先级 8, 不合并
  AstNode _parseRelationalExpr() {
    var left = _parseAdditiveExpr();
    if (HTLexicon.logicalRelationals.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance(1);
      final right = _parseAdditiveExpr();
      left = BinaryExpr(left, op.lexeme, right,
          source: _curSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    } else if (HTLexicon.typeRelationals.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance(1);
      late final String opLexeme;
      if (op.lexeme == HTLexicon.IS) {
        opLexeme = expect([HTLexicon.logicalNot], consume: true)
            ? HTLexicon.ISNOT
            : HTLexicon.IS;
      } else {
        opLexeme = op.lexeme;
      }
      final right = _parseTypeExpr(isLocal: true);
      left = BinaryExpr(left, opLexeme, right,
          source: _curSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    }
    return left;
  }

  /// 加法 +, -, 优先级 13, 左合并
  AstNode _parseAdditiveExpr() {
    var left = _parseMultiplicativeExpr();
    if (HTLexicon.additives.contains(curTok.type)) {
      _leftValueLegality = false;
      while (HTLexicon.additives.contains(curTok.type)) {
        final op = advance(1);
        final right = _parseMultiplicativeExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: _curSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// 乘法 *, /, %, 优先级 14, 左合并
  AstNode _parseMultiplicativeExpr() {
    var left = _parseUnaryPrefixExpr();
    if (HTLexicon.multiplicatives.contains(curTok.type)) {
      _leftValueLegality = false;
      while (HTLexicon.multiplicatives.contains(curTok.type)) {
        final op = advance(1);
        final right = _parseUnaryPrefixExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: _curSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// 前缀 -e, !e，++e, --e, 优先级 15, 不合并
  AstNode _parseUnaryPrefixExpr() {
    if (!(HTLexicon.unaryPrefixs.contains(curTok.type))) {
      return _parseUnaryPostfixExpr();
    } else {
      final op = advance(1);
      final value = _parseUnaryPostfixExpr();
      return UnaryPrefixExpr(op.lexeme, value,
          source: _curSource,
          line: op.line,
          column: op.column,
          offset: op.offset,
          length: curTok.offset - op.offset);
    }
  }

  /// 后缀 e., e[], e(), e++, e-- 优先级 16, 右合并
  AstNode _parseUnaryPostfixExpr() {
    var expr = _parsePrimaryExpr();
    while (HTLexicon.unaryPostfixs.contains(curTok.type)) {
      final op = advance(1);
      switch (op.type) {
        case HTLexicon.memberGet:
          _leftValueLegality = true;
          final name = match(SemanticNames.identifier);
          final key = SymbolExpr(name.lexeme,
              isLocal: false,
              source: _curSource,
              line: name.line,
              column: name.column,
              offset: name.offset,
              length: name.length);
          expr = MemberExpr(expr, key,
              source: _curSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case HTLexicon.subGet:
          var indexExpr = _parseExpr();
          _leftValueLegality = true;
          match(HTLexicon.squareRight);
          expr = SubExpr(expr, indexExpr,
              source: _curSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case HTLexicon.call:
          // TODO: typeArgs: typeArgs
          _leftValueLegality = false;
          var positionalArgs = <AstNode>[];
          var namedArgs = <String, AstNode>{};
          _handleCallArguments(positionalArgs, namedArgs);
          expr = CallExpr(expr, positionalArgs, namedArgs,
              source: _curSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case HTLexicon.postIncrement:
        case HTLexicon.postDecrement:
          _leftValueLegality = false;
          expr = UnaryPostfixExpr(expr, op.lexeme,
              source: _curSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        default:
          break;
      }
    }
    return expr;
  }

  /// Expression without operators
  AstNode _parsePrimaryExpr() {
    switch (curTok.type) {
      case HTLexicon.NULL:
        _leftValueLegality = false;
        final token = advance(1);
        return NullExpr(
            source: _curSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case SemanticNames.booleanLiteral:
        _leftValueLegality = false;
        final token = advance(1) as TokenBooleanLiteral;
        return BooleanExpr(token.literal,
            source: _curSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case SemanticNames.integerLiteral:
        _leftValueLegality = false;
        final token = advance(1) as TokenIntLiteral;
        return ConstIntExpr(token.literal,
            source: _curSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case SemanticNames.floatLiteral:
        _leftValueLegality = false;
        final token = advance(1) as TokenFloatLiteral;
        return ConstFloatExpr(token.literal,
            source: _curSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case SemanticNames.stringLiteral:
        _leftValueLegality = false;
        final token = advance(1) as TokenStringLiteral;
        return ConstStringExpr(
            token.literal, token.quotationLeft, token.quotationRight,
            source: _curSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case SemanticNames.stringInterpolation:
        _leftValueLegality = false;
        final token = advance(1) as TokenStringInterpolation;
        final interpolation = <AstNode>[];
        for (final tokens in token.interpolations) {
          final exprParser = HTParser(context: context);
          final nodes = exprParser.parse(tokens,
              source: _curSource, type: SourceType.expression);
          errors.addAll(exprParser.errors);
          if (nodes.length > 1) {
            final err = HTError.stringInterpolation(
                moduleFullName: _curModuleFullName,
                line: nodes.first.line,
                column: nodes.first.column,
                offset: nodes.first.offset,
                length: nodes.last.end - nodes.first.offset);
            errors.add(err);
            final errToken = EmptyExpr(
                source: _curSource,
                line: token.line,
                column: token.column,
                offset: token.offset);
            interpolation.add(errToken);
          } else {
            // parser will at least insert a empty line astnode
            if (nodes.first is EmptyExpr) {
              final err = HTError.stringInterpolation(
                  moduleFullName: _curModuleFullName,
                  line: nodes.first.line,
                  column: nodes.first.column,
                  offset: nodes.first.offset,
                  length: nodes.first.length +
                      HTLexicon.stringInterpolationStart.length +
                      HTLexicon.stringInterpolationEnd.length);
              errors.add(err);
            }
            interpolation.add(nodes.first);
          }
        }
        var i = 0;
        final value = token.literal.replaceAllMapped(
            RegExp(HTLexicon.stringInterpolationPattern),
            (Match m) => '${HTLexicon.curlyLeft}${i++}${HTLexicon.curlyRight}');
        return StringInterpolationExpr(
            value, token.quotationLeft, token.quotationRight, interpolation,
            source: _curSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case HTLexicon.THIS:
        _leftValueLegality = false;
        final keyword = advance(1);
        return SymbolExpr(keyword.lexeme,
            source: _curSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length);
      case HTLexicon.SUPER:
        _leftValueLegality = false;
        final keyword = advance(1);
        return SymbolExpr(keyword.lexeme,
            source: _curSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length);
      case HTLexicon.IF:
        final expr = _parseIf(isExpression: true);
        return expr;
      case HTLexicon.roundLeft:
        _leftValueLegality = false;
        final start = advance(1);
        final innerExpr = _parseExpr();
        final end = match(HTLexicon.roundRight);
        return GroupExpr(innerExpr,
            source: _curSource,
            line: start.line,
            column: start.column,
            offset: start.offset,
            length: end.offset + end.length - start.offset);
      case HTLexicon.squareLeft:
        _leftValueLegality = false;
        final start = advance(1);
        var listExpr = <AstNode>[];
        while (curTok.type != HTLexicon.squareRight) {
          listExpr.add(_parseExpr());
          if (curTok.type != HTLexicon.squareRight) {
            match(HTLexicon.comma);
          }
        }
        final end = match(HTLexicon.squareRight);
        return ListExpr(listExpr,
            source: _curSource,
            line: start.line,
            column: start.column,
            offset: start.offset,
            length: end.offset + end.length - start.offset);
      case HTLexicon.curlyLeft:
        _leftValueLegality = false;
        final start = advance(1);
        var mapExpr = <AstNode, AstNode>{};
        while (curTok.type != HTLexicon.curlyRight) {
          var keyExpr = _parseExpr();
          match(HTLexicon.colon);
          var valueExpr = _parseExpr();
          mapExpr[keyExpr] = valueExpr;
          if (curTok.type != HTLexicon.curlyRight) {
            match(HTLexicon.comma);
          }
        }
        final end = match(HTLexicon.curlyRight);
        return MapExpr(mapExpr,
            source: _curSource,
            line: start.line,
            column: start.column,
            offset: start.offset,
            length: end.offset + end.length - start.offset);
      case HTLexicon.FUNCTION:
        return _parseFuncDecl(
            category: FunctionCategory.literal, isExpression: true);
      case SemanticNames.identifier:
        // literal function type
        if (curTok.lexeme == HTLexicon.function) {
          _leftValueLegality = false;
          return _parseTypeExpr();
        }
        // TODO: literal interface type
        else {
          _leftValueLegality = true;
          final symbol = advance(1);
          // TODO: type arguments
          return SymbolExpr.fromToken(symbol);
        }
      default:
        final err = HTError.unexpected(SemanticNames.expression, curTok.lexeme,
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
        final errToken = advance(1);
        return EmptyExpr(
            source: _curSource,
            line: errToken.line,
            column: errToken.column,
            offset: errToken.offset);
    }
  }

  TypeExpr _parseTypeExpr({bool isLocal = false}) {
    // function type
    if (curTok.type == HTLexicon.FUNCTION) {
      final keyword = match(HTLexicon.FUNCTION);
      final keywordSymbol = SymbolExpr.fromToken(keyword);
      // TODO: genericTypeParameters 泛型参数
      final parameters = <ParamTypeExpr>[];
      var isOptional = false;
      var isNamed = false;
      var isVariadic = false;
      match(HTLexicon.roundLeft);
      while (curTok.type != HTLexicon.roundRight &&
          curTok.type != SemanticNames.endOfFile) {
        final start = curTok;
        if (!isOptional) {
          isOptional = expect([HTLexicon.squareLeft], consume: true);
          if (!isOptional && !isNamed) {
            isNamed = expect([HTLexicon.curlyLeft], consume: true);
          }
        }
        late final paramType;
        SymbolExpr? paramSymbol;
        if (!isNamed) {
          isVariadic = expect([HTLexicon.variadicArgs], consume: true);
        } else {
          final paramId = match(SemanticNames.identifier);
          paramSymbol = SymbolExpr.fromToken(paramId);
          match(HTLexicon.colon);
        }
        paramType = _parseTypeExpr();
        final param = ParamTypeExpr(paramType,
            isOptional: isOptional,
            isVariadic: isVariadic,
            id: paramSymbol,
            source: _curSource,
            line: start.line,
            column: start.column,
            offset: start.offset,
            length: curTok.offset - start.offset);
        parameters.add(param);
        if (isOptional && expect([HTLexicon.squareRight], consume: true)) {
          break;
        } else if (isNamed && expect([HTLexicon.curlyRight], consume: true)) {
          break;
        } else if (curTok.type != HTLexicon.roundRight) {
          match(HTLexicon.comma);
        }
        if (isVariadic) {
          break;
        }
      }
      match(HTLexicon.roundRight);
      final returnType = _parseTypeExpr();
      return FuncTypeExpr(keywordSymbol, returnType,
          isLocal: isLocal,
          paramTypes: parameters,
          hasOptionalParam: isOptional,
          hasNamedParam: isNamed,
          source: _curSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    }
    // TODO: interface type
    // nominal type
    else {
      final id = match(SemanticNames.identifier);
      final symbol = SymbolExpr.fromToken(id);
      final typeArgs = <TypeExpr>[];
      if (expect([HTLexicon.angleLeft], consume: true)) {
        if (curTok.type == HTLexicon.angleRight) {
          final lastTok = peek(-1);
          final err = HTError.emptyTypeArgs(
              moduleFullName: _curModuleFullName,
              line: curTok.line,
              column: curTok.column,
              offset: lastTok.offset,
              length: lastTok.length + curTok.length);
          errors.add(err);
        }
        while ((curTok.type != HTLexicon.angleRight) &&
            (curTok.type != SemanticNames.endOfFile)) {
          typeArgs.add(_parseTypeExpr());
          expect([HTLexicon.comma], consume: true);
        }
        match(HTLexicon.angleRight);
      }
      final isNullable = expect([HTLexicon.nullable], consume: true);
      return TypeExpr(
        symbol,
        arguments: typeArgs,
        isNullable: isNullable,
        isLocal: isLocal,
        source: _curSource,
        line: id.line,
        column: id.column,
        offset: id.offset,
      );
    }
  }

  BlockStmt _parseBlockStmt(
      {String? id,
      SourceType sourceType = SourceType.function,
      bool hasOwnNamespace = true}) {
    final start = match(HTLexicon.curlyLeft);
    final statements = <AstNode>[];
    while (curTok.type != HTLexicon.curlyRight &&
        curTok.type != SemanticNames.endOfFile) {
      final stmt = _parseStmt(sourceType: sourceType);
      if (stmt != null) {
        statements.add(stmt);
      }
    }
    match(HTLexicon.curlyRight);
    return BlockStmt(statements,
        id: id,
        hasOwnNamespace: hasOwnNamespace,
        source: _curSource,
        line: start.line,
        column: start.column,
        offset: start.offset,
        length: curTok.offset - start.offset);
  }

  void _handleCallArguments(
      List<AstNode> positionalArgs, Map<String, AstNode> namedArgs) {
    var isNamed = false;
    while ((curTok.type != HTLexicon.roundRight) &&
        (curTok.type != SemanticNames.endOfFile)) {
      if ((!isNamed &&
              expect([SemanticNames.identifier, HTLexicon.colon],
                  consume: false)) ||
          isNamed) {
        isNamed = true;
        final name = match(SemanticNames.identifier).lexeme;
        match(HTLexicon.colon);
        final value = _parseExpr();
        namedArgs[name] = value;
      } else {
        positionalArgs.add(_parseExpr());
      }
      if (curTok.type != HTLexicon.roundRight) {
        match(HTLexicon.comma);
      }
    }
    match(HTLexicon.roundRight);
  }

  AstNode _parseExprStmt() {
    final expr = _parseExpr();
    expect([HTLexicon.semicolon], consume: true);
    final stmt = ExprStmt(expr,
        source: _curSource,
        line: expr.line,
        column: expr.column,
        offset: expr.offset,
        length: curTok.offset - expr.offset);
    return stmt;
  }

  ReturnStmt _parseReturnStmt() {
    var keyword = advance(1);
    AstNode? expr;
    if (curTok.type != HTLexicon.curlyRight &&
        curTok.type != HTLexicon.semicolon &&
        curTok.type != SemanticNames.endOfFile) {
      expr = _parseExpr();
    }
    expect([HTLexicon.semicolon], consume: true);
    return ReturnStmt(keyword, expr,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  AstNode _parseExprOrStmtOrBlock({bool isExpression = false}) {
    if (curTok.type == HTLexicon.curlyLeft) {
      return _parseBlockStmt(id: SemanticNames.elseBranch);
    } else {
      if (isExpression) {
        return _parseExpr();
      } else {
        final token = curTok;
        final node = _parseStmt();
        if (node == null) {
          final err = HTError.unexpected(
              SemanticNames.statement, SemanticNames.emptyLine,
              moduleFullName: curModuleFullName,
              line: curTok.line,
              column: curTok.column);
          errors.add(err);
          return EmptyExpr(
              source: _curSource,
              line: token.line,
              column: token.column,
              offset: token.offset);
        } else {
          return node;
        }
      }
    }
  }

  IfStmt _parseIf({bool isExpression = false}) {
    final keyword = advance(1);
    var condition = _parseExpr();

    final thenBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
    AstNode? elseBranch;
    if (isExpression) {
      match(HTLexicon.ELSE);
      elseBranch = _parseExpr();
    } else {
      if (expect([HTLexicon.ELSE], consume: true)) {
        elseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
      }
    }
    return IfStmt(condition, thenBranch, elseBranch,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  WhileStmt _parseWhileStmt() {
    final keyword = advance(1);
    final condition = _parseExpr();
    final loop = _parseBlockStmt(id: SemanticNames.whileLoop);
    return WhileStmt(condition, loop,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  DoStmt _parseDoStmt() {
    final keyword = advance(1);
    final loop = _parseBlockStmt(id: SemanticNames.doLoop);
    AstNode? condition;
    if (expect([HTLexicon.WHILE], consume: true)) {
      condition = _parseExpr();
    }
    return DoStmt(loop, condition,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  AstNode _parseForStmt() {
    final keyword = advance(1);
    final hasBracket = expect([HTLexicon.roundLeft], consume: true);
    final forStmtType = peek(2).lexeme;
    VarDecl? decl;
    AstNode? condition;
    AstNode? increment;
    final newSymbolMap = <String, String>{};
    _markedSymbolsList.add(newSymbolMap);
    if (forStmtType == HTLexicon.IN) {
      if (!HTLexicon.varDeclKeywords.contains(curTok.type)) {
        final err = HTError.unexpected(
            SemanticNames.variableDeclaration, curTok.type,
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
      decl = _parseVarDecl(
          // typeInferrence: curTok.type != HTLexicon.VAR,
          isMutable: curTok.type != HTLexicon.FINAL);
      advance(1);
      final collection = _parseExpr();
      if (hasBracket) {
        match(HTLexicon.roundRight);
      }
      final loop = _parseBlockStmt(id: SemanticNames.forLoop);
      return ForInStmt(decl, collection, loop,
          hasBracket: hasBracket,
          source: _curSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    } else {
      if (!expect([HTLexicon.semicolon], consume: false)) {
        decl = _parseVarDecl(
            // typeInferrence: curTok.type != HTLexicon.VAR,
            isMutable: curTok.type != HTLexicon.FINAL,
            hasEndOfStatement: true);
      } else {
        match(HTLexicon.semicolon);
      }
      if (!expect([HTLexicon.semicolon], consume: false)) {
        condition = _parseExpr();
      }
      match(HTLexicon.semicolon);
      if (!expect([HTLexicon.roundRight], consume: false)) {
        increment = _parseExpr();
      }
      if (hasBracket) {
        match(HTLexicon.roundRight);
      }
      final loop = _parseBlockStmt(id: SemanticNames.forLoop);
      return ForStmt(decl, condition, increment, loop,
          hasBracket: hasBracket,
          source: _curSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    }
  }

  WhenStmt _parseWhenStmt() {
    final keyword = advance(1);
    AstNode? condition;
    if (curTok.type != HTLexicon.curlyLeft) {
      condition = _parseExpr();
    }
    final options = <AstNode, AstNode>{};
    AstNode? elseBranch;
    match(HTLexicon.curlyLeft);
    while (curTok.type != HTLexicon.curlyRight &&
        curTok.type != SemanticNames.endOfFile) {
      if (curTok.lexeme == HTLexicon.ELSE) {
        advance(1);
        match(HTLexicon.singleArrow);
        if (curTok.type == HTLexicon.curlyLeft) {
          elseBranch = _parseBlockStmt(id: SemanticNames.elseBranch);
        } else {
          final stmt = _parseStmt();
          if (stmt == null) {
            final err = HTError.unexpected(
                SemanticNames.statement, SemanticNames.emptyLine,
                moduleFullName: curModuleFullName,
                line: curTok.line,
                column: curTok.column);
            errors.add(err);
          }
          elseBranch = stmt;
        }
      } else {
        final caseExpr = _parseExpr();
        match(HTLexicon.singleArrow);
        late final caseBranch;
        if (curTok.type == HTLexicon.curlyLeft) {
          caseBranch = _parseBlockStmt(id: SemanticNames.whenBranch);
        } else {
          final stmt = _parseStmt();
          if (stmt == null) {
            final err = HTError.unexpected(
                SemanticNames.statement, SemanticNames.emptyLine,
                moduleFullName: curModuleFullName,
                line: curTok.line,
                column: curTok.column);
            errors.add(err);
          }
          caseBranch = stmt;
        }
        options[caseExpr] = caseBranch;
      }
    }
    match(HTLexicon.curlyRight);
    return WhenStmt(options, elseBranch, condition,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  List<GenericTypeParameterExpr> _getGenericParams() {
    final genericParams = <GenericTypeParameterExpr>[];
    if (expect([HTLexicon.angleLeft], consume: true)) {
      while ((curTok.type != HTLexicon.angleRight) &&
          (curTok.type != SemanticNames.endOfFile)) {
        if (genericParams.isNotEmpty) {
          match(HTLexicon.comma);
        }
        final id = match(SemanticNames.identifier);
        final symbol = SymbolExpr.fromToken(id);
        final param = GenericTypeParameterExpr(symbol,
            source: _curSource,
            line: id.line,
            column: id.column,
            offset: id.offset,
            length: curTok.offset - id.offset);
        genericParams.add(param);
      }
      match(HTLexicon.angleRight);
    }
    return genericParams;
  }

  LibraryDecl _parseLibraryDecl() {
    if (_isLibraryEntry) {
      final err = HTError.duplicateLibStmt(
          moduleFullName: _curModuleFullName,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.length);
      errors.add(err);
    }
    final keyword = advance(1);
    _isLibraryEntry = true;
    final id = match(SemanticNames.stringLiteral);
    final stmt = LibraryDecl(id.literal,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
    expect([HTLexicon.semicolon], consume: true);
    return stmt;
  }

  ImportDecl _parseImportDecl() {
    // TODO: duplicate import and self import error.
    final keyword = advance(1);
    final showList = <SymbolExpr>[];
    if (curTok.type == HTLexicon.curlyLeft) {
      advance(1);
      do {
        final id = match(SemanticNames.identifier);
        final symbol = SymbolExpr.fromToken(id);
        showList.add(symbol);
      } while (expect([HTLexicon.comma], consume: true));
      match(HTLexicon.curlyRight);
      // check lexeme here because expect() can only deal with token type
      final fromKeyword = advance(1).lexeme;
      if (fromKeyword != HTLexicon.FROM) {
        final err = HTError.unexpected(HTLexicon.FROM, curTok.lexeme,
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
    }
    final key = match(SemanticNames.stringLiteral);
    SymbolExpr? alias;
    if (expect([HTLexicon.AS], consume: true)) {
      final aliasId = match(SemanticNames.identifier);
      alias = SymbolExpr.fromToken(aliasId);
    }
    final stmt = ImportDecl(key.literal,
        alias: alias,
        showList: showList,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
    _curModuleImports.add(stmt);
    expect([HTLexicon.semicolon], consume: true);
    return stmt;
  }

  TypeAliasDecl _parseTypeAliasDecl(
      {String? classId, bool isExported = false, bool isTopLevel = false}) {
    final keyword = advance(1);
    final id = match(SemanticNames.identifier);
    final symbol = SymbolExpr.fromToken(id);
    final genericParameters = _getGenericParams();
    match(HTLexicon.assign);
    final value = _parseTypeExpr();
    return TypeAliasDecl(symbol, value,
        classId: classId,
        genericTypeParameters: genericParameters,
        isExported: isExported,
        isTopLevel: isTopLevel,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  VarDecl _parseVarDecl(
      {String? classId,
      // bool typeInferrence = false,
      bool isOverrided = false,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isMutable = false,
      bool isExported = false,
      bool isTopLevel = false,
      bool lateInitialize = false,
      AstNode? additionalInitializer,
      bool hasEndOfStatement = false}) {
    final keyword = advance(1);
    final id = match(SemanticNames.identifier);
    final symbol = SymbolExpr.fromToken(id);
    String? internalName;
    if (classId != null && isExternal) {
      if (!(_curClass!.isExternal) && !isStatic) {
        final err = HTError.externalMember(
            moduleFullName: _curModuleFullName,
            line: keyword.line,
            column: keyword.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
      internalName = '$classId.${id.lexeme}';
    }
    var declType;
    if (expect([HTLexicon.colon], consume: true)) {
      declType = _parseTypeExpr();
    }
    var initializer = additionalInitializer;
    if (expect([HTLexicon.assign], consume: true)) {
      initializer = _parseExpr();
    }
    if (hasEndOfStatement) {
      match(HTLexicon.semicolon);
    } else {
      expect([HTLexicon.semicolon], consume: true);
    }
    return VarDecl(symbol,
        internalName: internalName,
        classId: classId,
        declType: declType,
        initializer: initializer,
        // typeInferrence: typeInferrence,
        isExternal: isExternal,
        isStatic: isStatic,
        isConst: isConst,
        isMutable: isMutable,
        isExported: isExported,
        isTopLevel: isTopLevel,
        lateInitialize: lateInitialize,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  FuncDecl _parseFuncDecl(
      {FunctionCategory category = FunctionCategory.normal,
      String? classId,
      bool isOverrided = false,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isExported = false,
      bool isTopLevel = false,
      bool isExpression = false}) {
    final savedCurFuncType = _curFuncCategory;
    _curFuncCategory = category;
    final keyword = advance(1);
    String? externalTypedef;
    if (!isExternal &&
        (isStatic ||
            category == FunctionCategory.normal ||
            category == FunctionCategory.literal)) {
      if (expect([HTLexicon.squareLeft], consume: true)) {
        if (isExternal) {
          final err = HTError.internalFuncWithExternalTypeDef(
              moduleFullName: _curModuleFullName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.length);
          errors.add(err);
        }
        externalTypedef = match(SemanticNames.identifier).lexeme;
        match(HTLexicon.squareRight);
      }
    }
    Token? id;
    late String internalName;
    switch (category) {
      case FunctionCategory.constructor:
        _hasUserDefinedConstructor = true;
        if (curTok.type == SemanticNames.identifier) {
          id = advance(1);
        }
        internalName = (id == null)
            ? SemanticNames.constructor
            : '${SemanticNames.constructor}$id';
        break;
      case FunctionCategory.literal:
        if (curTok.type == SemanticNames.identifier) {
          id = advance(1);
        }
        internalName =
            (id == null) ? SemanticNames.anonymousFunction : id.lexeme;
        break;
      case FunctionCategory.getter:
        id = match(SemanticNames.identifier);
        internalName = '${SemanticNames.getter}$id';
        break;
      case FunctionCategory.setter:
        id = match(SemanticNames.identifier);
        internalName = '${SemanticNames.setter}$id';
        break;
      default:
        id = match(SemanticNames.identifier);
        internalName = id.lexeme;
    }
    final genericParameters = _getGenericParams();
    var isFuncVariadic = false;
    var minArity = 0;
    var maxArity = 0;
    var paramDecls = <ParamDecl>[];
    var hasParamDecls = false;
    if (category != FunctionCategory.getter &&
        expect([HTLexicon.roundLeft], consume: true)) {
      final startTok = curTok;
      hasParamDecls = true;
      var isOptional = false;
      var isNamed = false;
      var isVariadic = false;
      while ((curTok.type != HTLexicon.roundRight) &&
          (curTok.type != HTLexicon.squareRight) &&
          (curTok.type != HTLexicon.curlyRight) &&
          (curTok.type != SemanticNames.endOfFile)) {
        // 可选参数, 根据是否有方括号判断, 一旦开始了可选参数, 则不再增加参数数量arity要求
        if (!isOptional) {
          isOptional = expect([HTLexicon.squareLeft], consume: true);
          if (!isOptional && !isNamed) {
            //检查命名参数, 根据是否有花括号判断
            isNamed = expect([HTLexicon.curlyLeft], consume: true);
          }
        }
        if (!isNamed) {
          isVariadic = expect([HTLexicon.variadicArgs], consume: true);
        }
        if (!isNamed && !isVariadic) {
          if (!isOptional) {
            ++minArity;
            ++maxArity;
          } else {
            ++maxArity;
          }
        }
        final paramId = match(SemanticNames.identifier);
        final paramSymbol = SymbolExpr.fromToken(paramId);
        TypeExpr? paramDeclType;
        if (expect([HTLexicon.colon], consume: true)) {
          paramDeclType = _parseTypeExpr();
        }
        AstNode? initializer;
        if (expect([HTLexicon.assign], consume: true)) {
          if (isOptional || isNamed) {
            initializer = _parseExpr();
          } else {
            final lastTok = peek(-1);
            final err = HTError.argInit(
                moduleFullName: _curModuleFullName,
                line: lastTok.line,
                column: lastTok.column,
                offset: lastTok.offset,
                length: lastTok.length);
            errors.add(err);
          }
        }
        final param = ParamDecl(paramSymbol,
            declType: paramDeclType,
            initializer: initializer,
            isVariadic: isVariadic,
            isOptional: isOptional,
            isNamed: isNamed,
            source: _curSource,
            line: paramId.line,
            column: paramId.column,
            offset: paramId.offset,
            length: curTok.offset - paramId.offset);

        paramDecls.add(param);
        if (curTok.type != HTLexicon.squareRight &&
            curTok.type != HTLexicon.curlyRight &&
            curTok.type != HTLexicon.roundRight) {
          match(HTLexicon.comma);
        }
        if (isVariadic) {
          isFuncVariadic = true;
          break;
        }
      }
      if (isOptional) {
        match(HTLexicon.squareRight);
      } else if (isNamed) {
        match(HTLexicon.curlyRight);
      }

      final endTok = match(HTLexicon.roundRight);

      // setter can only have one parameter
      if ((category == FunctionCategory.setter) && (minArity != 1)) {
        final err = HTError.setterArity(
            moduleFullName: _curModuleFullName,
            line: startTok.line,
            column: startTok.column,
            offset: startTok.offset,
            length: endTok.offset + endTok.length - startTok.offset);
        errors.add(err);
      }
    }
    TypeExpr? returnType;
    RedirectingConstructCallExpr? referCtor;
    // the return value type declaration
    if (expect([HTLexicon.singleArrow], consume: true)) {
      if (category == FunctionCategory.constructor) {
        final lastTok = peek(-1);
        final err = HTError.ctorReturn(
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: lastTok.offset,
            length: lastTok.length);
        errors.add(err);
      }
      returnType = _parseTypeExpr();
    }
    // referring to another constructor
    else if (expect([HTLexicon.colon], consume: true)) {
      if (category != FunctionCategory.constructor) {
        final lastTok = peek(-1);
        final err = HTError.nonCotrWithReferCtor(
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: lastTok.offset,
            length: lastTok.length);
        errors.add(err);
      }
      if (isExternal) {
        final lastTok = peek(-1);
        final err = HTError.externalCtorWithReferCtor(
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: lastTok.offset,
            length: lastTok.length);
        errors.add(err);
      }
      final ctorCallee = advance(1);
      if (!HTLexicon.constructorCall.contains(ctorCallee.lexeme)) {
        final err = HTError.unexpected(
            SemanticNames.ctorCallExpr, curTok.lexeme,
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: ctorCallee.offset,
            length: ctorCallee.length);
        errors.add(err);
      }
      Token? ctorKey;
      if (expect([HTLexicon.memberGet], consume: true)) {
        ctorKey = match(SemanticNames.identifier);
        match(HTLexicon.roundLeft);
      } else {
        match(HTLexicon.roundLeft);
      }
      var positionalArgs = <AstNode>[];
      var namedArgs = <String, AstNode>{};
      _handleCallArguments(positionalArgs, namedArgs);
      referCtor = RedirectingConstructCallExpr(
          SymbolExpr.fromToken(ctorCallee), positionalArgs, namedArgs,
          key: ctorKey != null ? SymbolExpr.fromToken(ctorKey) : null,
          source: _curSource,
          line: ctorCallee.line,
          column: ctorCallee.column,
          offset: ctorCallee.offset,
          length: curTok.offset - ctorCallee.offset);
    }
    AstNode? definition;
    if (curTok.type == HTLexicon.curlyLeft) {
      definition = _parseBlockStmt(id: SemanticNames.functionCall);
    } else if (expect([HTLexicon.doubleArrow], consume: true)) {
      definition = _parseExprStmt();
    } else if (expect([HTLexicon.assign], consume: true)) {
      // TODO: redirecting function, usually for constructors
    } else {
      if (category != FunctionCategory.constructor &&
          category != FunctionCategory.literal &&
          !isExternal &&
          !(_curClass?.isAbstract ?? false)) {
        final err = HTError.missingFuncBody(internalName,
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
      if (!isExpression) {
        expect([HTLexicon.semicolon], consume: true);
      }
    }
    _curFuncCategory = savedCurFuncType;
    return FuncDecl(internalName, paramDecls,
        id: id != null ? SymbolExpr.fromToken(id) : null,
        classId: classId,
        genericTypeParameters: genericParameters,
        externalTypeId: externalTypedef,
        returnType: returnType,
        redirectingCtorCallExpr: referCtor,
        hasParamDecls: hasParamDecls,
        minArity: minArity,
        maxArity: maxArity,
        definition: definition,
        isExternal: isExternal,
        isStatic: isStatic,
        isConst: isConst,
        isVariadic: isFuncVariadic,
        isExported: isExported,
        isTopLevel: isTopLevel,
        category: category,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  ClassDecl _parseClassDecl(
      {String? classId,
      bool isExternal = false,
      bool isAbstract = false,
      bool isExported = false,
      bool isTopLevel = false}) {
    final keyword = match(HTLexicon.CLASS);
    if (_curClass != null && _curClass!.isNested) {
      final err = HTError.nestedClass(
          moduleFullName: _curModuleFullName,
          line: curTok.line,
          column: curTok.column,
          offset: keyword.offset,
          length: keyword.length);
      errors.add(err);
    }
    final id = match(SemanticNames.identifier);
    final genericParameters = _getGenericParams();
    TypeExpr? superClassType;
    if (expect([HTLexicon.EXTENDS], consume: true)) {
      if (curTok.lexeme == id.lexeme) {
        final err = HTError.extendsSelf(
            moduleFullName: _curModuleFullName,
            line: curTok.line,
            column: curTok.column,
            offset: keyword.offset,
            length: keyword.length);
        errors.add(err);
      }

      superClassType = _parseTypeExpr();
    }
    final savedClass = _curClass;
    _curClass = HTClassDeclaration(
        id: id.lexeme,
        classId: classId,
        isExternal: isExternal,
        isAbstract: isAbstract);
    final savedHasUsrDefCtor = _hasUserDefinedConstructor;
    _hasUserDefinedConstructor = false;
    final definition = _parseBlockStmt(
        sourceType: SourceType.klass,
        hasOwnNamespace: false,
        id: SemanticNames.classDefinition);
    final decl = ClassDecl(SymbolExpr.fromToken(id), definition,
        genericTypeParameters: genericParameters,
        superType: superClassType,
        isExternal: isExternal,
        isAbstract: isAbstract,
        isExported: isExported,
        isTopLevel: isTopLevel,
        hasUserDefinedConstructor: _hasUserDefinedConstructor,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
    _hasUserDefinedConstructor = savedHasUsrDefCtor;
    _curClass = savedClass;
    return decl;
  }

  EnumDecl _parseEnumDecl(
      {bool isExternal = false,
      bool isExported = true,
      bool isTopLevel = false}) {
    final keyword = match(HTLexicon.ENUM);
    final id = match(SemanticNames.identifier);
    var enumerations = <SymbolExpr>[];
    if (expect([HTLexicon.curlyLeft], consume: true)) {
      while (curTok.type != HTLexicon.curlyRight &&
          curTok.type != SemanticNames.endOfFile) {
        final symbol = SymbolExpr.fromToken(match(SemanticNames.identifier));
        enumerations.add(symbol);
        if (curTok.type != HTLexicon.curlyRight) {
          match(HTLexicon.comma);
        }
      }
      match(HTLexicon.curlyRight);
    } else {
      expect([HTLexicon.semicolon], consume: true);
    }
    return EnumDecl(SymbolExpr.fromToken(id), enumerations,
        isExternal: isExternal,
        isExported: isExported,
        isTopLevel: isTopLevel,
        source: _curSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }
}
