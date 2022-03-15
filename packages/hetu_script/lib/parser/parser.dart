import 'package:path/path.dart' as path;

import '../resource/resource.dart';
import '../resource/resource_context.dart';
import '../resource/overlay/overlay_context.dart';
import '../lexer/token.dart';
import '../grammar/semantic.dart';
import '../source/source.dart';
import '../declaration/class/class_declaration.dart';
import '../error/error.dart';
import '../ast/ast.dart';
import 'token_reader.dart';
import '../lexer/lexer.dart';
import '../grammar/lexicon.dart';

/// Determines how to parse a piece of code
enum ParseStyle {
  /// Module source can only have declarations (variables, functions, classes, enums),
  /// import & export statement.
  module,

  /// A script can have all statements and expressions, kind of like a funciton body.
  script,

  /// An expression.
  expression,

  /// Like module, but no import & export allowed.
  namespace,

  /// Class can only have declarations (variables, functions).
  classDefinition,

  /// Struct can not have external members
  structDefinition,

  /// Function & block can have declarations (variables, functions),
  /// expression & control statements.
  functionDefinition,
}

abstract class ParserConfig {}

class ParserConfigImpl implements ParserConfig {}

/// Walk through a token list and generates a abstract syntax tree.
class HTParser extends TokenReader {
  static var anonymousFunctionIndex = 0;

  // All import decl in this list must have non-null [fromPath]
  late List<ImportExportDecl> _currentModuleImports;

  String? _currrentFileName;
  @override
  String? get currrentFileName => _currrentFileName;

  final _currentPrecedingComments = <Comment>[];

  HTClassDeclaration? _currentClass;
  FunctionCategory? _currentFunctionCategory;
  String? _currentStructId;

  var _leftValueLegality = false;
  final List<Map<String, String>> _markedSymbolsList = [];

  bool _hasUserDefinedConstructor = false;

  HTSource? _currentSource;

  bool get _isWithinModuleNamespace {
    if (_currentFunctionCategory != null) {
      return false;
    } else if (_currentSource != null) {
      if (_currentSource!.type == HTResourceType.hetuModule) {
        return true;
      }
    }
    return false;
  }

  // final _cachedParseResults = <String, AstSource>{};

  final HTResourceContext<HTSource> sourceContext;

  // final AbstractLexicon lexicon;

  HTParser(
      {HTResourceContext<HTSource>?
          sourceContext}) //, AbstractLexicon? lexicon})
      : sourceContext = sourceContext ?? HTOverlayContext();
  // lexicon = lexicon ?? HTDefaultLexicon();

  /// Will use [style] when possible, then [source.sourceType]
  List<AstNode> parseToken(List<Token> tokens,
      {HTSource? source, ParseStyle? style, ParserConfig? config}) {
    // create new list of errors here, old error list is still usable
    errors = <HTError>[];
    final nodes = <AstNode>[];
    setTokens(tokens);
    _currentSource = source;
    _currrentFileName = source?.fullName;
    late ParseStyle parseStyle;
    if (style != null) {
      parseStyle = style;
    } else {
      if (_currentSource != null) {
        final sourceType = _currentSource!.type;
        if (sourceType == HTResourceType.hetuModule) {
          parseStyle = ParseStyle.module;
        } else if (sourceType == HTResourceType.hetuScript ||
            sourceType == HTResourceType.hetuLiteralCode) {
          parseStyle = ParseStyle.script;
        } else if (sourceType == HTResourceType.hetuValue) {
          parseStyle = ParseStyle.expression;
        } else {
          return nodes;
        }
      } else {
        parseStyle = ParseStyle.script;
      }
    }

    while (curTok.type != Semantic.endOfFile) {
      final stmt = _parseStmt(sourceType: parseStyle);
      if (stmt != null) {
        nodes.add(stmt);
      }
    }
    if (nodes.isEmpty) {
      final empty = EmptyLine(
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

  AstSource parseSource(HTSource source) {
    _currrentFileName = source.fullName;
    _currentClass = null;
    _currentFunctionCategory = null;
    _currentModuleImports = <ImportExportDecl>[];
    final tokens = HTLexer().lex(source.content);
    final nodes = parseToken(tokens, source: source);
    final result = AstSource(
        nodes: nodes,
        source: source,
        imports: _currentModuleImports,
        errors: errors); // copy the list);
    return result;
  }

  /// Parse a string content and generate a library,
  /// will import other files.
  AstCompilation parseToModule(HTSource entry) {
    final result = parseSource(entry);
    final parserErrors = result.errors!;
    final values = <String, AstSource>{};
    final sources = <String, AstSource>{};
    final Set _cachedParsingTargets = <String>{};
    void handleImport(AstSource result) {
      _cachedParsingTargets.add(result.fullName);
      for (final decl in result.imports) {
        if (decl.isPreloadedModule) {
          decl.fullName = decl.fromPath;
          continue;
        }
        try {
          late final AstSource importedSource;
          final currentDir =
              result.fullName.startsWith(InternalIdentifier.anonymousScript)
                  ? sourceContext.root
                  : path.dirname(result.fullName);
          final importFullName = sourceContext.getAbsolutePath(
              key: decl.fromPath!, dirName: currentDir);
          decl.fullName = importFullName;
          if (_cachedParsingTargets.contains(importFullName)) {
            continue;
          }
          // else if (_cachedParseResults.containsKey(importFullName)) {
          //   importedSource = _cachedParseResults[importFullName]!;
          // }
          else {
            final source2 = sourceContext.getResource(importFullName);
            importedSource = parseSource(source2);
            parserErrors.addAll(importedSource.errors!);
            // _cachedParseResults[importFullName] = importedSource;
          }
          if (importedSource.resourceType == HTResourceType.hetuValue) {
            values[importFullName] = importedSource;
          } else {
            handleImport(importedSource);
            sources[importFullName] = importedSource;
          }
        } catch (error) {
          final convertedError = HTError.sourceProviderError(decl.fromPath!,
              filename: entry.fullName,
              line: decl.line,
              column: decl.column,
              offset: decl.offset,
              length: decl.length);
          parserErrors.add(convertedError);
        }
      }
      _cachedParsingTargets.remove(result.fullName);
    }

    if (result.resourceType == HTResourceType.hetuValue) {
      values[result.fullName] = result;
    } else {
      handleImport(result);
      sources[result.fullName] = result;
    }
    final compilation = AstCompilation(
        values: values,
        sources: sources,
        entryResourceType: entry.type,
        errors: parserErrors);
    return compilation;
  }

  bool _handlePrecedingComment() {
    bool handled = false;
    while (curTok is TokenComment) {
      handled = true;
      final comment = Comment.fromToken(curTok as TokenComment);
      _currentPrecedingComments.add(comment);
      advance();
    }
    return handled;
  }

  bool _handleTrailingComment(AstNode expr) {
    if (curTok is TokenComment) {
      final tokenComment = curTok as TokenComment;
      if (tokenComment.isTrailing) {
        advance();
        expr.trailingComment = Comment.fromToken(tokenComment);
      }
      return true;
    }
    return false;
  }

  AstNode? _parseStmt({ParseStyle sourceType = ParseStyle.functionDefinition}) {
    if (_handlePrecedingComment()) {
      return null;
    }

    AstNode stmt;
    final precedingCommentsOfThisStmt =
        List<Comment>.from(_currentPrecedingComments);
    _currentPrecedingComments.clear();
    if (curTok.type == Semantic.emptyLine) {
      final empty = advance();
      stmt = EmptyLine(
          line: empty.line, column: empty.column, offset: empty.offset);
    } else {
      switch (sourceType) {
        case ParseStyle.script:
          if (curTok.lexeme == HTLexicon.kImport) {
            stmt = _parseImportDecl();
          } else if (curTok.lexeme == HTLexicon.kExport) {
            stmt = _parseExportStmt();
          } else if (curTok.lexeme == HTLexicon.kType) {
            stmt = _parseTypeAliasDecl();
          } else {
            switch (curTok.type) {
              case HTLexicon.kNamespace:
                stmt = _parseNamespaceDecl(isTopLevel: true);
                break;
              case HTLexicon.kAssert:
                stmt = _parseAssertStmt();
                break;
              case HTLexicon.kThrow:
                stmt = _parseThrowStmt();
                break;
              case HTLexicon.kExternal:
                advance();
                switch (curTok.type) {
                  case HTLexicon.kAbstract:
                    advance();
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
                    errors?.add(err);
                    final errToken = advance();
                    stmt = EmptyLine(
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
                        Semantic.declStmt, curTok.lexeme,
                        filename: _currrentFileName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors?.add(err);
                    final errToken = advance();
                    stmt = EmptyLine(
                        source: _currentSource,
                        line: errToken.line,
                        column: errToken.column,
                        offset: errToken.offset);
                }
                break;
              case HTLexicon.kAbstract:
                advance();
                stmt = _parseClassDecl(
                    isAbstract: true, isTopLevel: true, lateResolve: false);
                break;
              case HTLexicon.kClass:
                stmt = _parseClassDecl(isTopLevel: true, lateResolve: false);
                break;
              case HTLexicon.kEnum:
                stmt = _parseEnumDecl(isTopLevel: true);
                break;
              case HTLexicon.kVar:
                if (HTLexicon.destructuringDeclarationMark
                    .contains(peek(1).type)) {
                  stmt = _parseDestructuringDecl(isMutable: true);
                } else {
                  stmt = _parseVarDecl(isMutable: true, isTopLevel: true);
                }
                break;
              case HTLexicon.kFinal:
                if (HTLexicon.destructuringDeclarationMark
                    .contains(peek(1).type)) {
                  stmt = _parseDestructuringDecl();
                } else {
                  stmt = _parseVarDecl(isTopLevel: true);
                }
                break;
              case HTLexicon.kLate:
                stmt = _parseVarDecl(lateFinalize: true, isTopLevel: true);
                break;
              case HTLexicon.kConst:
                stmt = _parseVarDecl(isConst: true, isTopLevel: true);
                break;
              case HTLexicon.kFun:
                if (expect([HTLexicon.kFun, Semantic.identifier]) ||
                    expect([
                      HTLexicon.kFun,
                      HTLexicon.externalFunctionTypeDefStart,
                      Semantic.identifier,
                      HTLexicon.externalFunctionTypeDefEnd,
                      Semantic.identifier
                    ])) {
                  stmt = _parseFunction(isTopLevel: true);
                } else {
                  stmt = _parseFunction(
                      category: FunctionCategory.literal, isTopLevel: true);
                }
                break;
              case HTLexicon.kAsync:
                if (expect([HTLexicon.kAsync, Semantic.identifier]) ||
                    expect([
                      HTLexicon.kFun,
                      HTLexicon.externalFunctionTypeDefStart,
                      Semantic.identifier,
                      HTLexicon.externalFunctionTypeDefEnd,
                      Semantic.identifier
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
              case HTLexicon.kDelete:
                stmt = _parseDeleteStmt();
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
        case ParseStyle.module:
          if (curTok.lexeme == HTLexicon.kImport) {
            stmt = _parseImportDecl();
          } else if (curTok.lexeme == HTLexicon.kExport) {
            stmt = _parseExportStmt();
          } else if (curTok.lexeme == HTLexicon.kType) {
            stmt = _parseTypeAliasDecl(isTopLevel: true);
          } else {
            switch (curTok.type) {
              case HTLexicon.kNamespace:
                stmt = _parseNamespaceDecl(isTopLevel: true);
                break;
              case HTLexicon.kExternal:
                advance();
                switch (curTok.type) {
                  case HTLexicon.kAbstract:
                    advance();
                    if (curTok.type != HTLexicon.kClass) {
                      final err = HTError.unexpected(
                          Semantic.classDeclaration, curTok.lexeme,
                          filename: _currrentFileName,
                          line: curTok.line,
                          column: curTok.column,
                          offset: curTok.offset,
                          length: curTok.length);
                      errors?.add(err);
                      final errToken = advance();
                      stmt = EmptyLine(
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
                  case HTLexicon.kLate:
                  case HTLexicon.kConst:
                    final err = HTError.externalVar(
                        filename: _currrentFileName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors?.add(err);
                    final errToken = advance();
                    stmt = EmptyLine(
                        source: _currentSource,
                        line: errToken.line,
                        column: errToken.column,
                        offset: errToken.offset);
                    break;
                  default:
                    final err = HTError.unexpected(
                        Semantic.declStmt, curTok.lexeme,
                        filename: _currrentFileName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors?.add(err);
                    final errToken = advance();
                    stmt = EmptyLine(
                        source: _currentSource,
                        line: errToken.line,
                        column: errToken.column,
                        offset: errToken.offset);
                }
                break;
              case HTLexicon.kAbstract:
                advance();
                stmt = _parseClassDecl(isAbstract: true, isTopLevel: true);
                break;
              case HTLexicon.kClass:
                stmt = _parseClassDecl(isTopLevel: true);
                break;
              case HTLexicon.kEnum:
                stmt = _parseEnumDecl(isTopLevel: true);
                break;
              case HTLexicon.kVar:
                stmt = _parseVarDecl(
                    isMutable: true, isTopLevel: true, lateInitialize: true);
                break;
              case HTLexicon.kFinal:
                stmt = _parseVarDecl(lateInitialize: true, isTopLevel: true);
                break;
              case HTLexicon.kLate:
                stmt = _parseVarDecl(lateFinalize: true, isTopLevel: true);
                break;
              case HTLexicon.kConst:
                stmt = _parseVarDecl(isConst: true, isTopLevel: true);
                break;
              case HTLexicon.kFun:
                stmt = _parseFunction(isTopLevel: true);
                break;
              case HTLexicon.kStruct:
                stmt = _parseStructDecl(isTopLevel: true);
                break;
              default:
                final err = HTError.unexpected(Semantic.declStmt, curTok.lexeme,
                    filename: _currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance();
                stmt = EmptyLine(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
            }
          }
          break;
        case ParseStyle.namespace:
          if (curTok.lexeme == HTLexicon.kType) {
            stmt = _parseTypeAliasDecl();
          } else {
            switch (curTok.type) {
              case HTLexicon.kNamespace:
                stmt = _parseNamespaceDecl();
                break;
              case HTLexicon.kAssert:
                stmt = _parseAssertStmt();
                break;
              case HTLexicon.kThrow:
                stmt = _parseThrowStmt();
                break;
              case HTLexicon.kExternal:
                advance();
                switch (curTok.type) {
                  case HTLexicon.kAbstract:
                    advance();
                    if (curTok.type != HTLexicon.kClass) {
                      final err = HTError.unexpected(
                          Semantic.classDeclaration, curTok.lexeme,
                          filename: _currrentFileName,
                          line: curTok.line,
                          column: curTok.column,
                          offset: curTok.offset,
                          length: curTok.length);
                      errors?.add(err);
                      final errToken = advance();
                      stmt = EmptyLine(
                          source: _currentSource,
                          line: errToken.line,
                          column: errToken.column,
                          offset: errToken.offset);
                    } else {
                      stmt =
                          _parseClassDecl(isAbstract: true, isExternal: true);
                    }
                    break;
                  case HTLexicon.kClass:
                    stmt = _parseClassDecl(isExternal: true);
                    break;
                  case HTLexicon.kEnum:
                    stmt = _parseEnumDecl(isExternal: true);
                    break;
                  case HTLexicon.kFun:
                    stmt = _parseFunction(isExternal: true);
                    break;
                  case HTLexicon.kVar:
                  case HTLexicon.kFinal:
                  case HTLexicon.kLate:
                  case HTLexicon.kConst:
                    final err = HTError.externalVar(
                        filename: _currrentFileName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors?.add(err);
                    final errToken = advance();
                    stmt = EmptyLine(
                        source: _currentSource,
                        line: errToken.line,
                        column: errToken.column,
                        offset: errToken.offset);
                    break;
                  default:
                    final err = HTError.unexpected(
                        Semantic.declStmt, curTok.lexeme,
                        filename: _currrentFileName,
                        line: curTok.line,
                        column: curTok.column,
                        offset: curTok.offset,
                        length: curTok.length);
                    errors?.add(err);
                    final errToken = advance();
                    stmt = EmptyLine(
                        source: _currentSource,
                        line: errToken.line,
                        column: errToken.column,
                        offset: errToken.offset);
                }
                break;
              case HTLexicon.kAbstract:
                advance();
                stmt = _parseClassDecl(
                    isAbstract: true, lateResolve: _isWithinModuleNamespace);
                break;
              case HTLexicon.kClass:
                stmt = _parseClassDecl(lateResolve: _isWithinModuleNamespace);
                break;
              case HTLexicon.kEnum:
                stmt = _parseEnumDecl();
                break;
              case HTLexicon.kVar:
                stmt = _parseVarDecl(
                    isMutable: true, lateInitialize: _isWithinModuleNamespace);
                break;
              case HTLexicon.kFinal:
                stmt = _parseVarDecl(lateInitialize: _isWithinModuleNamespace);
                break;
              case HTLexicon.kConst:
                stmt = _parseVarDecl(isConst: true);
                break;
              case HTLexicon.kFun:
                stmt = _parseFunction();
                break;
              case HTLexicon.kStruct:
                stmt = _parseStructDecl();
                break;
              default:
                final err = HTError.unexpected(Semantic.declStmt, curTok.lexeme,
                    filename: _currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance();
                stmt = EmptyLine(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
            }
          }
          break;
        case ParseStyle.classDefinition:
          final isOverrided = expect([HTLexicon.kOverride], consume: true);
          final isExternal = expect([HTLexicon.kExternal], consume: true) ||
              (_currentClass?.isExternal ?? false);
          final isStatic = expect([HTLexicon.kStatic], consume: true);
          if (curTok.lexeme == HTLexicon.kType) {
            if (isExternal) {
              final err = HTError.external(Semantic.typeAliasDeclaration,
                  filename: _currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = EmptyLine(
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
              case HTLexicon.kLate:
                stmt = _parseVarDecl(
                    classId: _currentClass?.id,
                    isOverrided: isOverrided,
                    isExternal: isExternal,
                    isStatic: isStatic,
                    lateFinalize: true);
                break;
              case HTLexicon.kConst:
                if (isStatic) {
                  stmt =
                      _parseVarDecl(isConst: true, classId: _currentClass?.id);
                } else {
                  final err = HTError.external(Semantic.typeAliasDeclaration,
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors?.add(err);
                  final errToken = advance();
                  stmt = EmptyLine(
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
                  final err = HTError.external(Semantic.asyncFunction,
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors?.add(err);
                  final errToken = advance();
                  stmt = EmptyLine(
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
                      Semantic.declStmt, HTLexicon.kConstruct,
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors?.add(err);
                  final errToken = advance();
                  stmt = EmptyLine(
                      source: _currentSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
                } else if (isExternal && !_currentClass!.isExternal) {
                  final err = HTError.external(Semantic.ctorFunction,
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors?.add(err);
                  final errToken = advance();
                  stmt = EmptyLine(
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
                      Semantic.declStmt, HTLexicon.kConstruct,
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors?.add(err);
                  final errToken = advance();
                  stmt = EmptyLine(
                      source: _currentSource,
                      line: errToken.line,
                      column: errToken.column,
                      offset: errToken.offset);
                } else if (isExternal && !_currentClass!.isExternal) {
                  final err = HTError.external(Semantic.factory,
                      filename: _currrentFileName,
                      line: curTok.line,
                      column: curTok.column,
                      offset: curTok.offset,
                      length: curTok.length);
                  errors?.add(err);
                  final errToken = advance();
                  stmt = EmptyLine(
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
                final err = HTError.unexpected(Semantic.declStmt, curTok.lexeme,
                    filename: _currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance();
                stmt = EmptyLine(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
            }
          }
          break;
        case ParseStyle.structDefinition:
          final isExternal = expect([HTLexicon.kExternal], consume: true);
          final isStatic = expect([HTLexicon.kStatic], consume: true);
          switch (curTok.type) {
            case HTLexicon.kVar:
              stmt = _parseVarDecl(
                  classId: _currentStructId,
                  isField: true,
                  isExternal: isExternal,
                  isMutable: true,
                  isStatic: isStatic,
                  lateInitialize: true);
              break;
            case HTLexicon.kFinal:
              stmt = _parseVarDecl(
                  classId: _currentStructId,
                  isField: true,
                  isExternal: isExternal,
                  isStatic: isStatic,
                  lateInitialize: true);
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
                final err = HTError.external(Semantic.asyncFunction,
                    filename: _currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance();
                stmt = EmptyLine(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              } else {
                stmt = _parseFunction(
                    category: FunctionCategory.method,
                    classId: _currentStructId,
                    isAsync: true,
                    isField: true,
                    isExternal: isExternal,
                    isStatic: isStatic);
              }
              break;
            case HTLexicon.kGet:
              stmt = _parseFunction(
                  category: FunctionCategory.getter,
                  classId: _currentStructId,
                  isField: true,
                  isExternal: isExternal,
                  isStatic: isStatic);
              break;
            case HTLexicon.kSet:
              stmt = _parseFunction(
                  category: FunctionCategory.setter,
                  classId: _currentStructId,
                  isField: true,
                  isExternal: isExternal,
                  isStatic: isStatic);
              break;
            case HTLexicon.kConstruct:
              if (isStatic) {
                final err = HTError.unexpected(
                    Semantic.declStmt, HTLexicon.kConstruct,
                    filename: _currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance();
                stmt = EmptyLine(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              } else if (isExternal) {
                final err = HTError.external(Semantic.ctorFunction,
                    filename: _currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance();
                stmt = EmptyLine(
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
              final err = HTError.unexpected(Semantic.declStmt, curTok.lexeme,
                  filename: _currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = EmptyLine(
                  source: _currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
          }
          break;
        case ParseStyle.functionDefinition:
          switch (curTok.type) {
            case HTLexicon.kNamespace:
              stmt = _parseNamespaceDecl();
              break;
            case HTLexicon.kAssert:
              stmt = _parseAssertStmt();
              break;
            case HTLexicon.kThrow:
              stmt = _parseThrowStmt();
              break;
            case HTLexicon.kAbstract:
              advance();
              stmt = _parseClassDecl(isAbstract: true, lateResolve: false);
              break;
            case HTLexicon.kClass:
              stmt = _parseClassDecl(lateResolve: false);
              break;
            case HTLexicon.kEnum:
              stmt = _parseEnumDecl();
              break;
            case HTLexicon.kVar:
              if (HTLexicon.destructuringDeclarationMark
                  .contains(peek(1).type)) {
                stmt = _parseDestructuringDecl(isMutable: true);
              } else {
                stmt = _parseVarDecl(isMutable: true);
              }
              break;
            case HTLexicon.kFinal:
              if (HTLexicon.destructuringDeclarationMark
                  .contains(peek(1).type)) {
                stmt = _parseDestructuringDecl();
              } else {
                stmt = _parseVarDecl();
              }
              break;
            case HTLexicon.kLate:
              stmt = _parseVarDecl(lateFinalize: true);
              break;
            case HTLexicon.kConst:
              stmt = _parseVarDecl(isConst: true);
              break;
            case HTLexicon.kFun:
              if (expect([HTLexicon.kFun, Semantic.identifier]) ||
                  expect([
                    HTLexicon.kFun,
                    HTLexicon.externalFunctionTypeDefStart,
                    Semantic.identifier,
                    HTLexicon.externalFunctionTypeDefEnd,
                    Semantic.identifier
                  ])) {
                stmt = _parseFunction();
              } else {
                stmt = _parseFunction(category: FunctionCategory.literal);
              }
              break;
            case HTLexicon.kAsync:
              if (expect([HTLexicon.kAsync, Semantic.identifier]) ||
                  expect([
                    HTLexicon.kFun,
                    HTLexicon.externalFunctionTypeDefStart,
                    Semantic.identifier,
                    HTLexicon.externalFunctionTypeDefEnd,
                    Semantic.identifier
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
            case HTLexicon.kDelete:
              stmt = _parseDeleteStmt();
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
              final keyword = advance();
              final hasEndOfStmtMark =
                  expect([HTLexicon.endOfStatementMark], consume: true);
              stmt = BreakStmt(keyword,
                  hasEndOfStmtMark: hasEndOfStmtMark,
                  source: _currentSource,
                  line: keyword.line,
                  column: keyword.column,
                  offset: keyword.offset,
                  length: keyword.length);
              break;
            case HTLexicon.kContinue:
              final keyword = advance();
              final hasEndOfStmtMark =
                  expect([HTLexicon.endOfStatementMark], consume: true);
              stmt = ContinueStmt(keyword,
                  hasEndOfStmtMark: hasEndOfStmtMark,
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
                errors?.add(err);
                final errToken = advance();
                stmt = EmptyLine(
                    source: _currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              }
              break;
            default:
              stmt = _parseExprStmt();
          }
          break;
        case ParseStyle.expression:
          stmt = _parseExpr();
      }
    }

    if (stmt.isStatement) {
      stmt.precedingComments.addAll(precedingCommentsOfThisStmt);
      _currentPrecedingComments.clear();
    }

    if (curTok is TokenComment) {
      final token = advance();
      stmt.trailingComment = Comment.fromToken(token as TokenComment);
    }

    return stmt;
  }

  AssertStmt _parseAssertStmt() {
    final keyword = match(HTLexicon.kAssert);
    match(HTLexicon.groupExprStart);
    final expr = _parseExpr();
    match(HTLexicon.groupExprEnd);
    final hasEndOfStmtMark =
        expect([HTLexicon.endOfStatementMark], consume: true);
    final stmt = AssertStmt(expr,
        hasEndOfStmtMark: hasEndOfStmtMark,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: expr.end - keyword.offset);
    return stmt;
  }

  ThrowStmt _parseThrowStmt() {
    final keyword = match(HTLexicon.kThrow);
    final message = _parseExpr();
    final hasEndOfStmtMark =
        expect([HTLexicon.endOfStatementMark], consume: true);
    final stmt = ThrowStmt(message,
        hasEndOfStmtMark: hasEndOfStmtMark,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: message.end - keyword.offset);
    return stmt;
  }

  /// Recursive descent parsing
  ///
  /// Assignment operator =, precedence 1, associativity right
  AstNode _parseExpr() {
    _handlePrecedingComment();
    AstNode? expr;
    final left = _parserTernaryExpr();
    if (HTLexicon.assignments.contains(curTok.type)) {
      final op = advance();
      final right = _parseExpr();
      expr = AssignExpr(left, op.lexeme, right,
          source: _currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    } else {
      expr = left;
    }

    expr.precedingComments.addAll(_currentPrecedingComments);
    _currentPrecedingComments.clear();

    return expr;
  }

  /// Ternery operator: e1 ? e2 : e3, precedence 3, associativity right
  AstNode _parserTernaryExpr() {
    var condition = _parseIfNullExpr();
    if (expect([HTLexicon.ternaryThen], consume: true)) {
      _leftValueLegality = false;
      final thenBranch = _parserTernaryExpr();
      match(HTLexicon.ternaryElse);
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
        final op = advance();
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

  /// Logical or: ||, precedence 5, associativity left
  AstNode _parseLogicalOrExpr() {
    var left = _parseLogicalAndExpr();
    if (curTok.type == HTLexicon.logicalOr) {
      _leftValueLegality = false;
      while (curTok.type == HTLexicon.logicalOr) {
        final op = advance();
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

  /// Logical and: &&, precedence 6, associativity left
  AstNode _parseLogicalAndExpr() {
    var left = _parseEqualityExpr();
    if (curTok.type == HTLexicon.logicalAnd) {
      _leftValueLegality = false;
      while (curTok.type == HTLexicon.logicalAnd) {
        final op = advance();
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

  /// Logical equal: ==, !=, precedence 7, associativity none
  AstNode _parseEqualityExpr() {
    var left = _parseRelationalExpr();
    if (HTLexicon.equalitys.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance();
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

  /// Logical compare: <, >, <=, >=, as, is, is!, in, in!, precedence 8, associativity none
  AstNode _parseRelationalExpr() {
    var left = _parseAdditiveExpr();
    if (HTLexicon.logicalRelationals.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance();
      final right = _parseAdditiveExpr();
      left = BinaryExpr(left, op.lexeme, right,
          source: _currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    } else if (HTLexicon.setRelationals.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance();
      late final String opLexeme;
      if (op.lexeme == HTLexicon.kIn) {
        opLexeme = expect([HTLexicon.logicalNot], consume: true)
            ? HTLexicon.kNotIn
            : HTLexicon.kIn;
      } else {
        opLexeme = op.lexeme;
      }
      final right = _parseAdditiveExpr();
      left = BinaryExpr(left, opLexeme, right,
          source: _currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    } else if (HTLexicon.typeRelationals.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance();
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

  /// Add: +, -, precedence 13, associativity left
  AstNode _parseAdditiveExpr() {
    var left = _parseMultiplicativeExpr();
    if (HTLexicon.additives.contains(curTok.type)) {
      _leftValueLegality = false;
      while (HTLexicon.additives.contains(curTok.type)) {
        final op = advance();
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

  /// Multiply *, /, ~/, %, precedence 14, associativity left
  AstNode _parseMultiplicativeExpr() {
    var left = _parseUnaryPrefixExpr();
    if (HTLexicon.multiplicatives.contains(curTok.type)) {
      _leftValueLegality = false;
      while (HTLexicon.multiplicatives.contains(curTok.type)) {
        final op = advance();
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

  /// Prefix -e, !e，++e, --e, precedence 15, associativity none
  AstNode _parseUnaryPrefixExpr() {
    if (!(HTLexicon.unaryPrefixs.contains(curTok.type))) {
      return _parseUnaryPostfixExpr();
    } else {
      final op = advance();
      final value = _parseUnaryPostfixExpr();
      if (op.type != HTLexicon.logicalNot && op.type != HTLexicon.negative) {
        if (!_leftValueLegality) {
          final err = HTError.invalidLeftValue(
              filename: _currrentFileName,
              line: value.line,
              column: value.column,
              offset: value.offset,
              length: value.length);
          errors?.add(err);
        }
      }
      return UnaryPrefixExpr(op.lexeme, value,
          source: _currentSource,
          line: op.line,
          column: op.column,
          offset: op.offset,
          length: curTok.offset - op.offset);
    }
  }

  /// Postfix e., e?., e[], e?[], e(), e?(), e++, e-- precedence 16, associativity right
  AstNode _parseUnaryPostfixExpr() {
    var expr = _parsePrimaryExpr();
    while (HTLexicon.unaryPostfixs.contains(curTok.type)) {
      final op = advance();
      switch (op.type) {
        case HTLexicon.memberGet:
          var isNullable = false;
          if ((expr is MemberExpr && expr.isNullable) ||
              (expr is SubExpr && expr.isNullable) ||
              (expr is CallExpr && expr.isNullable)) {
            isNullable = true;
          }
          _leftValueLegality = true;
          final name = match(Semantic.identifier);
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
        case HTLexicon.nullableMemberGet:
          _leftValueLegality = false;
          final name = match(Semantic.identifier);
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
        case HTLexicon.subGetStart:
          var isNullable = false;
          if ((expr is MemberExpr && expr.isNullable) ||
              (expr is SubExpr && expr.isNullable) ||
              (expr is CallExpr && expr.isNullable)) {
            isNullable = true;
          }
          var indexExpr = _parseExpr();
          _leftValueLegality = true;
          match(HTLexicon.listEnd);
          expr = SubExpr(expr, indexExpr,
              isNullable: isNullable,
              source: _currentSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case HTLexicon.nullableSubGet:
          var indexExpr = _parseExpr();
          _leftValueLegality = true;
          match(HTLexicon.listEnd);
          expr = SubExpr(expr, indexExpr,
              isNullable: true,
              source: _currentSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case HTLexicon.nullableFunctionCallArgumentStart:
          _leftValueLegality = false;
          var positionalArgs = <AstNode>[];
          var namedArgs = <String, AstNode>{};
          _handleCallArguments(positionalArgs, namedArgs);
          expr = CallExpr(expr,
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              isNullable: true,
              source: _currentSource,
              line: expr.line,
              column: expr.column,
              offset: expr.offset,
              length: curTok.offset - expr.offset);
          break;
        case HTLexicon.functionCallArgumentStart:
          var isNullable = false;
          if ((expr is MemberExpr && expr.isNullable) ||
              (expr is SubExpr && expr.isNullable) ||
              (expr is CallExpr && expr.isNullable)) {
            isNullable = true;
          }
          _leftValueLegality = false;
          var positionalArgs = <AstNode>[];
          var namedArgs = <String, AstNode>{};
          _handleCallArguments(positionalArgs, namedArgs);
          expr = CallExpr(expr,
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              isNullable: isNullable,
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

  /// Expression without associativity
  AstNode _parsePrimaryExpr() {
    switch (curTok.type) {
      case HTLexicon.kNull:
        final token = advance();
        _leftValueLegality = false;
        return NullExpr(
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case Semantic.booleanLiteral:
        final token = match(Semantic.booleanLiteral) as TokenBooleanLiteral;
        _leftValueLegality = false;
        return BooleanLiteralExpr(token.literal,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case Semantic.integerLiteral:
        final token = match(Semantic.integerLiteral) as TokenIntLiteral;
        _leftValueLegality = false;
        return IntegerLiteralExpr(token.literal,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case Semantic.floatLiteral:
        final token = advance() as TokenFloatLiteral;
        _leftValueLegality = false;
        return FloatLiteralExpr(token.literal,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case Semantic.stringLiteral:
        final token = advance() as TokenStringLiteral;
        _leftValueLegality = false;
        return StringLiteralExpr(
            token.literal, token.quotationLeft, token.quotationRight,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case Semantic.stringInterpolation:
        final token = advance() as TokenStringInterpolation;
        final interpolations = <AstNode>[];
        for (final tokens in token.interpolations) {
          final exprParser = HTParser(sourceContext: sourceContext);
          final nodes = exprParser.parseToken(tokens,
              source: _currentSource, style: ParseStyle.expression);
          errors?.addAll(exprParser.errors!);

          AstNode? expr;
          for (final node in nodes) {
            if (node is! EmptyLine) {
              if (expr == null) {
                expr = node;
              } else {
                final err = HTError.stringInterpolation(
                    filename: _currrentFileName,
                    line: node.line,
                    column: node.column,
                    offset: node.offset,
                    length: node.length);
                errors?.add(err);
                break;
              }
            }
          }
          if (expr != null) {
            interpolations.add(expr);
          } else {
            // parser will always contain at least a empty line expr
            interpolations.add(nodes.first);
          }
        }
        var i = 0;
        final text = token.literal.replaceAllMapped(
            RegExp(HTLexicon.stringInterpolationPattern),
            (Match m) =>
                '${HTLexicon.functionBlockStart}${i++}${HTLexicon.functionBlockEnd}');
        _leftValueLegality = false;
        return StringInterpolationExpr(
            text, token.quotationLeft, token.quotationRight, interpolations,
            source: _currentSource,
            line: token.line,
            column: token.column,
            offset: token.offset,
            length: token.length);
      case HTLexicon.kThis:
        final keyword = advance();
        _leftValueLegality = false;
        return IdentifierExpr(keyword.lexeme,
            source: _currentSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length,
            isKeyword: true);
      case HTLexicon.kSuper:
        final keyword = advance();
        _leftValueLegality = false;
        return IdentifierExpr(keyword.lexeme,
            source: _currentSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length,
            isKeyword: true);
      case HTLexicon.kNew:
        final keyword = advance();
        _leftValueLegality = false;
        final idTok = match(Semantic.identifier);
        final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
        var positionalArgs = <AstNode>[];
        var namedArgs = <String, AstNode>{};
        if (expect([HTLexicon.functionCallArgumentStart], consume: true)) {
          _handleCallArguments(positionalArgs, namedArgs);
        }
        return CallExpr(id,
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            hasNewOperator: true,
            source: _currentSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: curTok.offset - keyword.offset);
      case HTLexicon.kIf:
        _leftValueLegality = false;
        return _parseIf(isExpression: true);
      case HTLexicon.kWhen:
        _leftValueLegality = false;
        return _parseWhen(isExpression: true);
      case HTLexicon.groupExprStart:
        // a literal function expression
        final token = seekGroupClosing();
        if (token.type == HTLexicon.functionBlockStart ||
            token.type == HTLexicon.functionSingleLineBodyIndicator) {
          _leftValueLegality = false;
          return _parseFunction(
              category: FunctionCategory.literal, hasKeyword: false);
        }
        // a group expression
        else {
          final start = advance();
          final innerExpr = _parseExpr();
          final end = match(HTLexicon.groupExprEnd);
          _leftValueLegality = false;
          return GroupExpr(innerExpr,
              source: _currentSource,
              line: start.line,
              column: start.column,
              offset: start.offset,
              length: end.offset + end.length - start.offset);
        }
      case HTLexicon.listStart:
        final start = advance();
        final listExpr = <AstNode>[];
        while (curTok.type != HTLexicon.listEnd &&
            curTok.type != Semantic.endOfFile) {
          AstNode item;
          if (curTok.type == HTLexicon.spreadSyntax) {
            final spreadTok = advance();
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
          if (curTok.type != HTLexicon.listEnd) {
            match(HTLexicon.comma);
          }
          _handleTrailingComment(item);
        }
        final end = match(HTLexicon.listEnd);
        _leftValueLegality = false;
        return ListExpr(listExpr,
            source: _currentSource,
            line: start.line,
            column: start.column,
            offset: start.offset,
            length: end.end - start.offset);
      case HTLexicon.functionBlockStart:
        _leftValueLegality = false;
        return _parseStructObj();
      case HTLexicon.kStruct:
        _leftValueLegality = false;
        return _parseStructObj(hasKeyword: true);
      case HTLexicon.kFun:
        _leftValueLegality = false;
        return _parseFunction(category: FunctionCategory.literal);
      case Semantic.identifier:
        final id = advance();
        final isLocal = curTok.type != HTLexicon.assign;
        // TODO: type arguments
        _leftValueLegality = true;
        return IdentifierExpr.fromToken(id,
            isLocal: isLocal, source: _currentSource);
      default:
        final err = HTError.unexpected(Semantic.expression, curTok.lexeme,
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
        final errToken = advance();
        return EmptyLine(
            source: _currentSource,
            line: errToken.line,
            column: errToken.column,
            offset: errToken.offset);
    }
  }

  CommaExpr _handleCommaExpr(String endMark, {bool isLocal = true}) {
    final list = <AstNode>[];
    while (curTok.type != endMark && curTok.type != Semantic.endOfFile) {
      if (list.isNotEmpty) {
        match(HTLexicon.comma);
      }
      final item = _parseExpr();
      _handleTrailingComment(item);
      list.add(item);
    }
    return CommaExpr(list,
        isLocal: isLocal,
        source: _currentSource,
        line: list.first.line,
        column: list.first.column,
        offset: list.first.offset,
        length: curTok.offset - list.first.offset);
  }

  InOfExpr _handleInOfExpr() {
    final opTok = advance();
    final collection = _parseExpr();
    return InOfExpr(collection, opTok.lexeme == HTLexicon.kOf ? true : false,
        line: collection.line,
        column: collection.column,
        offset: collection.offset,
        length: curTok.offset - collection.offset);
  }

  TypeExpr _parseTypeExpr({bool isLocal = false}) {
    // function type
    if (curTok.type == HTLexicon.groupExprStart) {
      final startTok = advance();
      // TODO: generic parameters
      final parameters = <ParamTypeExpr>[];
      var isOptional = false;
      var isNamed = false;
      var isVariadic = false;
      while (curTok.type != HTLexicon.groupExprEnd &&
          curTok.type != Semantic.endOfFile) {
        final start = curTok;
        if (!isOptional) {
          isOptional = expect([HTLexicon.listStart], consume: true);
          if (!isOptional && !isNamed) {
            isNamed = expect([HTLexicon.functionBlockStart], consume: true);
          }
        }
        late final TypeExpr paramType;
        IdentifierExpr? paramSymbol;
        if (!isNamed) {
          isVariadic = expect([HTLexicon.variadicArgs], consume: true);
        } else {
          final paramId = match(Semantic.identifier);
          paramSymbol =
              IdentifierExpr.fromToken(paramId, source: _currentSource);
          match(HTLexicon.typeIndicator);
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
        if (isOptional && expect([HTLexicon.listEnd], consume: true)) {
          break;
        } else if (isNamed &&
            expect([HTLexicon.functionBlockEnd], consume: true)) {
          break;
        } else if (curTok.type != HTLexicon.groupExprEnd) {
          match(HTLexicon.comma);
        }
        _handleTrailingComment(param);
        parameters.add(param);
        if (isVariadic) {
          break;
        }
      }
      match(HTLexicon.groupExprEnd);
      match(HTLexicon.functionReturnTypeIndicator);
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
    // structural type (interface of struct)
    else if (curTok.type == HTLexicon.functionBlockStart) {
      final startTok = advance();
      final fieldTypes = <FieldTypeExpr>[];
      while (curTok.type != HTLexicon.functionBlockEnd &&
          curTok.type != Semantic.endOfFile) {
        _handlePrecedingComment();
        late Token idTok;
        if (curTok.type == Semantic.stringLiteral) {
          idTok = advance();
        } else {
          idTok = match(Semantic.identifier);
        }
        match(HTLexicon.typeIndicator);
        final typeExpr = _parseTypeExpr();
        fieldTypes.add(FieldTypeExpr(idTok.literal, typeExpr));
        expect([HTLexicon.comma], consume: true);
      }
      match(HTLexicon.functionBlockEnd);
      return StructuralTypeExpr(
        fieldTypes: fieldTypes,
        isLocal: isLocal,
        source: _currentSource,
        line: startTok.line,
        column: startTok.column,
        length: curTok.offset - startTok.offset,
      );
    }
    // nominal type (class)
    else {
      final idTok = match(Semantic.identifier);
      final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
      final typeArgs = <TypeExpr>[];
      if (expect([HTLexicon.typeParameterStart], consume: true)) {
        if (curTok.type == HTLexicon.typeParameterEnd) {
          final err = HTError.emptyTypeArgs(
              filename: _currrentFileName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.end - idTok.offset);
          errors?.add(err);
        }
        while ((curTok.type != HTLexicon.typeParameterEnd) &&
            (curTok.type != Semantic.endOfFile)) {
          final typeArg = _parseTypeExpr();
          expect([HTLexicon.comma], consume: true);
          _handleTrailingComment(typeArg);
          typeArgs.add(typeArg);
        }
        match(HTLexicon.typeParameterEnd);
      }
      final isNullable = expect([HTLexicon.nullableTypePostfix], consume: true);
      return TypeExpr(
        id: id,
        arguments: typeArgs,
        isNullable: isNullable,
        isLocal: isLocal,
        source: _currentSource,
        line: idTok.line,
        column: idTok.column,
        offset: idTok.offset,
        length: curTok.offset - idTok.offset,
      );
    }
  }

  BlockStmt _parseBlockStmt(
      {String? id,
      ParseStyle sourceType = ParseStyle.functionDefinition,
      bool hasOwnNamespace = true}) {
    final startTok = match(HTLexicon.functionBlockStart);
    final statements = <AstNode>[];
    while (curTok.type != HTLexicon.functionBlockEnd &&
        curTok.type != Semantic.endOfFile) {
      final stmt = _parseStmt(sourceType: sourceType);
      if (stmt != null) {
        statements.add(stmt);
      }
    }
    final endTok = match(HTLexicon.functionBlockEnd);
    if (statements.isEmpty) {
      final empty = EmptyLine(
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
    while ((curTok.type != HTLexicon.groupExprEnd) &&
        (curTok.type != Semantic.endOfFile)) {
      if ((!isNamed &&
              expect(
                  [Semantic.identifier, HTLexicon.namedArgumentValueIndicator],
                  consume: false)) ||
          isNamed) {
        isNamed = true;
        final name = match(Semantic.identifier).lexeme;
        match(HTLexicon.namedArgumentValueIndicator);
        final namedArg = _parseExpr();
        if (curTok.type != HTLexicon.groupExprEnd) {
          match(HTLexicon.comma);
        }
        _handleTrailingComment(namedArg);
        namedArgs[name] = namedArg;
      } else {
        late AstNode positionalArg;
        if (curTok.type == HTLexicon.spreadSyntax) {
          final spreadTok = advance();
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
        if (curTok.type != HTLexicon.groupExprEnd) {
          match(HTLexicon.comma);
        }
        _handleTrailingComment(positionalArg);
        positionalArgs.add(positionalArg);
      }
    }
    match(HTLexicon.functionCallArgumentEnd);
  }

  AstNode _parseExprStmt() {
    if (curTok.type == HTLexicon.endOfStatementMark) {
      final empty = advance();
      final stmt = EmptyLine(
          hasEndOfStmtMark: true,
          source: _currentSource,
          line: empty.line,
          column: empty.column,
          offset: empty.offset,
          length: curTok.offset - empty.offset);
      return stmt;
    } else {
      final expr = _parseExpr();
      final hasEndOfStmtMark =
          expect([HTLexicon.endOfStatementMark], consume: true);
      final stmt = ExprStmt(expr,
          hasEndOfStmtMark: hasEndOfStmtMark,
          source: _currentSource,
          line: expr.line,
          column: expr.column,
          offset: expr.offset,
          length: curTok.offset - expr.offset);
      return stmt;
    }
  }

  ReturnStmt _parseReturnStmt() {
    var keyword = advance();
    AstNode? expr;
    if (curTok.type != HTLexicon.functionBlockEnd &&
        curTok.type != HTLexicon.endOfStatementMark &&
        curTok.type != Semantic.endOfFile) {
      expr = _parseExpr();
    }
    final hasEndOfStmtMark =
        expect([HTLexicon.endOfStatementMark], consume: true);
    return ReturnStmt(keyword,
        returnValue: expr,
        source: _currentSource,
        hasEndOfStmtMark: hasEndOfStmtMark,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  AstNode _parseExprOrStmtOrBlock({bool isExpression = false}) {
    if (curTok.type == HTLexicon.functionBlockStart) {
      return _parseBlockStmt(id: Semantic.elseBranch);
    } else {
      if (isExpression) {
        return _parseExpr();
      } else {
        final startTok = curTok;
        var node = _parseStmt();
        if (node == null) {
          final err = HTError.unexpected(Semantic.expression, curTok.lexeme,
              filename: _currrentFileName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.length);
          errors?.add(err);
          node = EmptyLine(
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
    match(HTLexicon.groupExprStart);
    final condition = _parseExpr();
    match(HTLexicon.groupExprEnd);
    var thenBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
    _handlePrecedingComment();
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
    match(HTLexicon.groupExprStart);
    final condition = _parseExpr();
    match(HTLexicon.groupExprEnd);
    final loop = _parseBlockStmt(id: Semantic.whileLoop);
    return WhileStmt(condition, loop,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  DoStmt _parseDoStmt() {
    final keyword = advance();
    final loop = _parseBlockStmt(id: Semantic.doLoop);
    AstNode? condition;
    if (expect([HTLexicon.kWhile], consume: true)) {
      match(HTLexicon.groupExprStart);
      condition = _parseExpr();
      match(HTLexicon.groupExprEnd);
    }
    final hasEndOfStmtMark =
        expect([HTLexicon.endOfStatementMark], consume: true);
    return DoStmt(loop, condition,
        hasEndOfStmtMark: hasEndOfStmtMark,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  AstNode _parseForStmt() {
    final keyword = advance();
    final hasBracket = expect([HTLexicon.groupExprStart], consume: true);
    final forStmtType = peek(2).lexeme;
    VarDecl? decl;
    AstNode? condition;
    AstNode? increment;
    final newSymbolMap = <String, String>{};
    _markedSymbolsList.add(newSymbolMap);
    if (forStmtType == HTLexicon.kIn || forStmtType == HTLexicon.kOf) {
      if (!HTLexicon.forDeclarationKeywords.contains(curTok.type)) {
        final err = HTError.unexpected(
            Semantic.variableDeclaration, curTok.type,
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
      }
      decl = _parseVarDecl(
          // typeInferrence: curTok.type != HTLexicon.VAR,
          isMutable: curTok.type != HTLexicon.kFinal);
      advance();
      final collection = _parseExpr();
      if (hasBracket) {
        match(HTLexicon.groupExprEnd);
      }
      final loop = _parseBlockStmt(id: Semantic.forLoop);
      return ForRangeStmt(decl, collection, loop,
          hasBracket: hasBracket,
          iterateValue: forStmtType == HTLexicon.kOf,
          source: _currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    } else {
      if (!expect([HTLexicon.endOfStatementMark], consume: false)) {
        decl = _parseVarDecl(
            // typeInferrence: curTok.type != HTLexicon.VAR,
            isMutable: curTok.type != HTLexicon.kFinal,
            hasEndOfStatement: true);
      } else {
        match(HTLexicon.endOfStatementMark);
      }
      if (!expect([HTLexicon.endOfStatementMark], consume: false)) {
        condition = _parseExpr();
      }
      match(HTLexicon.endOfStatementMark);
      if (!expect([HTLexicon.groupExprEnd], consume: false)) {
        increment = _parseExpr();
      }
      if (hasBracket) {
        match(HTLexicon.groupExprEnd);
      }
      final loop = _parseBlockStmt(id: Semantic.forLoop);
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
    final keyword = advance();
    AstNode? condition;
    if (curTok.type != HTLexicon.functionBlockStart) {
      match(HTLexicon.groupExprStart);
      condition = _parseExpr();
      match(HTLexicon.groupExprEnd);
    }
    final options = <AstNode, AstNode>{};
    AstNode? elseBranch;
    match(HTLexicon.functionBlockStart);
    while (curTok.type != HTLexicon.functionBlockEnd &&
        curTok.type != Semantic.endOfFile) {
      _handlePrecedingComment();
      if (curTok.lexeme == HTLexicon.kElse) {
        advance();
        match(HTLexicon.whenBranchIndicator);
        elseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
      } else {
        AstNode caseExpr;
        if (condition != null) {
          if (peek(1).type == HTLexicon.comma) {
            caseExpr =
                _handleCommaExpr(HTLexicon.whenBranchIndicator, isLocal: false);
          } else if (curTok.type == HTLexicon.kIn) {
            caseExpr = _handleInOfExpr();
          } else {
            caseExpr = _parseExpr();
          }
        } else {
          caseExpr = _parseExpr();
        }
        match(HTLexicon.whenBranchIndicator);
        var caseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
        options[caseExpr] = caseBranch;
      }
    }
    match(HTLexicon.functionBlockEnd);
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
    if (expect([HTLexicon.typeParameterStart], consume: true)) {
      while ((curTok.type != HTLexicon.typeParameterEnd) &&
          (curTok.type != Semantic.endOfFile)) {
        final idTok = match(Semantic.identifier);
        final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
        final param = GenericTypeParameterExpr(id,
            source: _currentSource,
            line: idTok.line,
            column: idTok.column,
            offset: idTok.offset,
            length: curTok.offset - idTok.offset);
        if (curTok.type != HTLexicon.typeParameterEnd) {
          match(HTLexicon.comma);
        }
        _handleTrailingComment(param);
        genericParams.add(param);
      }
      match(HTLexicon.typeParameterEnd);
    }
    return genericParams;
  }

  ImportExportDecl _parseImportDecl() {
    // TODO: duplicate import and self import error.
    final keyword = advance(); // not a keyword so don't use match
    final showList = <IdentifierExpr>[];
    if (curTok.type == HTLexicon.functionBlockStart) {
      advance();
      if (curTok.type == HTLexicon.functionBlockEnd) {
        final err = HTError.emptyImportList(
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.end - keyword.offset);
        errors?.add(err);
      }
      while (curTok.type != HTLexicon.functionBlockEnd &&
          curTok.type != Semantic.endOfFile) {
        _handlePrecedingComment();
        final idTok = match(Semantic.identifier);
        final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
        if (curTok.type != HTLexicon.functionBlockEnd) {
          match(HTLexicon.comma);
        }
        _handleTrailingComment(id);
        showList.add(id);
      }
      match(HTLexicon.functionBlockEnd);
      // check lexeme here because expect() can only deal with token type
      final fromKeyword = advance().lexeme;
      if (fromKeyword != HTLexicon.kFrom) {
        final err = HTError.unexpected(HTLexicon.kFrom, curTok.lexeme,
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
      }
    }
    IdentifierExpr? alias;
    late bool hasEndOfStmtMark;
    void _handleAlias() {
      final aliasId = match(Semantic.identifier);
      alias = IdentifierExpr.fromToken(aliasId, source: _currentSource);
      hasEndOfStmtMark = expect([HTLexicon.endOfStatementMark], consume: true);
    }

    final fromPathTok = match(Semantic.stringLiteral);
    String fromPathRaw = fromPathTok.literal;
    String fromPath;
    bool isPreloadedModule = false;
    if (fromPathRaw.startsWith(HTResourceContext.hetuPreloadedModulesPrefix)) {
      isPreloadedModule = true;
      fromPath = fromPathRaw
          .substring(HTResourceContext.hetuPreloadedModulesPrefix.length);
      hasEndOfStmtMark = expect([HTLexicon.endOfStatementMark], consume: true);
    } else {
      fromPath = fromPathRaw;
      final ext = path.extension(fromPathTok.lexeme);
      if (ext != HTResource.hetuModule && ext != HTResource.hetuScript) {
        if (showList.isNotEmpty) {
          final err = HTError.importListOnNonHetuSource(
              filename: _currrentFileName,
              line: fromPathTok.line,
              column: fromPathTok.column,
              offset: fromPathTok.offset,
              length: fromPathTok.length);
          errors?.add(err);
        }
        match(HTLexicon.kAs);
        _handleAlias();
      } else {
        hasEndOfStmtMark =
            expect([HTLexicon.endOfStatementMark], consume: true);
        if (!hasEndOfStmtMark && expect([HTLexicon.kAs], consume: true)) {
          _handleAlias();
        }
      }
    }
    final stmt = ImportExportDecl(
        fromPath: fromPath,
        showList: showList,
        alias: alias,
        hasEndOfStmtMark: hasEndOfStmtMark,
        isPreloadedModule: isPreloadedModule,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
    _currentModuleImports.add(stmt);
    expect([HTLexicon.endOfStatementMark], consume: true);
    return stmt;
  }

  ImportExportDecl _parseExportStmt() {
    final keyword = advance(); // not a keyword so don't use match
    late final ImportExportDecl stmt;
    // export some of the symbols from this or other source
    if (curTok.type == HTLexicon.functionBlockStart) {
      advance();
      final showList = <IdentifierExpr>[];
      while (curTok.type != HTLexicon.functionBlockEnd &&
          curTok.type != Semantic.endOfFile) {
        _handlePrecedingComment();
        final idTok = match(Semantic.identifier);
        final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
        if (curTok.type != HTLexicon.functionBlockEnd) {
          match(HTLexicon.comma);
        }
        _handleTrailingComment(id);
        showList.add(id);
      }
      match(HTLexicon.functionBlockEnd);
      String? fromPath;
      var hasEndOfStmtMark =
          expect([HTLexicon.endOfStatementMark], consume: true);
      if (!hasEndOfStmtMark && curTok.lexeme == HTLexicon.kFrom) {
        advance();
        final fromPathTok = match(Semantic.stringLiteral);
        final ext = path.extension(fromPathTok.literal);
        if (ext != HTResource.hetuModule && ext != HTResource.hetuScript) {
          final err = HTError.importListOnNonHetuSource(
              filename: _currrentFileName,
              line: fromPathTok.line,
              column: fromPathTok.column,
              offset: fromPathTok.offset,
              length: fromPathTok.length);
          errors?.add(err);
        }
        hasEndOfStmtMark =
            expect([HTLexicon.endOfStatementMark], consume: true);
      }
      stmt = ImportExportDecl(
          fromPath: fromPath,
          showList: showList,
          hasEndOfStmtMark: hasEndOfStmtMark,
          isExport: true,
          source: _currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
      if (fromPath != null) {
        _currentModuleImports.add(stmt);
      }
    }
    // export all of the symbols from other source
    else {
      final key = match(Semantic.stringLiteral);
      final hasEndOfStmtMark =
          expect([HTLexicon.endOfStatementMark], consume: true);
      stmt = ImportExportDecl(
          fromPath: key.literal,
          hasEndOfStmtMark: hasEndOfStmtMark,
          isExport: true,
          source: _currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
      _currentModuleImports.add(stmt);
    }
    return stmt;
  }

  AstNode _parseDeleteStmt() {
    var keyword = advance();
    final nextTok = peek(1);
    if (curTok.type == Semantic.identifier &&
        nextTok.type != HTLexicon.memberGet &&
        nextTok.type != HTLexicon.subGetStart) {
      final id = advance().lexeme;
      final hasEndOfStmtMark =
          expect([HTLexicon.endOfStatementMark], consume: true);
      return DeleteStmt(id,
          source: _currentSource,
          hasEndOfStmtMark: hasEndOfStmtMark,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    } else {
      final expr = _parseExpr();
      final hasEndOfStmtMark =
          expect([HTLexicon.endOfStatementMark], consume: true);
      if (expr is MemberExpr) {
        return DeleteMemberStmt(expr.object, expr.key.id,
            hasEndOfStmtMark: hasEndOfStmtMark,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: curTok.offset - keyword.offset);
      } else if (expr is SubExpr) {
        return DeleteSubStmt(expr.object, expr.key,
            hasEndOfStmtMark: hasEndOfStmtMark,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: curTok.offset - keyword.offset);
      } else {
        final err = HTError.delete(
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
        final empty = EmptyLine(
            source: _currentSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: curTok.offset - keyword.offset);
        return empty;
      }
    }
  }

  NamespaceDecl _parseNamespaceDecl({bool isTopLevel = false}) {
    final keyword = match(HTLexicon.kNamespace);
    final idTok = match(Semantic.identifier);
    final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
    final definition = _parseBlockStmt(
        id: id.id, sourceType: ParseStyle.module, hasOwnNamespace: false);
    return NamespaceDecl(
      id,
      definition,
      classId: _currentClass?.id,
      isTopLevel: isTopLevel,
      source: _currentSource,
      line: keyword.line,
      column: keyword.column,
      offset: keyword.offset,
      length: curTok.end - keyword.offset,
    );
  }

  TypeAliasDecl _parseTypeAliasDecl(
      {String? classId, bool isTopLevel = false}) {
    final keyword = advance();
    final idTok = match(Semantic.identifier);
    final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
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

  VarDecl _parseVarDecl(
      {String? classId,
      bool isField = false,
      // bool typeInferrence = false,
      bool isOverrided = false,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isMutable = false,
      bool isTopLevel = false,
      bool lateFinalize = false,
      bool lateInitialize = false,
      AstNode? additionalInitializer,
      bool hasEndOfStatement = false}) {
    final keyword = advance();
    final idTok = match(Semantic.identifier);
    final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
    String? internalName;
    if (classId != null && isExternal) {
      // if (!(_currentClass!.isExternal) && !isStatic) {
      //   final err = HTError.externalMember(
      //       filename: _currrentFileName,
      //       line: keyword.line,
      //       column: keyword.column,
      //       offset: curTok.offset,
      //       length: curTok.length);
      //   errors?.add(err);
      // }
      internalName = '$classId.${idTok.lexeme}';
    }
    TypeExpr? declType;
    if (expect([HTLexicon.typeIndicator], consume: true)) {
      declType = _parseTypeExpr();
    }
    AstNode? initializer;
    if (!lateFinalize) {
      if (isConst) {
        match(HTLexicon.assign);
        initializer = _parseExpr();
      } else {
        if (expect([HTLexicon.assign], consume: true)) {
          initializer = _parseExpr();
        } else {
          initializer = additionalInitializer;
        }
      }
    }
    bool hasEndOfStmtMark = hasEndOfStatement;
    if (hasEndOfStatement) {
      match(HTLexicon.endOfStatementMark);
    } else {
      hasEndOfStmtMark = expect([HTLexicon.endOfStatementMark], consume: true);
    }
    return VarDecl(id,
        internalName: internalName,
        classId: classId,
        declType: declType,
        initializer: initializer,
        hasEndOfStmtMark: hasEndOfStmtMark,
        isField: isField,
        isExternal: isExternal,
        isStatic: isConst && classId != null ? true : isStatic,
        isConst: isConst,
        isMutable: !isConst && isMutable,
        isTopLevel: isTopLevel,
        lateFinalize: lateFinalize,
        lateInitialize: lateInitialize,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  DestructuringDecl _parseDestructuringDecl({bool isMutable = false}) {
    final keyword = advance(2);
    final ids = <IdentifierExpr, TypeExpr?>{};
    bool isVector = false;
    String endMark;
    if (peek(-1).type == HTLexicon.listStart) {
      endMark = HTLexicon.listEnd;
      isVector = true;
    } else {
      endMark = HTLexicon.functionBlockEnd;
    }
    while (curTok.type != endMark && curTok.type != Semantic.endOfFile) {
      _handlePrecedingComment();
      final idTok = match(Semantic.identifier);
      final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
      TypeExpr? declType;
      if (expect([HTLexicon.typeIndicator], consume: true)) {
        declType = _parseTypeExpr();
      }
      if (curTok.type != endMark) {
        match(HTLexicon.comma);
      }
      if (declType == null) {
        _handleTrailingComment(id);
      } else {
        _handleTrailingComment(declType);
      }
      ids[id] = declType;
    }
    match(endMark);
    match(HTLexicon.assign);
    final initializer = _parseExpr();
    bool hasEndOfStmtMark =
        expect([HTLexicon.endOfStatementMark], consume: true);
    return DestructuringDecl(
        ids: ids,
        isVector: isVector,
        initializer: initializer,
        hasEndOfStmtMark: hasEndOfStmtMark,
        isMutable: isMutable,
        source: _currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
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
    String? externalTypedef;
    if (category != FunctionCategory.literal || hasKeyword) {
      // there are multiple keyword for function, so don't use match here.
      startTok = advance();
      if (!isExternal &&
          (isStatic ||
              category == FunctionCategory.normal ||
              category == FunctionCategory.literal)) {
        if (expect([HTLexicon.listStart], consume: true)) {
          externalTypedef = match(Semantic.identifier).lexeme;
          match(HTLexicon.listEnd);
        }
      }
    }
    Token? id;
    late String internalName;
    // to distinguish getter and setter, and to give default constructor a name
    switch (category) {
      case FunctionCategory.factoryConstructor:
      case FunctionCategory.constructor:
        _hasUserDefinedConstructor = true;
        if (curTok.type == Semantic.identifier) {
          id = advance();
        }
        internalName = (id == null)
            ? InternalIdentifier.defaultConstructor
            : '${InternalIdentifier.namedConstructorPrefix}$id';
        break;
      case FunctionCategory.literal:
        if (curTok.type == Semantic.identifier) {
          id = advance();
        }
        internalName = (id == null)
            ? '${InternalIdentifier.anonymousFunction}${anonymousFunctionIndex++}'
            : id.lexeme;
        break;
      case FunctionCategory.getter:
        id = match(Semantic.identifier);
        internalName = '${InternalIdentifier.getter}$id';
        break;
      case FunctionCategory.setter:
        id = match(Semantic.identifier);
        internalName = '${InternalIdentifier.setter}$id';
        break;
      default:
        id = match(Semantic.identifier);
        internalName = id.lexeme;
    }
    final genericParameters = _getGenericParams();
    var isFuncVariadic = false;
    var minArity = 0;
    var maxArity = 0;
    var paramDecls = <ParamDecl>[];
    var hasParamDecls = false;
    if (category != FunctionCategory.getter &&
        expect([HTLexicon.groupExprStart], consume: true)) {
      final startTok = curTok;
      hasParamDecls = true;
      var isOptional = false;
      var isNamed = false;
      var isVariadic = false;
      while ((curTok.type != HTLexicon.groupExprEnd) &&
          (curTok.type != HTLexicon.listEnd) &&
          (curTok.type != HTLexicon.functionBlockEnd) &&
          (curTok.type != Semantic.endOfFile)) {
        _handlePrecedingComment();
        // 可选参数, 根据是否有方括号判断, 一旦开始了可选参数, 则不再增加参数数量arity要求
        if (!isOptional) {
          isOptional = expect([HTLexicon.listStart], consume: true);
          if (!isOptional && !isNamed) {
            //检查命名参数, 根据是否有花括号判断
            isNamed = expect([HTLexicon.functionBlockStart], consume: true);
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
        final paramId = match(Semantic.identifier);
        final paramSymbol =
            IdentifierExpr.fromToken(paramId, source: _currentSource);
        TypeExpr? paramDeclType;
        if (expect([HTLexicon.typeIndicator], consume: true)) {
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
            errors?.add(err);
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
        if (curTok.type != HTLexicon.listEnd &&
            curTok.type != HTLexicon.functionBlockEnd &&
            curTok.type != HTLexicon.groupExprEnd) {
          match(HTLexicon.comma);
        }
        _handleTrailingComment(param);
        paramDecls.add(param);
        if (isVariadic) {
          isFuncVariadic = true;
          break;
        }
      }
      if (isOptional) {
        match(HTLexicon.listEnd);
      } else if (isNamed) {
        match(HTLexicon.functionBlockEnd);
      }

      final endTok = match(HTLexicon.groupExprEnd);

      // setter can only have one parameter
      if ((category == FunctionCategory.setter) && (minArity != 1)) {
        final err = HTError.setterArity(
            filename: _currrentFileName,
            line: startTok.line,
            column: startTok.column,
            offset: startTok.offset,
            length: endTok.offset + endTok.length - startTok.offset);
        errors?.add(err);
      }
    }

    TypeExpr? returnType;
    RedirectingConstructorCallExpr? referCtor;
    // the return value type declaration
    if (expect([HTLexicon.functionReturnTypeIndicator], consume: true)) {
      if (category == FunctionCategory.constructor ||
          category == FunctionCategory.setter) {
        final err = HTError.unexpected(
            Semantic.functionDefinition, Semantic.returnType,
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
      }
      returnType = _parseTypeExpr();
    }
    // referring to another constructor
    else if (expect([HTLexicon.constructorInitializationListIndicator],
        consume: true)) {
      if (category != FunctionCategory.constructor) {
        final lastTok = peek(-1);
        final err = HTError.unexpected(HTLexicon.functionBlockStart,
            HTLexicon.constructorInitializationListIndicator,
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: lastTok.offset,
            length: lastTok.length);
        errors?.add(err);
      }
      if (isExternal) {
        final lastTok = peek(-1);
        final err = HTError.externalCtorWithReferCtor(
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: lastTok.offset,
            length: lastTok.length);
        errors?.add(err);
      }
      final ctorCallee = advance();
      if (!HTLexicon.redirectingConstructorCallKeywords
          .contains(ctorCallee.lexeme)) {
        final err = HTError.unexpected(Semantic.ctorCallExpr, curTok.lexeme,
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: ctorCallee.offset,
            length: ctorCallee.length);
        errors?.add(err);
      }
      Token? ctorKey;
      if (expect([HTLexicon.memberGet], consume: true)) {
        ctorKey = match(Semantic.identifier);
        match(HTLexicon.groupExprStart);
      } else {
        match(HTLexicon.groupExprStart);
      }
      var positionalArgs = <AstNode>[];
      var namedArgs = <String, AstNode>{};
      _handleCallArguments(positionalArgs, namedArgs);
      referCtor = RedirectingConstructorCallExpr(
          IdentifierExpr.fromToken(ctorCallee, source: _currentSource),
          positionalArgs,
          namedArgs,
          key: ctorKey != null
              ? IdentifierExpr.fromToken(ctorKey, source: _currentSource)
              : null,
          source: _currentSource,
          line: ctorCallee.line,
          column: ctorCallee.column,
          offset: ctorCallee.offset,
          length: curTok.offset - ctorCallee.offset);
    }
    bool isExpressionBody = false;
    bool hasEndOfStmtMark = false;
    AstNode? definition;
    if (curTok.type == HTLexicon.functionBlockStart) {
      if (category == FunctionCategory.literal && !hasKeyword) {
        startTok = curTok;
      }
      definition = _parseBlockStmt(id: Semantic.functionCall);
    } else if (expect([HTLexicon.functionSingleLineBodyIndicator],
        consume: true)) {
      isExpressionBody = true;
      if (category == FunctionCategory.literal && !hasKeyword) {
        startTok = curTok;
      }
      definition = _parseExpr();
      hasEndOfStmtMark = expect([HTLexicon.endOfStatementMark], consume: true);
    } else if (expect([HTLexicon.assign], consume: true)) {
      final err = HTError.unsupported(Semantic.redirectingFunctionDefinition,
          filename: _currrentFileName,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.length);
      errors?.add(err);
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
        errors?.add(err);
      }
      if (category != FunctionCategory.literal) {
        expect([HTLexicon.endOfStatementMark], consume: true);
      }
    }
    _currentFunctionCategory = savedCurFuncType;
    return FuncDecl(internalName, paramDecls,
        id: id != null
            ? IdentifierExpr.fromToken(id, source: _currentSource)
            : null,
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
      bool isTopLevel = false,
      bool lateResolve = true}) {
    final keyword = match(HTLexicon.kClass);
    if (_currentClass != null && _currentClass!.isNested) {
      final err = HTError.nestedClass(
          filename: _currrentFileName,
          line: curTok.line,
          column: curTok.column,
          offset: keyword.offset,
          length: keyword.length);
      errors?.add(err);
    }
    final id = match(Semantic.identifier);
    final genericParameters = _getGenericParams();
    TypeExpr? superClassType;
    if (curTok.lexeme == HTLexicon.kExtends) {
      advance();
      if (curTok.lexeme == id.lexeme) {
        final err = HTError.extendsSelf(
            filename: _currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
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
        sourceType: ParseStyle.classDefinition,
        hasOwnNamespace: false,
        id: Semantic.classDefinition);
    final decl = ClassDecl(
        IdentifierExpr.fromToken(id, source: _currentSource), definition,
        genericTypeParameters: genericParameters,
        superType: superClassType,
        isExternal: isExternal,
        isAbstract: isAbstract,
        isTopLevel: isTopLevel,
        hasUserDefinedConstructor: _hasUserDefinedConstructor,
        lateResolve: lateResolve,
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
    final id = match(Semantic.identifier);
    var enumerations = <IdentifierExpr>[];
    if (expect([HTLexicon.functionBlockStart], consume: true)) {
      _handlePrecedingComment();
      while (curTok.type != HTLexicon.functionBlockEnd &&
          curTok.type != Semantic.endOfFile) {
        final enumIdTok = match(Semantic.identifier);
        final enumId =
            IdentifierExpr.fromToken(enumIdTok, source: _currentSource);
        if (curTok.type != HTLexicon.functionBlockEnd) {
          match(HTLexicon.comma);
        }
        _handleTrailingComment(enumId);
        enumerations.add(enumId);
      }
      match(HTLexicon.functionBlockEnd);
    } else {
      expect([HTLexicon.endOfStatementMark], consume: true);
    }
    return EnumDecl(
        IdentifierExpr.fromToken(id, source: _currentSource), enumerations,
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
    final idTok = match(Semantic.identifier);
    final id = IdentifierExpr.fromToken(idTok, source: _currentSource);
    IdentifierExpr? prototypeId;
    if (expect([HTLexicon.kExtends], consume: true)) {
      final prototypeIdTok = match(Semantic.identifier);
      if (prototypeIdTok.lexeme == id.id) {
        final err = HTError.extendsSelf(
            filename: _currrentFileName,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length);
        errors?.add(err);
      }
      prototypeId =
          IdentifierExpr.fromToken(prototypeIdTok, source: _currentSource);
    }
    final savedStructId = _currentStructId;
    _currentStructId = id.id;
    final definition = <AstNode>[];
    final startTok = match(HTLexicon.functionBlockStart);
    while (curTok.type != HTLexicon.functionBlockEnd &&
        curTok.type != Semantic.endOfFile) {
      final stmt = _parseStmt(sourceType: ParseStyle.structDefinition);
      if (stmt != null) {
        definition.add(stmt);
      }
    }
    final endTok = match(HTLexicon.functionBlockEnd);
    if (definition.isEmpty) {
      final empty = EmptyLine(
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
        final idTok = match(Semantic.identifier);
        prototypeId = IdentifierExpr.fromToken(idTok, source: _currentSource);
      }
    }
    prototypeId ??= IdentifierExpr(HTLexicon.globalPrototypeId);
    final structBlockStartTok = match(HTLexicon.functionBlockStart);
    final fields = <StructObjField>[];
    while (curTok.type != HTLexicon.functionBlockEnd &&
        curTok.type != Semantic.endOfFile) {
      if (curTok.type == Semantic.identifier ||
          curTok.type == Semantic.stringLiteral) {
        final keyTok = advance();
        late final StructObjField field;
        if (curTok.type == HTLexicon.comma ||
            curTok.type == HTLexicon.functionBlockEnd) {
          final id = IdentifierExpr.fromToken(keyTok, source: _currentSource);
          field = StructObjField(
              key: IdentifierExpr.fromToken(
                keyTok,
                isLocal: false,
                source: _currentSource,
              ),
              fieldValue: id);
        } else {
          match(HTLexicon.structValueIndicator);
          final value = _parseExpr();
          field = StructObjField(
              key: IdentifierExpr.fromToken(
                keyTok,
                isLocal: false,
                source: _currentSource,
              ),
              fieldValue: value);
        }
        if (curTok.type != HTLexicon.functionBlockEnd) {
          match(HTLexicon.comma);
        }
        _handleTrailingComment(field);
        fields.add(field);
      } else if (curTok.type == HTLexicon.spreadSyntax) {
        advance();
        final value = _parseExpr();
        final field = StructObjField(fieldValue: value, isSpread: true);
        if (curTok.type != HTLexicon.functionBlockEnd) {
          match(HTLexicon.comma);
        }
        _handleTrailingComment(field);
        fields.add(field);
      } else if (curTok is TokenComment) {
        _handlePrecedingComment();
      } else {
        final errTok = advance();
        final err = HTError.structMemberId(
            filename: _currrentFileName,
            line: errTok.line,
            column: errTok.column,
            offset: errTok.offset,
            length: errTok.length);
        errors?.add(err);
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
    match(HTLexicon.functionBlockEnd);
    return StructObjExpr(fields,
        prototypeId: prototypeId,
        source: _currentSource,
        line: structBlockStartTok.line,
        column: structBlockStartTok.column,
        offset: structBlockStartTok.offset,
        length: curTok.offset - structBlockStartTok.offset);
  }
}
