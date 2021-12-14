import 'dart:io';

import 'package:path/path.dart' as path;

import '../resource/resource_context.dart';
import '../resource/overlay/overlay_context.dart';
import '../grammar/lexicon.dart';
import '../lexer/token.dart';
import '../grammar/semantic.dart';
import '../source/source.dart';
import '../declaration/class/class_declaration.dart';
import '../error/error.dart';
import '../ast/ast.dart';
import 'parse_result.dart';
import 'parse_result_compilation.dart';
// import '../error/error_handler.dart';
import 'abstract_parser.dart';
import '../lexer/lexer.dart';

/// Walk through a token list and generates a abstract syntax tree.
class HTParser extends HTAbstractParser {
  static var anonymousFunctionIndex = 0;
  // static var anonymousStructIndex = 0;

  final _currentModuleImports = <ImportExportDecl>[];

  String? _currrentFileName;
  @override
  String? get currrentFileName => _currrentFileName;

  late String _currentModuleName;
  @override
  String? get currentModuleName => _currentModuleName;

  final _currentPrecedingComments = <Comment>[];

  HTClassDeclaration? _currentClass;
  FunctionCategory? _currentFunctionCategory;
  String? _currentStructId;

  var _leftValueLegality = false;
  final List<Map<String, String>> _markedSymbolsList = [];

  bool _hasUserDefinedConstructor = false;

  HTSource? _currentSource;

  final _cachedParseResults = <String, HTSourceParseResult>{};

  final Set<String> _cachedRecursiveParsingTargets = {};

  @override
  final HTResourceContext<HTSource> sourceContext;

  HTParser({HTResourceContext<HTSource>? context})
      : sourceContext = context ?? HTOverlayContext();

  /// Will use [type] when possible, then [source.isScript]
  List<AstNode> parseToken(List<Token> tokens,
      {HTSource? source, SourceType? type, ParserConfig? config}) {
    final nodes = <AstNode>[];
    _currentSource = source;
    _currrentFileName = source?.name;
    setTokens(tokens);
    while (curTok.type != SemanticNames.endOfFile) {
      late SourceType sourceType;
      if (type != null) {
        sourceType = type;
      } else {
        if (_currentSource != null) {
          sourceType =
              _currentSource!.isScript ? SourceType.script : SourceType.module;
        } else {
          sourceType = SourceType.module;
        }
      }
      final stmt = _parseStmt(sourceType: sourceType);
      if (stmt != null) {
        nodes.add(stmt);
      }
    }
    if (nodes.isEmpty) {
      final empty = EmptyExpr(
          source: _currentSource,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.end);
      empty.precedingComments.addAll(_currentPrecedingComments);
      _currentPrecedingComments.clear();
      nodes.add(empty);
    }
    return nodes;
  }

  List<AstNode> parse(String content, {HTSource? source}) {
    final tokens = HTLexer().lex(content);
    final nodes = parseToken(tokens, source: source);
    return nodes;
  }

  HTSourceParseResult parseSource(HTSource source, {String? moduleName}) {
    _currentModuleName = moduleName ?? source.name;
    _currrentFileName = source.name;
    _currentClass = null;
    _currentFunctionCategory = null;
    final nodes = parse(source.content, source: source);
    final result = HTSourceParseResult(source, nodes,
        imports: _currentModuleImports.toList(),
        errors: errors); // copy the list);
    _currentModuleImports.clear();
    return result;
  }

  /// Parse a string content and generate a library,
  /// will import other files.
  HTModuleParseResult parseToModule(HTSource source, {String? moduleName}) {
    final result = parseSource(source, moduleName: moduleName);
    final results = <String, HTSourceParseResult>{};

    void handleImport(HTSourceParseResult result) {
      _cachedRecursiveParsingTargets.add(result.fullName);
      for (final decl in result.imports) {
        try {
          late final HTSourceParseResult importModule;
          final importFullName = sourceContext.getAbsolutePath(
              key: decl.fromPath!, dirName: path.dirname(result.fullName));
          decl.fullName = importFullName;
          if (_cachedRecursiveParsingTargets.contains(importFullName)) {
            continue;
          } else if (_cachedParseResults.containsKey(importFullName)) {
            importModule = _cachedParseResults[importFullName]!;
          } else {
            final source2 = sourceContext.getResource(importFullName);
            importModule = parseSource(source2, moduleName: _currentModuleName);
            _cachedParseResults[importFullName] = importModule;
          }
          results[importFullName] = importModule;
          handleImport(importModule);
        } catch (error) {
          late HTError convertedError;
          if (error is FileSystemException) {
            convertedError = HTError.sourceProviderError(decl.fromPath!,
                filename: source.name,
                line: decl.line,
                column: decl.column,
                offset: decl.offset,
                length: decl.length);
          } else {
            convertedError = HTError.extern(error.toString(),
                filename: source.name,
                line: decl.line,
                column: decl.column,
                offset: decl.offset,
                length: decl.length);
          }
          result.errors.add(convertedError);
        }
      }
      _cachedRecursiveParsingTargets.remove(result.fullName);
    }

    handleImport(result);
    results[result.fullName] = result;
    final compilation =
        HTModuleParseResult(results: results, isScript: source.isScript);
    return compilation;
  }

  void _handleComment() {
    if (curTok.type == SemanticNames.singleLineComment) {
      final token = advance(1);
      final comment = Comment(token.literal,
          isMultiline: false,
          isDocumentation: token.lexeme
              .startsWith(HTLexicon.singleLineCommentDocumentationPattern));
      _currentPrecedingComments.add(comment);
    } else if (curTok.type == SemanticNames.multiLineComment) {
      final token = advance(1);
      final comment = Comment(token.literal,
          isMultiline: true,
          isDocumentation: token.lexeme
              .startsWith(HTLexicon.multiLineCommentDocumentationPattern));
      _currentPrecedingComments.add(comment);
    }
  }

  AstNode? _parseStmt({SourceType sourceType = SourceType.functionDefinition}) {
    if (curTok.type == SemanticNames.singleLineComment ||
        curTok.type == SemanticNames.multiLineComment) {
      _handleComment();
      return null;
    }

    AstNode stmt;
    final precedingCommentsOfThisStmt =
        List<Comment>.from(_currentPrecedingComments);
    _currentPrecedingComments.clear();
    if (curTok.type == SemanticNames.emptyLine) {
      advance(1);
      final empty = advance(1);
      stmt = EmptyExpr(
          line: empty.line, column: empty.column, offset: empty.offset);
    } else {
      switch (sourceType) {
        case SourceType.script:
          if (curTok.lexeme == HTLexicon.kImport) {
            stmt = _parseImportDecl();
          } else if (curTok.lexeme == HTLexicon.kExport) {
            stmt = _parseExportStmt();
          } else if (curTok.lexeme == HTLexicon.kType) {
            stmt = _parseTypeAliasDecl();
          } else {
            switch (curTok.type) {
              case HTLexicon.kAssert:
                stmt = _parseAssertStmt();
                break;
              case HTLexicon.kExternal:
                advance(1);
                switch (curTok.type) {
                  case HTLexicon.kAbstract:
                    advance(1);
                    stmt = _parseClassDecl(
                        isAbstract: true, isExternal: true, isTopLevel: true);
                    break;
                  case HTLexicon.kClass:
                    stmt = _parseClassDecl(isExternal: true, isTopLevel: true);
                    break;
                  case HTLexicon.kEnum:
                    stmt = _parseEnumDecl(isExternal: true, isTopLevel: true);
                    break;
                  case HTLexicon.kVar:
                  case HTLexicon.kFinal:
                  case HTLexicon.kConst:
                    final err = HTError.externalVar(
                        filename: _currrentFileName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors.add(err);
                    final errToken = advance(1);
                    stmt = EmptyExpr(
                        source: _currentSource,
                        line: errToken.line,
                        column: errToken.column,
                        offset: errToken.offset);
                    break;
                  case HTLexicon.kFun:
                    stmt = _parseFunction(isExternal: true, isTopLevel: true);
                    break;
                  case HTLexicon.kAsync:
                    stmt = _parseFunction(
                        isAsync: true, isExternal: true, isTopLevel: true);
                    break;
                  default:
                    final err = HTError.unexpected(
                        SemanticNames.declStmt, curTok.lexeme,
                        filename: _currrentFileName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors.add(err);
                    final errToken = advance(1);
                    stmt = EmptyExpr(
                        source: _currentSource,
                        line: errToken.line,
                        column: errToken.column,
                        offset: errToken.offset);
                }
                break;
              case HTLexicon.kAbstract:
                advance(1);
                stmt = _parseClassDecl(isAbstract: true, isTopLevel: true);
                break;
              case HTLexicon.kEnum:
                stmt = _parseEnumDecl(isTopLevel: true);
                break;
              case HTLexicon.kClass:
                stmt = _parseClassDecl(isTopLevel: true);
                break;
              case HTLexicon.kVar:
                stmt = _parseVarDecl(isMutable: true, isTopLevel: true);
                break;
              case HTLexicon.kFinal:
                stmt = _parseVarDecl(isTopLevel: true);
                break;
              case HTLexicon.kConst:
                stmt = _parseConstDecl(isTopLevel: true);
                break;
              case HTLexicon.kFun:
                if (expect([HTLexicon.kFun, SemanticNames.identifier]) ||
                    expect([
                      HTLexicon.kFun,
                      HTLexicon.bracketsLeft,
                      SemanticNames.identifier,
                      HTLexicon.bracketsRight,
                      SemanticNames.identifier
                    ])) {
                  stmt = _parseFunction(isTopLevel: true);
                } else {
                  stmt = _parseFunction(
                      category: FunctionCategory.literal, isTopLevel: true);
                }
                break;
              case HTLexicon.kAsync:
                if (expect([HTLexicon.kAsync, SemanticNames.identifier]) ||
                    expect([
                      HTLexicon.kFun,
                      HTLexicon.bracketsLeft,
                      SemanticNames.identifier,
                      HTLexicon.bracketsRight,
                      SemanticNames.identifier
                    ])) {
                  stmt = _parseFunction(isAsync: true, isTopLevel: true);
                } else {
                  stmt = _parseFunction(
                      category: FunctionCategory.literal,
                      isAsync: true,
                      isTopLevel: true);
                }
                break;
              case HTLexicon.kStruct:
                stmt =
                    _parseStructDecl(isTopLevel: true, lateInitialize: false);
                break;
              case HTLexicon.kIf:
                stmt = _parseIf();
                break;
              case HTLexicon.kWhile:
                stmt = _parseWhileStmt();
                break;
              case HTLexicon.kDo:
                stmt = _parseDoStmt();
                break;
              case HTLexicon.kFor:
                stmt = _parseForStmt();
                break;
              case HTLexicon.kWhen:
                stmt = _parseWhen();
                break;
              default:
                stmt = _parseExprStmt();
            }
          }
          break;
        case SourceType.module:
          if (curTok.lexeme == HTLexicon.kImport) {
            stmt = _parseImportDecl();
          } else if (curTok.lexeme == HTLexicon.kExport) {
            stmt = _parseExportStmt();
          } else if (curTok.lexeme == HTLexicon.kType) {
            stmt = _parseTypeAliasDecl(isTopLevel: true);
          } else {
            switch (curTok.type) {
              case HTLexicon.kAssert:
                stmt = _parseAssertStmt();
                break;
              case HTLexicon.kExternal:
                advance(1);
                switch (curTok.type) {
                  case HTLexicon.kAbstract:
                    advance(1);
                    if (curTok.type != HTLexicon.kClass) {
                      final err = HTError.unexpected(
                          SemanticNames.classDeclaration, curTok.lexeme,
                          filename: _currrentFileName,
                          line: curTok.line,
                          column: curTok.column,
                          offset: curTok.offset,
                          length: curTok.length);
                      errors.add(err);
                      final errToken = advance(1);
                      stmt = EmptyExpr(
                          source: _currentSource,
                          line: errToken.line,
                          column: errToken.column,
                          offset: errToken.offset);
                    } else {
                      stmt = _parseClassDecl(
                          isAbstract: true, isExternal: true, isTopLevel: true);
                    }
                    break;
                  case HTLexicon.kClass:
                    stmt = _parseClassDecl(isExternal: true, isTopLevel: true);
                    break;
                  case HTLexicon.kEnum:
                    stmt = _parseEnumDecl(isExternal: true, isTopLevel: true);
                    break;
                  case HTLexicon.kFun:
                    stmt = _parseFunction(isExternal: true, isTopLevel: true);
                    break;
                  case HTLexicon.kVar:
                  case HTLexicon.kFinal:
                  case HTLexicon.kConst:
                    final err = HTError.externalVar(
                        filename: _currrentFileName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors.add(err);
                    final errToken = advance(1);
                    stmt = EmptyExpr(
                        source: _currentSource,
                        line: errToken.line,
                        column: errToken.column,
                        offset: errToken.offset);
                    break;
                  default:
                    final err = HTError.unexpected(
                        SemanticNames.declStmt, curTok.lexeme,
                        filename: _currrentFileName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors.add(err);
                    final errToken = advance(1);
                    stmt = EmptyExpr(
                        source: _currentSource,
                        line: errToken.line,
                        column: errToken.column,
                        offset: errToken.offset);
                }
                break;
              case HTLexicon.kAbstract:
                advance(1);
                stmt = _parseClassDecl(isAbstract: true, isTopLevel: true);
                break;
              case HTLexicon.kEnum:
                stmt = _parseEnumDecl(isTopLevel: true);
                break;
              case HTLexicon.kClass:
                stmt = _parseClassDecl(isTopLevel: true);
                break;
              case HTLexicon.kVar:
                stmt = _parseVarDecl(
                    isMutable: true, isTopLevel: true, lateInitialize: true);
                break;
              case HTLexicon.kFinal:
                stmt = _parseVarDecl(lateInitialize: true, isTopLevel: true);
                break;
              case HTLexicon.kConst:
                stmt = _parseConstDecl(isTopLevel: true);
                break;
              case HTLexicon.kFun:
                stmt = _parseFunction(isTopLevel: true);
                break;
              case HTLexicon.kStruct:
                stmt = _parseStructDecl(isTopLevel: true);
                break;
              default:
                final err = HTError.unexpected(
                    SemanticNames.declStmt, curTok.lexeme,
                    filename: _currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors.add(err);
                final errToken = advance(1);
                stmt = EmptyExpr(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
            }
          }
          break;
        case SourceType.classDefinition:
          final isOverrided = expect([HTLexicon.kOverride], consume: true);
          final isExternal = expect([HTLexicon.kExternal], consume: true) ||
              (_currentClass?.isExternal ?? false);
          final isStatic = expect([HTLexicon.kStatic], consume: true);
          if (curTok.lexeme == HTLexicon.kType) {
            if (isExternal) {
              final err = HTError.external(SemanticNames.typeAliasDeclaration,
                  filename: _currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors.add(err);
              final errToken = advance(1);
              stmt = EmptyExpr(
                  source: _currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else {
              stmt = _parseTypeAliasDecl();
            }
          } else {
            switch (curTok.type) {
              case HTLexicon.kVar:
                stmt = _parseVarDecl(
                    classId: _currentClass?.id,
                    isOverrided: isOverrided,
                    isExternal: isExternal,
                    isMutable: true,
                    isStatic: isStatic,
                    lateInitialize: true);
                break;
              case HTLexicon.kFinal:
                stmt = _parseVarDecl(
                    classId: _currentClass?.id,
                    isOverrided: isOverrided,
                    isExternal: isExternal,
                    isStatic: isStatic,
                    lateInitialize: true);
                break;
              case HTLexicon.kConst:
                if (isStatic) {
                  stmt = _parseConstDecl(
                      classId: _currentClass?.id, isStatic: isStatic);
                } else {
                  final err = HTError.external(
                      SemanticNames.typeAliasDeclaration,
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors.add(err);
                  final errToken = advance(1);
                  stmt = EmptyExpr(
                      source: _currentSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
                }
                break;
              case HTLexicon.kFun:
                stmt = _parseFunction(
                    category: FunctionCategory.method,
                    classId: _currentClass?.id,
                    isOverrided: isOverrided,
                    isExternal: isExternal,
                    isStatic: isStatic);
                break;
              case HTLexicon.kAsync:
                if (isExternal) {
                  final err = HTError.external(SemanticNames.asyncFunction,
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors.add(err);
                  final errToken = advance(1);
                  stmt = EmptyExpr(
                      source: _currentSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
                } else {
                  stmt = _parseFunction(
                      category: FunctionCategory.method,
                      classId: _currentClass?.id,
                      isAsync: true,
                      isOverrided: isOverrided,
                      isExternal: isExternal,
                      isStatic: isStatic);
                }
                break;
              case HTLexicon.kGet:
                stmt = _parseFunction(
                    category: FunctionCategory.getter,
                    classId: _currentClass?.id,
                    isOverrided: isOverrided,
                    isExternal: isExternal,
                    isStatic: isStatic);
                break;
              case HTLexicon.kSet:
                stmt = _parseFunction(
                    category: FunctionCategory.setter,
                    classId: _currentClass?.id,
                    isOverrided: isOverrided,
                    isExternal: isExternal,
                    isStatic: isStatic);
                break;
              case HTLexicon.kConstruct:
                if (isStatic) {
                  final err = HTError.unexpected(
                      SemanticNames.declStmt, HTLexicon.kConstruct,
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors.add(err);
                  final errToken = advance(1);
                  stmt = EmptyExpr(
                      source: _currentSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
                } else if (isExternal && !_currentClass!.isExternal) {
                  final err = HTError.external(SemanticNames.ctorFunction,
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors.add(err);
                  final errToken = advance(1);
                  stmt = EmptyExpr(
                      source: _currentSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
                } else {
                  stmt = _parseFunction(
                    category: FunctionCategory.constructor,
                    classId: _currentClass?.id,
                    isExternal: isExternal,
                  );
                }
                break;
              case HTLexicon.kFactory:
                if (isStatic) {
                  final err = HTError.unexpected(
                      SemanticNames.declStmt, HTLexicon.kConstruct,
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors.add(err);
                  final errToken = advance(1);
                  stmt = EmptyExpr(
                      source: _currentSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
                } else if (isExternal && !_currentClass!.isExternal) {
                  final err = HTError.external(SemanticNames.factory,
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors.add(err);
                  final errToken = advance(1);
                  stmt = EmptyExpr(
                      source: _currentSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
                } else {
                  stmt = _parseFunction(
                    category: FunctionCategory.factoryConstructor,
                    classId: _currentClass?.id,
                    isExternal: isExternal,
                    isStatic: true,
                  );
                }
                break;
              default:
                final err = HTError.unexpected(
                    SemanticNames.declStmt, curTok.lexeme,
                    filename: _currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors.add(err);
                final errToken = advance(1);
                stmt = EmptyExpr(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
            }
          }
          break;
        case SourceType.structDefinition:
          final isExternal = expect([HTLexicon.kExternal], consume: true);
          final isStatic = expect([HTLexicon.kStatic], consume: true);
          switch (curTok.type) {
            case HTLexicon.kVar:
              stmt = _parseVarDecl(
                  classId: _currentStructId,
                  isExternal: isExternal,
                  isMutable: true,
                  isStatic: isStatic,
                  lateInitialize: true);
              break;
            case HTLexicon.kFinal:
              stmt = _parseVarDecl(
                  classId: _currentStructId,
                  isExternal: isExternal,
                  isStatic: isStatic,
                  lateInitialize: true);
              break;
            case HTLexicon.kConst:
              stmt = _parseConstDecl(
                  classId: _currentStructId, isStatic: isStatic);
              break;
            case HTLexicon.kFun:
              stmt = _parseFunction(
                  category: FunctionCategory.method,
                  classId: _currentStructId,
                  isExternal: isExternal,
                  isField: true,
                  isStatic: isStatic);
              break;
            case HTLexicon.kAsync:
              if (isExternal) {
                final err = HTError.external(SemanticNames.asyncFunction,
                    filename: _currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors.add(err);
                final errToken = advance(1);
                stmt = EmptyExpr(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              } else {
                stmt = _parseFunction(
                    category: FunctionCategory.method,
                    classId: _currentStructId,
                    isAsync: true,
                    isExternal: isExternal,
                    isField: true,
                    isStatic: isStatic);
              }
              break;
            case HTLexicon.kGet:
              stmt = _parseFunction(
                  category: FunctionCategory.getter,
                  classId: _currentStructId,
                  isExternal: isExternal,
                  isField: true,
                  isStatic: isStatic);
              break;
            case HTLexicon.kSet:
              stmt = _parseFunction(
                  category: FunctionCategory.setter,
                  classId: _currentStructId,
                  isExternal: isExternal,
                  isField: true,
                  isStatic: isStatic);
              break;
            case HTLexicon.kConstruct:
              if (isStatic) {
                final err = HTError.unexpected(
                    SemanticNames.declStmt, HTLexicon.kConstruct,
                    filename: _currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors.add(err);
                final errToken = advance(1);
                stmt = EmptyExpr(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              } else if (isExternal) {
                final err = HTError.external(SemanticNames.ctorFunction,
                    filename: _currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors.add(err);
                final errToken = advance(1);
                stmt = EmptyExpr(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              } else {
                stmt = _parseFunction(
                    category: FunctionCategory.constructor,
                    classId: _currentStructId,
                    isExternal: isExternal,
                    isField: true);
              }
              break;
            default:
              final err = HTError.unexpected(
                  SemanticNames.declStmt, curTok.lexeme,
                  filename: _currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors.add(err);
              final errToken = advance(1);
              stmt = EmptyExpr(
                  source: _currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
          }
          break;
        case SourceType.functionDefinition:
          if (curTok.lexeme == HTLexicon.kType) {
            stmt = _parseTypeAliasDecl();
          } else {
            switch (curTok.type) {
              case HTLexicon.kAssert:
                stmt = _parseAssertStmt();
                break;
              case HTLexicon.kAbstract:
                advance(1);
                stmt = _parseClassDecl(isAbstract: true);
                break;
              case HTLexicon.kEnum:
                stmt = _parseEnumDecl();
                break;
              case HTLexicon.kClass:
                stmt = _parseClassDecl();
                break;
              case HTLexicon.kVar:
                stmt = _parseVarDecl(isMutable: true);
                break;
              case HTLexicon.kFinal:
                stmt = _parseVarDecl();
                break;
              case HTLexicon.kConst:
                stmt = _parseConstDecl();
                break;
              case HTLexicon.kFun:
                if (expect([HTLexicon.kFun, SemanticNames.identifier]) ||
                    expect([
                      HTLexicon.kFun,
                      HTLexicon.bracketsLeft,
                      SemanticNames.identifier,
                      HTLexicon.bracketsRight,
                      SemanticNames.identifier
                    ])) {
                  stmt = _parseFunction();
                } else {
                  stmt = _parseFunction(category: FunctionCategory.literal);
                }
                break;
              case HTLexicon.kAsync:
                if (expect([HTLexicon.kAsync, SemanticNames.identifier]) ||
                    expect([
                      HTLexicon.kFun,
                      HTLexicon.bracketsLeft,
                      SemanticNames.identifier,
                      HTLexicon.bracketsRight,
                      SemanticNames.identifier
                    ])) {
                  stmt = _parseFunction(isAsync: true);
                } else {
                  stmt = _parseFunction(
                      category: FunctionCategory.literal, isAsync: true);
                }
                break;
              case HTLexicon.kStruct:
                stmt = _parseStructDecl(lateInitialize: false);
                break;
              case HTLexicon.kIf:
                stmt = _parseIf();
                break;
              case HTLexicon.kWhile:
                stmt = _parseWhileStmt();
                break;
              case HTLexicon.kDo:
                stmt = _parseDoStmt();
                break;
              case HTLexicon.kFor:
                stmt = _parseForStmt();
                break;
              case HTLexicon.kWhen:
                stmt = _parseWhen();
                break;
              case HTLexicon.kBreak:
                final keyword = advance(1);
                stmt = BreakStmt(keyword,
                    source: _currentSource,
                    line: keyword.line,
                    column: keyword.column,
                    offset: keyword.offset,
                    length: keyword.length);
                break;
              case HTLexicon.kContinue:
                final keyword = advance(1);
                stmt = ContinueStmt(keyword,
                    source: _currentSource,
                    line: keyword.line,
                    column: keyword.column,
                    offset: keyword.offset,
                    length: keyword.length);
                break;
              case HTLexicon.kReturn:
                if (_currentFunctionCategory != null &&
                    _currentFunctionCategory != FunctionCategory.constructor) {
                  stmt = _parseReturnStmt();
                } else {
                  final err = HTError.outsideReturn(
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors.add(err);
                  final errToken = advance(1);
                  stmt = EmptyExpr(
                      source: _currentSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
                }
                break;
              default:
                stmt = _parseExprStmt();
            }
          }
          break;
        case SourceType.expression:
          stmt = _parseExpr();
      }
    }

    if (stmt.isStatement) {
      stmt.precedingComments.addAll(precedingCommentsOfThisStmt);
      _currentPrecedingComments.clear();
    }

    if (curTok.type == SemanticNames.consumingLineEndComment) {
      final token = advance(1);
      stmt.consumingLineEndComment = Comment(token.literal);
    }

    return stmt;
  }

  AssertStmt _parseAssertStmt() {
    final keyword = match(HTLexicon.kAssert);
    final expr = _parseExpr();
    expect([HTLexicon.semicolon], consume: true);
    final stmt = AssertStmt(expr,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: expr.end - keyword.offset);
    return stmt;
  }

  /// 使用递归向下的方法生成表达式, 不断调用更底层的, 优先级更高的子Parser
  ///
  /// 赋值 = , 优先级 1, 右合并
  ///
  /// 需要判断嵌套赋值、取属性、取下标的叠加
  AstNode _parseExpr() {
    AstNode? expr;

    while (curTok.type == SemanticNames.singleLineComment ||
        curTok.type == SemanticNames.multiLineComment) {
      _handleComment();
    }

    final left = _parserTernaryExpr();
    if (HTLexicon.assignments.contains(curTok.type)) {
      if (!_leftValueLegality) {
        final err = HTError.invalidLeftValue(
            filename: _currrentFileName,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: left.length);
        errors.add(err);
      }
      final op = advance(1);
      final right = _parseExpr();
      if (op.type == HTLexicon.assign) {
        if (left is MemberExpr) {
          expr = MemberAssignExpr(left.object, left.key, right,
              source: _currentSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        } else if (left is SubExpr) {
          expr = SubAssignExpr(left.object, left.key, right,
              source: _currentSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        } else {
          expr = BinaryExpr(left, op.lexeme, right,
              source: _currentSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        }
      } else if (op.type == HTLexicon.assignIfNull) {
        if (left is MemberExpr) {
          expr = IfStmt(
            BinaryExpr(
              left,
              HTLexicon.equal,
              NullExpr(),
            ),
            MemberAssignExpr(
              left.object,
              left.key,
              right,
              source: _currentSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset,
            ),
          );
        } else if (left is SubExpr) {
          expr = IfStmt(
            BinaryExpr(
              left,
              HTLexicon.equal,
              NullExpr(),
            ),
            SubAssignExpr(
              left.object,
              left.key,
              right,
              source: _currentSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset,
            ),
          );
        } else {
          expr = IfStmt(
            BinaryExpr(
              left,
              HTLexicon.equal,
              NullExpr(),
            ),
            BinaryExpr(
              left,
              HTLexicon.assign,
              right,
              source: _currentSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset,
            ),
          );
        }
      } else {
        if (left is MemberExpr) {
          expr = MemberAssignExpr(left.object, left.key,
              BinaryExpr(left, op.lexeme.substring(0, 1), right),
              source: _currentSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        } else if (left is SubExpr) {
          expr = SubAssignExpr(left.object, left.key,
              BinaryExpr(left, op.lexeme.substring(0, 1), right),
              source: _currentSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        } else {
          expr = BinaryExpr(
              left,
              HTLexicon.assign,
              BinaryExpr(
                  left, op.lexeme.substring(0, op.lexeme.length - 1), right),
              source: _currentSource,
              line: left.line,
              column: left.column,
              offset: left.offset,
              length: curTok.offset - left.offset);
        }
      }
    } else {
      expr = left;
    }

    expr.precedingComments.addAll(_currentPrecedingComments);
    _currentPrecedingComments.clear();

    if (curTok.type == SemanticNames.consumingLineEndComment) {
      final token = advance(1);
      expr.consumingLineEndComment = Comment(token.literal);
    }

    return expr;
  }

  /// Ternery operator: e1 ? e2 : e3, precedence 3, associativity right
  AstNode _parserTernaryExpr() {
    var condition = _parseIfNullExpr();
    if (expect([HTLexicon.condition], consume: true)) {
      _leftValueLegality = false;
      final thenBranch = _parserTernaryExpr();
      match(HTLexicon.colon);
      final elseBranch = _parserTernaryExpr();
      condition = TernaryExpr(condition, thenBranch, elseBranch,
          source: _currentSource,
          line: condition.line,
          column: condition.column,
          offset: condition.offset,
          length: curTok.offset - condition.offset);
    }
    return condition;
  }

  /// If null: e1 ?? e2, precedence 4, associativity left
  AstNode _parseIfNullExpr() {
    var left = _parseLogicalOrExpr();
    if (curTok.type == HTLexicon.ifNull) {
      _leftValueLegality = false;
      while (curTok.type == HTLexicon.ifNull) {
        final op = advance(1);
        final right = _parseLogicalOrExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: _currentSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// Logical or: || , precedence 5, associativity left
  AstNode _parseLogicalOrExpr() {
    var left = _parseLogicalAndExpr();
    if (curTok.type == HTLexicon.logicalOr) {
      _leftValueLegality = false;
      while (curTok.type == HTLexicon.logicalOr) {
        final op = advance(1);
        final right = _parseLogicalAndExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: _currentSource,
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
        final op = advance(1);
        final right = _parseEqualityExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: _currentSource,
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
          source: _currentSource,
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
          source: _currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    } else if (HTLexicon.typeRelationals.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance(1);
      late final String opLexeme;
      if (op.lexeme == HTLexicon.kIs) {
        opLexeme = expect([HTLexicon.logicalNot], consume: true)
            ? HTLexicon.kIsNot
            : HTLexicon.kIs;
      } else {
        opLexeme = op.lexeme;
      }
      final right = _parseTypeExpr(isLocal: true);
      left = BinaryExpr(left, opLexeme, right,
          source: _currentSource,
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
            source: _currentSource,
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
            source: _currentSource,
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
          source: _currentSource,
          line: op.line,
          column: op.column,
          offset: op.offset,
          length: curTok.offset - op.offset);
    }
  }

  /// 后缀 e., e?., e[], e(), e++, e-- 优先级 16, 右合并
  AstNode _parseUnaryPostfixExpr() {
    var expr = _parsePrimaryExpr();
    while (HTLexicon.unaryPostfixs.contains(curTok.type)) {
      final op = advance(1);
      switch (op.type) {
        case HTLexicon.nullableMemberGet:
          _leftValueLegality = false;
          final name = match(SemanticNames.identifier);
          final key = IdentifierExpr(name.lexeme,
              isLocal: false,
              source: _currentSource,
              line: name.line,
              column: name.column,
              offset: name.offset,
              length: name.length);
          expr = MemberExpr(expr, key,
              isNullable: true,
              source: _currentSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case HTLexicon.memberGet:
          final isNullable =
              (expr is MemberExpr && expr.isNullable) ? true : false;
          _leftValueLegality = true;
          final name = match(SemanticNames.identifier);
          final key = IdentifierExpr(name.lexeme,
              isLocal: false,
              source: _currentSource,
              line: name.line,
              column: name.column,
              offset: name.offset,
              length: name.length);
          expr = MemberExpr(expr, key,
              isNullable: isNullable,
              source: _currentSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case HTLexicon.subGet:
          var indexExpr = _parseExpr();
          _leftValueLegality = true;
          match(HTLexicon.bracketsRight);
          expr = SubExpr(expr, indexExpr,
              source: _currentSource,
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
              source: _currentSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case HTLexicon.postIncrement:
        case HTLexicon.postDecrement:
          _leftValueLegality = false;
          expr = UnaryPostfixExpr(expr, op.lexeme,
              source: _currentSource,
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
      case HTLexicon.kNull:
        _leftValueLegality = false;
        final token = advance(1);
        return NullExpr(
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case SemanticNames.booleanLiteral:
        _leftValueLegality = false;
        final token =
            match(SemanticNames.booleanLiteral) as TokenBooleanLiteral;
        return BooleanExpr(token.literal,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case SemanticNames.integerLiteral:
        _leftValueLegality = false;
        final token = match(SemanticNames.integerLiteral) as TokenIntLiteral;
        return IntLiteralExpr(token.literal,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case SemanticNames.floatLiteral:
        _leftValueLegality = false;
        final token = advance(1) as TokenFloatLiteral;
        return FloatLiteralExpr(token.literal,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case SemanticNames.stringLiteral:
        _leftValueLegality = false;
        final token = advance(1) as TokenStringLiteral;
        return StringLiteralExpr(
            token.literal, token.quotationLeft, token.quotationRight,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case SemanticNames.stringInterpolation:
        _leftValueLegality = false;
        final token = advance(1) as TokenStringInterpolation;
        final interpolation = <AstNode>[];
        for (final tokens in token.interpolations) {
          final exprParser = HTParser(context: sourceContext);
          final nodes = exprParser.parseToken(tokens,
              source: _currentSource, type: SourceType.expression);
          errors.addAll(exprParser.errors);
          if (nodes.length > 1) {
            final err = HTError.stringInterpolation(
                filename: _currrentFileName,
                line: nodes.first.line,
                column: nodes.first.column,
                offset: nodes.first.offset,
                length: nodes.last.end - nodes.first.offset);
            errors.add(err);
            final errNode = EmptyExpr(
                source: _currentSource,
                line: token.line,
                column: token.column,
                offset: token.offset);
            interpolation.add(errNode);
          } else {
            // parser will at least insert a empty line astnode
            if (nodes.first is EmptyExpr) {
              final err = HTError.stringInterpolation(
                  filename: _currrentFileName,
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
            (Match m) =>
                '${HTLexicon.bracesLeft}${i++}${HTLexicon.bracesRight}');
        return StringInterpolationExpr(
            value, token.quotationLeft, token.quotationRight, interpolation,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case HTLexicon.kThis:
        _leftValueLegality = false;
        final keyword = advance(1);
        return IdentifierExpr(keyword.lexeme,
            source: _currentSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length,
            isKeyword: true);
      case HTLexicon.kSuper:
        _leftValueLegality = false;
        final keyword = advance(1);
        return IdentifierExpr(keyword.lexeme,
            source: _currentSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length,
            isKeyword: true);
      case HTLexicon.kIf:
        return _parseIf(isExpression: true);
      case HTLexicon.kWhen:
        return _parseWhen(isExpression: true);
      case HTLexicon.parenthesesLeft:
        _leftValueLegality = false;
        // a literal function expression
        final token = seekGroupClosing();
        if (token.type == HTLexicon.bracesLeft ||
            token.type == HTLexicon.doubleArrow) {
          return _parseFunction(
              category: FunctionCategory.literal, hasKeyword: false);
        }
        // a group expression
        else {
          final start = advance(1);
          final innerExpr = _parseExpr();
          final end = match(HTLexicon.parenthesesRight);
          return GroupExpr(innerExpr,
              source: _currentSource,
              line: start.line,
              column: start.column,
              offset: start.offset,
              length: end.offset + end.length - start.offset);
        }
      case HTLexicon.bracketsLeft:
        _leftValueLegality = false;
        final start = advance(1);
        var listExpr = <AstNode>[];
        while (curTok.type != HTLexicon.bracketsRight &&
            curTok.type != SemanticNames.endOfFile) {
          AstNode item;
          if (curTok.type == HTLexicon.spreadSyntax) {
            final spreadTok = advance(1);
            item = _parseExpr();
            listExpr.add(SpreadExpr(item,
                source: _currentSource,
                line: spreadTok.line,
                column: spreadTok.column,
                offset: spreadTok.offset,
                length: item.end - spreadTok.offset));
          } else {
            item = _parseExpr();
            listExpr.add(item);
          }
          if (curTok.type != HTLexicon.bracketsRight) {
            match(HTLexicon.comma);
          }
          if (curTok.type == SemanticNames.consumingLineEndComment) {
            final token = advance(1);
            item.consumingLineEndComment = Comment(token.literal);
          }
        }
        final end = match(HTLexicon.bracketsRight);
        return ListExpr(listExpr,
            source: _currentSource,
            line: start.line,
            column: start.column,
            offset: start.offset,
            length: end.end - start.offset);
      case HTLexicon.bracesLeft:
        return _parseStructObj();
      case HTLexicon.kStruct:
        return _parseStructObj(hasKeyword: true);
      // _leftValueLegality = false;
      // final start = advance(1);
      // var mapExpr = <AstNode, AstNode>{};
      // while (curTok.type != HTLexicon.curlyRight) {
      //   var keyExpr = _parseExpr();
      //   match(HTLexicon.colon);
      //   var valueExpr = _parseExpr();
      //   mapExpr[keyExpr] = valueExpr;
      //   if (curTok.type != HTLexicon.curlyRight) {
      //     match(HTLexicon.comma);
      //   }
      // }
      // final end = match(HTLexicon.curlyRight);
      // return MapExpr(mapExpr,
      //     source: _curSource,
      //     line: start.line,
      //     column: start.column,
      //     offset: start.offset,
      //     length: end.offset + end.length - start.offset);
      case HTLexicon.kFun:
        return _parseFunction(category: FunctionCategory.literal);
      case SemanticNames.identifier:
        // literal function type
        if (curTok.lexeme == HTLexicon.kFun) {
          _leftValueLegality = false;
          return _parseTypeExpr();
        }
        // TODO: literal interface type
        else {
          _leftValueLegality = true;
          final id = advance(1);
          // TODO: type arguments
          return IdentifierExpr.fromToken(id);
        }
      default:
        final err = HTError.unexpected(SemanticNames.expression, curTok.lexeme,
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
        final errToken = advance(1);
        return EmptyExpr(
            source: _currentSource,
            line: errToken.line,
            column: errToken.column,
            offset: errToken.offset);
    }
  }

  TypeExpr _parseTypeExpr({bool isLocal = false}) {
    // function type
    if (curTok.type == HTLexicon.parenthesesLeft) {
      final startTok = advance(1);
      // TODO: genericTypeParameters 泛型参数
      final parameters = <ParamTypeExpr>[];
      var isOptional = false;
      var isNamed = false;
      var isVariadic = false;
      while (curTok.type != HTLexicon.parenthesesRight &&
          curTok.type != SemanticNames.endOfFile) {
        final start = curTok;
        if (!isOptional) {
          isOptional = expect([HTLexicon.bracketsLeft], consume: true);
          if (!isOptional && !isNamed) {
            isNamed = expect([HTLexicon.bracesLeft], consume: true);
          }
        }
        late final TypeExpr paramType;
        IdentifierExpr? paramSymbol;
        if (!isNamed) {
          isVariadic = expect([HTLexicon.variadicArgs], consume: true);
        } else {
          final paramId = match(SemanticNames.identifier);
          paramSymbol = IdentifierExpr.fromToken(paramId);
          match(HTLexicon.colon);
        }
        paramType = _parseTypeExpr();
        final param = ParamTypeExpr(paramType,
            isOptional: isOptional,
            isVariadic: isVariadic,
            id: paramSymbol,
            source: _currentSource,
            line: start.line,
            column: start.column,
            offset: start.offset,
            length: curTok.offset - start.offset);
        if (isOptional && expect([HTLexicon.bracketsRight], consume: true)) {
          break;
        } else if (isNamed && expect([HTLexicon.bracesRight], consume: true)) {
          break;
        } else if (curTok.type != HTLexicon.parenthesesRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == SemanticNames.consumingLineEndComment) {
          final token = advance(1);
          param.consumingLineEndComment = Comment(token.literal);
        }
        parameters.add(param);
        if (isVariadic) {
          break;
        }
      }
      match(HTLexicon.parenthesesRight);
      match(HTLexicon.singleArrow);
      final returnType = _parseTypeExpr();
      return FuncTypeExpr(returnType,
          isLocal: isLocal,
          paramTypes: parameters,
          hasOptionalParam: isOptional,
          hasNamedParam: isNamed,
          source: _currentSource,
          line: startTok.line,
          column: startTok.column,
          offset: startTok.offset,
          length: curTok.offset - startTok.offset);
    }
    // TODO: interface type
    // else if (curTok.type == HTLexicon.curlyLeft) {
    //   return StructuralTypeExpr();
    // }
    // nominal type
    else {
      final idTok = match(SemanticNames.identifier);
      final id = IdentifierExpr.fromToken(idTok);
      final typeArgs = <TypeExpr>[];
      if (expect([HTLexicon.chevronsLeft], consume: true)) {
        if (curTok.type == HTLexicon.chevronsRight) {
          final err = HTError.emptyTypeArgs(
              filename: _currrentFileName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.end - idTok.offset);
          errors.add(err);
        }
        while ((curTok.type != HTLexicon.chevronsRight) &&
            (curTok.type != SemanticNames.endOfFile)) {
          final typeArg = _parseTypeExpr();
          expect([HTLexicon.comma], consume: true);
          if (curTok.type == SemanticNames.consumingLineEndComment) {
            final token = advance(1);
            typeArg.consumingLineEndComment = Comment(token.literal);
          }
          typeArgs.add(typeArg);
        }
        match(HTLexicon.chevronsRight);
      }
      final isNullable = expect([HTLexicon.nullable], consume: true);
      return TypeExpr(
        id: id,
        arguments: typeArgs,
        isNullable: isNullable,
        isLocal: isLocal,
        source: _currentSource,
        line: idTok.line,
        column: idTok.column,
        offset: idTok.offset,
      );
    }
  }

  BlockStmt _parseBlockStmt(
      {String? id,
      SourceType sourceType = SourceType.functionDefinition,
      bool hasOwnNamespace = true}) {
    final startTok = match(HTLexicon.bracesLeft);
    final statements = <AstNode>[];
    while (curTok.type != HTLexicon.bracesRight &&
        curTok.type != SemanticNames.endOfFile) {
      final stmt = _parseStmt(sourceType: sourceType);
      if (stmt != null) {
        statements.add(stmt);
      }
    }
    final endTok = match(HTLexicon.bracesRight);
    if (statements.isEmpty) {
      final empty = EmptyExpr(
          source: _currentSource,
          line: endTok.line,
          column: endTok.column,
          offset: endTok.offset,
          length: endTok.offset - startTok.end);
      empty.precedingComments.addAll(_currentPrecedingComments);
      _currentPrecedingComments.clear();
      statements.add(empty);
    }

    return BlockStmt(statements,
        id: id,
        hasOwnNamespace: hasOwnNamespace,
        source: _currentSource,
        line: startTok.line,
        column: startTok.column,
        offset: startTok.offset,
        length: curTok.offset - startTok.offset);
  }

  void _handleCallArguments(
      List<AstNode> positionalArgs, Map<String, AstNode> namedArgs) {
    var isNamed = false;
    while ((curTok.type != HTLexicon.parenthesesRight) &&
        (curTok.type != SemanticNames.endOfFile)) {
      if ((!isNamed &&
              expect([SemanticNames.identifier, HTLexicon.colon],
                  consume: false)) ||
          isNamed) {
        isNamed = true;
        final name = match(SemanticNames.identifier).lexeme;
        match(HTLexicon.colon);
        final namedArg = _parseExpr();
        if (curTok.type != HTLexicon.parenthesesRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == SemanticNames.consumingLineEndComment) {
          final token = advance(1);
          namedArg.consumingLineEndComment = Comment(token.literal);
        }
        namedArgs[name] = namedArg;
      } else {
        late AstNode positionalArg;
        if (curTok.type == HTLexicon.spreadSyntax) {
          final spreadTok = advance(1);
          final spread = _parseExpr();
          positionalArg = SpreadExpr(spread,
              source: _currentSource,
              line: spreadTok.line,
              column: spreadTok.column,
              offset: spreadTok.offset,
              length: spread.end - spreadTok.offset);
        } else {
          positionalArg = _parseExpr();
        }
        if (curTok.type != HTLexicon.parenthesesRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == SemanticNames.consumingLineEndComment) {
          final token = advance(1);
          positionalArg.consumingLineEndComment = Comment(token.literal);
        }
        positionalArgs.add(positionalArg);
      }
    }
    match(HTLexicon.parenthesesRight);
  }

  AstNode _parseExprStmt() {
    final expr = _parseExpr();
    expect([HTLexicon.semicolon], consume: true);
    final stmt = ExprStmt(expr,
        source: _currentSource,
        line: expr.line,
        column: expr.column,
        offset: expr.offset,
        length: curTok.offset - expr.offset);
    return stmt;
  }

  ReturnStmt _parseReturnStmt() {
    var keyword = advance(1);
    AstNode? expr;
    if (curTok.type == HTLexicon.kSuper) {
      final err = HTError.unexpected(SemanticNames.expression, curTok.lexeme,
          filename: _currrentFileName,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.length);
      errors.add(err);
      advance(1);
    } else {
      if (curTok.type != HTLexicon.bracesRight &&
          curTok.type != HTLexicon.semicolon &&
          curTok.type != SemanticNames.endOfFile) {
        expr = _parseExpr();
      }
    }
    final hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
    return ReturnStmt(keyword,
        value: expr,
        source: _currentSource,
        hasEndOfStmtMark: hasEndOfStmtMark,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  AstNode _parseExprOrStmtOrBlock({bool isExpression = false}) {
    if (curTok.type == HTLexicon.bracesLeft) {
      return _parseBlockStmt(id: SemanticNames.elseBranch);
    } else {
      if (isExpression) {
        return _parseExpr();
      } else {
        final startTok = curTok;
        var node = _parseStmt();
        if (node == null) {
          final err = HTError.unexpected(
              SemanticNames.expression, curTok.lexeme,
              filename: _currrentFileName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.length);
          errors.add(err);
          node = EmptyExpr(
              source: _currentSource,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.offset - startTok.offset);
          node.precedingComments.addAll(_currentPrecedingComments);
          _currentPrecedingComments.clear();
        }
        return node;
      }
    }
  }

  IfStmt _parseIf({bool isExpression = false}) {
    final keyword = match(HTLexicon.kIf);
    match(HTLexicon.parenthesesLeft);
    final condition = _parseExpr();
    match(HTLexicon.parenthesesRight);
    var thenBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
    AstNode? elseBranch;
    if (isExpression) {
      match(HTLexicon.kElse);
      elseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
    } else {
      if (expect([HTLexicon.kElse], consume: true)) {
        elseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
      }
    }
    return IfStmt(condition, thenBranch,
        isExpression: isExpression,
        elseBranch: elseBranch,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  WhileStmt _parseWhileStmt() {
    final keyword = match(HTLexicon.kWhile);
    match(HTLexicon.parenthesesLeft);
    final condition = _parseExpr();
    match(HTLexicon.parenthesesRight);
    final loop = _parseBlockStmt(id: SemanticNames.whileLoop);
    return WhileStmt(condition, loop,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  DoStmt _parseDoStmt() {
    final keyword = advance(1);
    final loop = _parseBlockStmt(id: SemanticNames.doLoop);
    AstNode? condition;
    if (expect([HTLexicon.kWhile], consume: true)) {
      match(HTLexicon.parenthesesLeft);
      condition = _parseExpr();
      match(HTLexicon.parenthesesRight);
    }
    return DoStmt(loop, condition,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  AstNode _parseForStmt() {
    final keyword = advance(1);
    final hasBracket = expect([HTLexicon.parenthesesLeft], consume: true);
    final forStmtType = peek(2).lexeme;
    VarDecl? decl;
    AstNode? condition;
    AstNode? increment;
    final newSymbolMap = <String, String>{};
    _markedSymbolsList.add(newSymbolMap);
    if (forStmtType == HTLexicon.kIn || forStmtType == HTLexicon.kOf) {
      if (!HTLexicon.varDeclKeywords.contains(curTok.type)) {
        final err = HTError.unexpected(
            SemanticNames.variableDeclaration, curTok.type,
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
      decl = _parseVarDecl(
          // typeInferrence: curTok.type != HTLexicon.VAR,
          isMutable: curTok.type != HTLexicon.kFinal);
      advance(1);
      final collection = _parseExpr();
      if (hasBracket) {
        match(HTLexicon.parenthesesRight);
      }
      final loop = _parseBlockStmt(id: SemanticNames.forLoop);
      return ForRangeStmt(decl, collection, loop,
          hasBracket: hasBracket,
          iterateValue: forStmtType == HTLexicon.kOf,
          source: _currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    } else {
      if (!expect([HTLexicon.semicolon], consume: false)) {
        decl = _parseVarDecl(
            // typeInferrence: curTok.type != HTLexicon.VAR,
            isMutable: curTok.type != HTLexicon.kFinal,
            hasEndOfStatement: true);
      } else {
        match(HTLexicon.semicolon);
      }
      if (!expect([HTLexicon.semicolon], consume: false)) {
        condition = _parseExpr();
      }
      match(HTLexicon.semicolon);
      if (!expect([HTLexicon.parenthesesRight], consume: false)) {
        increment = _parseExpr();
      }
      if (hasBracket) {
        match(HTLexicon.parenthesesRight);
      }
      final loop = _parseBlockStmt(id: SemanticNames.forLoop);
      return ForStmt(decl, condition, increment, loop,
          hasBracket: hasBracket,
          source: _currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    }
  }

  WhenStmt _parseWhen({bool isExpression = false}) {
    final keyword = advance(1);
    AstNode? condition;
    if (curTok.type != HTLexicon.bracesLeft) {
      match(HTLexicon.parenthesesLeft);
      condition = _parseExpr();
      match(HTLexicon.parenthesesRight);
    }
    final options = <AstNode, AstNode>{};
    AstNode? elseBranch;
    match(HTLexicon.bracesLeft);
    while (curTok.type != HTLexicon.bracesRight &&
        curTok.type != SemanticNames.endOfFile) {
      if (curTok.lexeme == HTLexicon.kElse) {
        advance(1);
        match(HTLexicon.singleArrow);
        elseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
      } else {
        final caseExpr = _parseExpr();
        match(HTLexicon.singleArrow);
        var caseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
        options[caseExpr] = caseBranch;
      }
    }
    match(HTLexicon.bracesRight);
    return WhenStmt(options, elseBranch, condition,
        isExpression: isExpression,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  List<GenericTypeParameterExpr> _getGenericParams() {
    final genericParams = <GenericTypeParameterExpr>[];
    if (expect([HTLexicon.chevronsLeft], consume: true)) {
      while ((curTok.type != HTLexicon.chevronsRight) &&
          (curTok.type != SemanticNames.endOfFile)) {
        final idTok = match(SemanticNames.identifier);
        final id = IdentifierExpr.fromToken(idTok);
        final param = GenericTypeParameterExpr(id,
            source: _currentSource,
            line: idTok.line,
            column: idTok.column,
            offset: idTok.offset,
            length: curTok.offset - idTok.offset);
        if (curTok.type != HTLexicon.chevronsRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == SemanticNames.consumingLineEndComment) {
          final token = advance(1);
          param.consumingLineEndComment = Comment(token.literal);
        }
        genericParams.add(param);
      }
      match(HTLexicon.chevronsRight);
    }
    return genericParams;
  }

  ImportExportDecl _parseImportDecl() {
    // TODO: duplicate import and self import error.
    final keyword = advance(1); // not a keyword so don't use match
    final showList = <IdentifierExpr>[];
    if (curTok.type == HTLexicon.bracesLeft) {
      advance(1);
      if (curTok.type == HTLexicon.bracesRight) {
        final err = HTError.emptyImportList(
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.end - keyword.offset);
        errors.add(err);
      }
      while (curTok.type != HTLexicon.bracesRight &&
          curTok.type != SemanticNames.endOfFile) {
        final idTok = match(SemanticNames.identifier);
        final id = IdentifierExpr.fromToken(idTok);
        if (curTok.type != HTLexicon.bracesRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == SemanticNames.consumingLineEndComment) {
          final token = advance(1);
          id.consumingLineEndComment = Comment(token.literal);
        }
        showList.add(id);
      }
      match(HTLexicon.bracesRight);
      // check lexeme here because expect() can only deal with token type
      final fromKeyword = advance(1).lexeme;
      if (fromKeyword != HTLexicon.kFrom) {
        final err = HTError.unexpected(HTLexicon.kFrom, curTok.lexeme,
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
    }
    final key = match(SemanticNames.stringLiteral);
    var hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
    IdentifierExpr? alias;
    if (!hasEndOfStmtMark && expect([HTLexicon.kAs], consume: true)) {
      final aliasId = match(SemanticNames.identifier);
      alias = IdentifierExpr.fromToken(aliasId);
      hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
    }
    final stmt = ImportExportDecl(
        fromPath: key.literal,
        showList: showList,
        alias: alias,
        hasEndOfStmtMark: hasEndOfStmtMark,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
    _currentModuleImports.add(stmt);
    expect([HTLexicon.semicolon], consume: true);
    return stmt;
  }

  ImportExportDecl _parseExportStmt() {
    final keyword = advance(1); // not a keyword so don't use match
    if (curTok.type == HTLexicon.bracesLeft) {
      advance(1);
      final showList = <IdentifierExpr>[];
      while (curTok.type != HTLexicon.bracesRight &&
          curTok.type != SemanticNames.endOfFile) {
        final idTok = match(SemanticNames.identifier);
        final id = IdentifierExpr.fromToken(idTok);
        if (curTok.type != HTLexicon.bracesRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == SemanticNames.consumingLineEndComment) {
          final token = advance(1);
          id.consumingLineEndComment = Comment(token.literal);
        }
        showList.add(id);
      }
      match(HTLexicon.bracesRight);
      String? fromPath;
      var hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
      if (!hasEndOfStmtMark && curTok.lexeme == HTLexicon.kFrom) {
        advance(1);
        fromPath = match(SemanticNames.stringLiteral).literal;
        hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
      }
      final stmt = ImportExportDecl(
          fromPath: fromPath,
          showList: showList,
          hasEndOfStmtMark: hasEndOfStmtMark,
          isExported: true,
          source: _currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
      if (fromPath != null) {
        _currentModuleImports.add(stmt);
      }
      return stmt;
    } else {
      final key = match(SemanticNames.stringLiteral);
      final hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
      final stmt = ImportExportDecl(
          fromPath: key.literal,
          hasEndOfStmtMark: hasEndOfStmtMark,
          isExported: true,
          source: _currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
      _currentModuleImports.add(stmt);
      return stmt;
    }
  }

  TypeAliasDecl _parseTypeAliasDecl(
      {String? classId, bool isTopLevel = false}) {
    final keyword = advance(1);
    final idTok = match(SemanticNames.identifier);
    final id = IdentifierExpr.fromToken(idTok);
    final genericParameters = _getGenericParams();
    match(HTLexicon.assign);
    final value = _parseTypeExpr();
    return TypeAliasDecl(id, value,
        classId: classId,
        genericTypeParameters: genericParameters,
        isTopLevel: isTopLevel,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  ConstDecl _parseConstDecl(
      {String? classId, bool isStatic = false, bool isTopLevel = false}) {
    final keyword = match(HTLexicon.kConst);
    final idTok = match(SemanticNames.identifier);
    final id = IdentifierExpr.fromToken(idTok);
    match(HTLexicon.assign);
    final constExpr = _parseExpr();
    if (constExpr is! IntLiteralExpr &&
        constExpr is! FloatLiteralExpr &&
        constExpr is! StringLiteralExpr) {
      final err = HTError.notConstValue(
          filename: _currrentFileName,
          line: constExpr.line,
          column: constExpr.column,
          offset: constExpr.offset,
          length: constExpr.length);
      errors.add(err);
    }
    final hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
    return ConstDecl(
      id,
      constExpr,
      classId: classId,
      hasEndOfStmtMark: hasEndOfStmtMark,
      isStatic: isStatic,
      source: _currentSource,
      line: keyword.line,
      column: keyword.column,
      offset: keyword.offset,
      length: constExpr.end - keyword.offset,
    );
  }

  VarDecl _parseVarDecl(
      {String? classId,
      bool isField = false,
      // bool typeInferrence = false,
      bool isOverrided = false,
      bool isExternal = false,
      bool isStatic = false,
      bool isMutable = false,
      bool isTopLevel = false,
      bool lateInitialize = false,
      AstNode? additionalInitializer,
      bool hasEndOfStatement = false}) {
    if (isField) {
      final idTok = advance(1);
      late IdentifierExpr id;
      if (idTok.type == SemanticNames.identifier ||
          idTok.type == SemanticNames.stringLiteral) {
        id = IdentifierExpr.fromToken(idTok);
      } else {
        final err = HTError.structMemberId(
            filename: _currrentFileName,
            line: idTok.line,
            column: idTok.column,
            offset: idTok.offset,
            length: idTok.length);
        errors.add(err);
      }
      match(HTLexicon.colon);
      final initializer = _parseExpr();
      return VarDecl(id,
          classId: classId,
          initializer: initializer,
          isMutable: isMutable,
          lateInitialize: lateInitialize,
          source: _currentSource,
          line: idTok.line,
          column: idTok.column,
          offset: idTok.offset,
          length: curTok.offset - idTok.offset);
    } else {
      final keyword = advance(1);
      final idTok = match(SemanticNames.identifier);
      final id = IdentifierExpr.fromToken(idTok);
      String? internalName;
      if (classId != null && isExternal) {
        if (!(_currentClass!.isExternal) && !isStatic) {
          final err = HTError.externalMember(
              filename: _currrentFileName,
              line: keyword.line,
              column: keyword.column,
              offset: curTok.offset,
              length: curTok.length);
          errors.add(err);
        }
        internalName = '$classId.${idTok.lexeme}';
      }
      TypeExpr? declType;
      if (expect([HTLexicon.colon], consume: true)) {
        declType = _parseTypeExpr();
      }
      var initializer = additionalInitializer;
      if (expect([HTLexicon.assign], consume: true)) {
        initializer = _parseExpr();
      }
      bool hasEndOfStmtMark = hasEndOfStatement;
      if (hasEndOfStatement) {
        match(HTLexicon.semicolon);
      } else {
        hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
      }
      return VarDecl(id,
          internalName: internalName,
          classId: classId,
          declType: declType,
          initializer: initializer,
          hasEndOfStmtMark: hasEndOfStmtMark,
          isExternal: isExternal,
          isStatic: isStatic,
          isMutable: isMutable,
          isTopLevel: isTopLevel,
          lateInitialize: lateInitialize,
          source: _currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    }
  }

  FuncDecl _parseFunction(
      {FunctionCategory category = FunctionCategory.normal,
      String? classId,
      bool hasKeyword = true,
      bool isAsync = false,
      bool isField = false,
      bool isOverrided = false,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isTopLevel = false}) {
    final savedCurFuncType = _currentFunctionCategory;
    _currentFunctionCategory = category;
    late Token startTok;
    if (category != FunctionCategory.literal || hasKeyword) {
      // there are multiple keyword for function, so don't use match here.
      startTok = advance(1);
    }
    String? externalTypedef;
    if (!isExternal &&
        (isStatic ||
            category == FunctionCategory.normal ||
            category == FunctionCategory.literal)) {
      if (expect([HTLexicon.bracketsLeft], consume: true)) {
        externalTypedef = match(SemanticNames.identifier).lexeme;
        match(HTLexicon.bracketsRight);
      }
    }
    Token? id;
    late String internalName;
    // to distinguish getter and setter, and to give default constructor a name
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
        internalName = (id == null)
            ? '${SemanticNames.anonymousFunction}${HTParser.anonymousFunctionIndex++}'
            : id.lexeme;
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
        expect([HTLexicon.parenthesesLeft], consume: true)) {
      final startTok = curTok;
      hasParamDecls = true;
      var isOptional = false;
      var isNamed = false;
      var isVariadic = false;
      while ((curTok.type != HTLexicon.parenthesesRight) &&
          (curTok.type != HTLexicon.bracketsRight) &&
          (curTok.type != HTLexicon.bracesRight) &&
          (curTok.type != SemanticNames.endOfFile)) {
        // 可选参数, 根据是否有方括号判断, 一旦开始了可选参数, 则不再增加参数数量arity要求
        if (!isOptional) {
          isOptional = expect([HTLexicon.bracketsLeft], consume: true);
          if (!isOptional && !isNamed) {
            //检查命名参数, 根据是否有花括号判断
            isNamed = expect([HTLexicon.bracesLeft], consume: true);
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
        final paramSymbol = IdentifierExpr.fromToken(paramId);
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
                filename: _currrentFileName,
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
            source: _currentSource,
            line: paramId.line,
            column: paramId.column,
            offset: paramId.offset,
            length: curTok.offset - paramId.offset);
        if (curTok.type != HTLexicon.bracketsRight &&
            curTok.type != HTLexicon.bracesRight &&
            curTok.type != HTLexicon.parenthesesRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == SemanticNames.consumingLineEndComment) {
          final token = advance(1);
          param.consumingLineEndComment = Comment(token.literal);
        }
        paramDecls.add(param);
        if (isVariadic) {
          isFuncVariadic = true;
          break;
        }
      }
      if (isOptional) {
        match(HTLexicon.bracketsRight);
      } else if (isNamed) {
        match(HTLexicon.bracesRight);
      }

      final endTok = match(HTLexicon.parenthesesRight);

      // setter can only have one parameter
      if ((category == FunctionCategory.setter) && (minArity != 1)) {
        final err = HTError.setterArity(
            filename: _currrentFileName,
            line: startTok.line,
            column: startTok.column,
            offset: startTok.offset,
            length: endTok.offset + endTok.length - startTok.offset);
        errors.add(err);
      }
    }
    TypeExpr? returnType;
    RedirectingConstructorCallExpr? referCtor;
    // the return value type declaration
    if (expect([HTLexicon.singleArrow], consume: true)) {
      if (category == FunctionCategory.constructor ||
          category == FunctionCategory.setter) {
        final err = HTError.unexpected(
            SemanticNames.functionDefinition, SemanticNames.returnType,
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
      returnType = _parseTypeExpr();
    }
    // referring to another constructor
    else if (expect([HTLexicon.colon], consume: true)) {
      if (category != FunctionCategory.constructor) {
        final lastTok = peek(-1);
        final err = HTError.nonCotrWithReferCtor(
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: lastTok.offset,
            length: lastTok.length);
        errors.add(err);
      }
      if (isExternal) {
        final lastTok = peek(-1);
        final err = HTError.externalCtorWithReferCtor(
            filename: _currrentFileName,
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
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: ctorCallee.offset,
            length: ctorCallee.length);
        errors.add(err);
      }
      Token? ctorKey;
      if (expect([HTLexicon.memberGet], consume: true)) {
        ctorKey = match(SemanticNames.identifier);
        match(HTLexicon.parenthesesLeft);
      } else {
        match(HTLexicon.parenthesesLeft);
      }
      var positionalArgs = <AstNode>[];
      var namedArgs = <String, AstNode>{};
      _handleCallArguments(positionalArgs, namedArgs);
      referCtor = RedirectingConstructorCallExpr(
          IdentifierExpr.fromToken(ctorCallee), positionalArgs, namedArgs,
          key: ctorKey != null ? IdentifierExpr.fromToken(ctorKey) : null,
          source: _currentSource,
          line: ctorCallee.line,
          column: ctorCallee.column,
          offset: ctorCallee.offset,
          length: curTok.offset - ctorCallee.offset);
    }
    bool isExpressionBody = false;
    bool hasEndOfStmtMark = false;
    AstNode? definition;
    if (curTok.type == HTLexicon.bracesLeft) {
      if (category == FunctionCategory.literal && !hasKeyword) {
        startTok = curTok;
      }
      definition = _parseBlockStmt(id: SemanticNames.functionCall);
    } else if (expect([HTLexicon.doubleArrow], consume: true)) {
      isExpressionBody = true;
      if (category == FunctionCategory.literal && !hasKeyword) {
        startTok = curTok;
      }
      definition = _parseExpr();
      hasEndOfStmtMark = expect([HTLexicon.semicolon], consume: true);
    } else if (expect([HTLexicon.assign], consume: true)) {
      final err = HTError.unsupported(
          SemanticNames.redirectingFunctionDefinition,
          filename: _currrentFileName,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.length);
      errors.add(err);
    } else {
      if (category != FunctionCategory.constructor &&
          category != FunctionCategory.literal &&
          !isExternal &&
          !(_currentClass?.isAbstract ?? false)) {
        final err = HTError.missingFuncBody(internalName,
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
      if (category != FunctionCategory.literal) {
        expect([HTLexicon.semicolon], consume: true);
      }
    }
    _currentFunctionCategory = savedCurFuncType;
    return FuncDecl(internalName, paramDecls,
        id: id != null ? IdentifierExpr.fromToken(id) : null,
        classId: classId,
        genericTypeParameters: genericParameters,
        externalTypeId: externalTypedef,
        returnType: returnType,
        redirectingCtorCallExpr: referCtor,
        hasParamDecls: hasParamDecls,
        minArity: minArity,
        maxArity: maxArity,
        isExpressionBody: isExpressionBody,
        hasEndOfStmtMark: hasEndOfStmtMark,
        definition: definition,
        isField: isField,
        isExternal: isExternal,
        isStatic: isStatic,
        isConst: isConst,
        isVariadic: isFuncVariadic,
        isTopLevel: isTopLevel,
        category: category,
        source: _currentSource,
        line: startTok.line,
        column: startTok.column,
        offset: startTok.offset,
        length: curTok.offset - startTok.offset);
  }

  ClassDecl _parseClassDecl(
      {String? classId,
      bool isExternal = false,
      bool isAbstract = false,
      bool isTopLevel = false}) {
    final keyword = match(HTLexicon.kClass);
    if (_currentClass != null && _currentClass!.isNested) {
      final err = HTError.nestedClass(
          filename: _currrentFileName,
          line: curTok.line,
          column: curTok.column,
          offset: keyword.offset,
          length: keyword.length);
      errors.add(err);
    }
    final id = match(SemanticNames.identifier);
    final genericParameters = _getGenericParams();
    TypeExpr? superClassType;
    if (expect([HTLexicon.kExtends], consume: true)) {
      if (curTok.lexeme == id.lexeme) {
        final err = HTError.extendsSelf(
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors.add(err);
      }
      superClassType = _parseTypeExpr();
    }
    final savedClass = _currentClass;
    _currentClass = HTClassDeclaration(
        id: id.lexeme,
        classId: classId,
        isExternal: isExternal,
        isAbstract: isAbstract);
    final savedHasUsrDefCtor = _hasUserDefinedConstructor;
    _hasUserDefinedConstructor = false;
    final definition = _parseBlockStmt(
        sourceType: SourceType.classDefinition,
        hasOwnNamespace: false,
        id: SemanticNames.classDefinition);
    final decl = ClassDecl(IdentifierExpr.fromToken(id), definition,
        genericTypeParameters: genericParameters,
        superType: superClassType,
        isExternal: isExternal,
        isAbstract: isAbstract,
        isTopLevel: isTopLevel,
        hasUserDefinedConstructor: _hasUserDefinedConstructor,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
    _hasUserDefinedConstructor = savedHasUsrDefCtor;
    _currentClass = savedClass;
    return decl;
  }

  EnumDecl _parseEnumDecl({bool isExternal = false, bool isTopLevel = false}) {
    final keyword = match(HTLexicon.kEnum);
    final id = match(SemanticNames.identifier);
    var enumerations = <IdentifierExpr>[];
    if (expect([HTLexicon.bracesLeft], consume: true)) {
      while (curTok.type != HTLexicon.bracesRight &&
          curTok.type != SemanticNames.endOfFile) {
        final enumIdTok = match(SemanticNames.identifier);
        final enumId = IdentifierExpr.fromToken(enumIdTok);
        if (curTok.type != HTLexicon.bracesRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == SemanticNames.consumingLineEndComment) {
          final token = advance(1);
          enumId.consumingLineEndComment = Comment(token.literal);
        }
        enumerations.add(enumId);
      }
      match(HTLexicon.bracesRight);
    } else {
      expect([HTLexicon.semicolon], consume: true);
    }
    return EnumDecl(IdentifierExpr.fromToken(id), enumerations,
        isExternal: isExternal,
        isTopLevel: isTopLevel,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  StructDecl _parseStructDecl(
      {bool isTopLevel = false, bool lateInitialize = true}) {
    final keyword = match(HTLexicon.kStruct);
    final idTok = match(SemanticNames.identifier);
    final id = IdentifierExpr.fromToken(idTok);
    IdentifierExpr? prototypeId;
    if (expect([HTLexicon.kExtends], consume: true)) {
      final prototypeIdTok = match(SemanticNames.identifier);
      if (prototypeIdTok.lexeme == id.id) {
        final err = HTError.extendsSelf(
            filename: _currrentFileName,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length);
        errors.add(err);
      }
      prototypeId = IdentifierExpr.fromToken(prototypeIdTok);
    } else if (id.id != HTLexicon.prototype) {
      prototypeId = IdentifierExpr(HTLexicon.prototype);
    }
    final savedStructId = _currentStructId;
    _currentStructId = id.id;
    final definition = <AstNode>[];
    final startTok = match(HTLexicon.bracesLeft);
    while (curTok.type != HTLexicon.bracesRight &&
        curTok.type != SemanticNames.endOfFile) {
      final stmt = _parseStmt(sourceType: SourceType.structDefinition);
      if (stmt != null) {
        definition.add(stmt);
      }
    }
    final endTok = match(HTLexicon.bracesRight);
    if (definition.isEmpty) {
      final empty = EmptyExpr(
          source: _currentSource,
          line: endTok.line,
          column: endTok.column,
          offset: endTok.offset,
          length: endTok.offset - startTok.end);
      empty.precedingComments.addAll(_currentPrecedingComments);
      _currentPrecedingComments.clear();
      definition.add(empty);
    }
    _currentStructId = savedStructId;
    return StructDecl(id, definition,
        prototypeId: prototypeId,
        isTopLevel: isTopLevel,
        lateInitialize: lateInitialize,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  StructObjExpr _parseStructObj({bool hasKeyword = false}) {
    IdentifierExpr? prototypeId;
    if (hasKeyword) {
      match(HTLexicon.kStruct);
      if (hasKeyword && expect([HTLexicon.kExtends], consume: true)) {
        final idTok = match(SemanticNames.identifier);
        prototypeId = IdentifierExpr.fromToken(idTok);
      }
    } else {
      prototypeId = IdentifierExpr(HTLexicon.prototype);
    }
    // final internalName =
    //     '${SemanticNames.anonymousStruct}${HTParser.anonymousStructIndex++}';
    final structBlockStartTok = match(HTLexicon.bracesLeft);
    final fields = <StructObjField>[];
    while (curTok.type != HTLexicon.bracesRight &&
        curTok.type != SemanticNames.endOfFile) {
      if (curTok.type == SemanticNames.identifier ||
          curTok.type == SemanticNames.stringLiteral) {
        final keyTok = advance(1);
        late final StructObjField field;
        if (curTok.type == HTLexicon.comma ||
            curTok.type == HTLexicon.bracesRight) {
          final id = IdentifierExpr.fromToken(keyTok);
          field = StructObjField(key: keyTok.lexeme, value: id);
        } else {
          match(HTLexicon.colon);
          final value = _parseExpr();
          field = StructObjField(key: keyTok.lexeme, value: value);
        }
        if (curTok.type != HTLexicon.bracesRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == SemanticNames.consumingLineEndComment) {
          final token = advance(1);
          field.consumingLineEndComment = Comment(token.literal);
        }
        fields.add(field);
      } else if (curTok.type == HTLexicon.spreadSyntax) {
        advance(1);
        final value = _parseExpr();
        final field = StructObjField(value: value, isSpread: true);
        if (curTok.type != HTLexicon.bracesRight) {
          match(HTLexicon.comma);
        }
        if (curTok.type == SemanticNames.consumingLineEndComment) {
          final token = advance(1);
          field.consumingLineEndComment = Comment(token.literal);
        }
        fields.add(field);
      } else if (curTok.type == SemanticNames.singleLineComment ||
          curTok.type == SemanticNames.multiLineComment) {
        _handleComment();
      } else {
        final errTok = advance(1);
        final err = HTError.structMemberId(
            filename: _currrentFileName,
            line: errTok.line,
            column: errTok.column,
            offset: errTok.offset,
            length: errTok.length);
        errors.add(err);
      }
    }
    if (fields.isEmpty) {
      final empty = StructObjField(
          source: _currentSource,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.offset - structBlockStartTok.offset);
      empty.precedingComments.addAll(_currentPrecedingComments);
      _currentPrecedingComments.clear();
      fields.add(empty);
    }
    match(HTLexicon.bracesRight);
    return StructObjExpr(fields,
        prototypeId: prototypeId,
        source: _currentSource,
        line: structBlockStartTok.line,
        column: structBlockStartTok.column,
        offset: structBlockStartTok.offset,
        length: curTok.offset - structBlockStartTok.offset);
  }
}
