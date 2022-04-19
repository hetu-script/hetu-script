import 'package:path/path.dart' as path;

import 'parser.dart';
import 'token.dart';
import '../lexer/lexicon_default_impl.dart';
import '../error/error.dart';
import '../resource/resource.dart';
import '../resource/resource_context.dart';
import '../grammar/constant.dart';
import '../declaration/class/class_declaration.dart';
import '../ast/ast.dart';
import '../comment/comment.dart';
import '../parser/parser.dart';
import '../type/type.dart' show PrimitiveTypeCategory;

/// Default parser implementation used by Hetu.
class HTDefaultParser extends HTParser {
  @override
  String get name => 'default';

  HTDefaultParser() : super(lexicon: HTDefaultLexicon());

  bool get _isWithinModuleNamespace {
    if (currentFunctionCategory != null) {
      return false;
    } else if (currentSource != null) {
      if (currentSource!.type == HTResourceType.hetuModule) {
        return true;
      }
    }
    return false;
  }

  bool _handlePrecedingComment() {
    bool handled = false;
    while (curTok is TokenComment) {
      handled = true;
      final comment = Comment.fromToken(curTok as TokenComment);
      currentPrecedingComments.add(comment);
      advance();
    }
    return handled;
  }

  bool _handleTrailingComment(ASTNode expr) {
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

  @override
  ASTNode? parseStmt({required ParseStyle style}) {
    if (_handlePrecedingComment()) {
      return null;
    }

    final precedingComments = currentPrecedingComments;
    currentPrecedingComments = [];

    if (curTok is TokenEmptyLine) {
      final empty = advance();
      final emptyStmt = ASTEmptyLine(
          line: empty.line, column: empty.column, offset: empty.offset);
      emptyStmt.precedingComments = precedingComments;
      return emptyStmt;
    }

    ASTNode stmt;

    switch (style) {
      case ParseStyle.script:
        if (curTok.lexeme == lexicon.kImport) {
          stmt = _parseImportDecl();
        } else if (curTok.lexeme == lexicon.kExport) {
          stmt = _parseExportStmt();
        } else if (curTok.lexeme == lexicon.kType) {
          stmt = _parseTypeAliasDecl();
        } else {
          if (curTok.type == lexicon.kExternal) {
            advance();
            if (curTok.type == lexicon.kAbstract) {
              advance();
              stmt = _parseClassDecl(
                  isAbstract: true, isExternal: true, isTopLevel: true);
            } else if (curTok.type == lexicon.kClass) {
              stmt = _parseClassDecl(isExternal: true, isTopLevel: true);
            } else if (curTok.type == lexicon.kEnum) {
              stmt = _parseEnumDecl(isExternal: true, isTopLevel: true);
            } else if (lexicon.variableDeclarationKeywords
                .contains(curTok.type)) {
              final err = HTError.externalVar(
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else if (curTok.type == lexicon.kFun) {
              stmt = _parseFunction(isExternal: true, isTopLevel: true);
            } else {
              final err = HTError.unexpected(
                  lexicon.kExternal, Semantic.declStmt, curTok.lexeme,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            }
          } else if (curTok.type == lexicon.kAbstract) {
            advance();
            stmt = _parseClassDecl(
                isAbstract: true, isTopLevel: true, lateResolve: false);
          } else if (curTok.type == lexicon.kClass) {
            stmt = _parseClassDecl(isTopLevel: true, lateResolve: false);
          } else if (curTok.type == lexicon.kEnum) {
            stmt = _parseEnumDecl(isTopLevel: true);
          } else if (curTok.type == lexicon.kNamespace) {
            stmt = _parseNamespaceDecl(isTopLevel: true);
          } else if (curTok.type == lexicon.kVar) {
            if (lexicon.destructuringDeclarationMark.contains(peek(1).type)) {
              stmt = _parseDestructuringDecl(isMutable: true);
            } else {
              stmt = _parseVarDecl(isMutable: true, isTopLevel: true);
            }
          } else if (curTok.type == lexicon.kFinal) {
            if (lexicon.destructuringDeclarationMark.contains(peek(1).type)) {
              stmt = _parseDestructuringDecl();
            } else {
              stmt = _parseVarDecl(isTopLevel: true);
            }
          } else if (curTok.type == lexicon.kLate) {
            stmt = _parseVarDecl(lateFinalize: true, isTopLevel: true);
          } else if (curTok.type == lexicon.kConst) {
            stmt = _parseVarDecl(isConst: true, isTopLevel: true);
          } else if (curTok.type == lexicon.kFun) {
            if (expect([lexicon.kFun, Semantic.identifier]) ||
                expect([
                  lexicon.kFun,
                  lexicon.externalFunctionTypeDefStart,
                  Semantic.identifier,
                  lexicon.externalFunctionTypeDefEnd,
                  Semantic.identifier
                ])) {
              stmt = _parseFunction(isTopLevel: true);
            } else {
              stmt = _parseFunction(
                  category: FunctionCategory.literal, isTopLevel: true);
            }
          } else if (curTok.type == lexicon.kAsync) {
            if (expect([lexicon.kAsync, Semantic.identifier]) ||
                expect([
                  lexicon.kFun,
                  lexicon.externalFunctionTypeDefStart,
                  Semantic.identifier,
                  lexicon.externalFunctionTypeDefEnd,
                  Semantic.identifier
                ])) {
              stmt = _parseFunction(isAsync: true, isTopLevel: true);
            } else {
              stmt = _parseFunction(
                  category: FunctionCategory.literal,
                  isAsync: true,
                  isTopLevel: true);
            }
          } else if (curTok.type == lexicon.kStruct) {
            stmt =
                _parseStructDecl(isTopLevel: true); // , lateInitialize: false);
          } else if (curTok.type == lexicon.kDelete) {
            stmt = _parseDeleteStmt();
          } else if (curTok.type == lexicon.kIf) {
            stmt = _parseIf();
          } else if (curTok.type == lexicon.kWhile) {
            stmt = _parseWhileStmt();
          } else if (curTok.type == lexicon.kDo) {
            stmt = _parseDoStmt();
          } else if (curTok.type == lexicon.kFor) {
            stmt = _parseForStmt();
          } else if (curTok.type == lexicon.kWhen) {
            stmt = _parseWhen();
          } else if (curTok.type == lexicon.kAssert) {
            stmt = _parseAssertStmt();
          } else if (curTok.type == lexicon.kThrow) {
            stmt = _parseThrowStmt();
          } else {
            stmt = _parseExprStmt();
          }
        }
        break;
      case ParseStyle.module:
        if (curTok.lexeme == lexicon.kImport) {
          stmt = _parseImportDecl();
        } else if (curTok.lexeme == lexicon.kExport) {
          stmt = _parseExportStmt();
        } else if (curTok.lexeme == lexicon.kType) {
          stmt = _parseTypeAliasDecl(isTopLevel: true);
        } else {
          if (curTok.type == lexicon.kNamespace) {
            stmt = _parseNamespaceDecl(isTopLevel: true);
          } else if (curTok.type == lexicon.kExternal) {
            advance();
            if (curTok.type == lexicon.kAbstract) {
              advance();
              if (curTok.type != lexicon.kClass) {
                final err = HTError.unexpected(
                    lexicon.kAbstract, Semantic.classDeclaration, curTok.lexeme,
                    filename: currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance();
                stmt = ASTEmptyLine(
                    source: currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              } else {
                stmt = _parseClassDecl(
                    isAbstract: true, isExternal: true, isTopLevel: true);
              }
            } else if (curTok.type == lexicon.kClass) {
              stmt = _parseClassDecl(isExternal: true, isTopLevel: true);
            } else if (curTok.type == lexicon.kEnum) {
              stmt = _parseEnumDecl(isExternal: true, isTopLevel: true);
            } else if (curTok.type == lexicon.kFun) {
              stmt = _parseFunction(isExternal: true, isTopLevel: true);
            } else if (lexicon.variableDeclarationKeywords
                .contains(curTok.type)) {
              final err = HTError.externalVar(
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else {
              final err = HTError.unexpected(
                  lexicon.kExternal, Semantic.declStmt, curTok.lexeme,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            }
          } else if (curTok.type == lexicon.kAbstract) {
            advance();
            stmt = _parseClassDecl(isAbstract: true, isTopLevel: true);
          } else if (curTok.type == lexicon.kClass) {
            stmt = _parseClassDecl(isTopLevel: true);
          } else if (curTok.type == lexicon.kEnum) {
            stmt = _parseEnumDecl(isTopLevel: true);
          } else if (curTok.type == lexicon.kVar) {
            stmt = _parseVarDecl(
                isMutable: true, isTopLevel: true, lateInitialize: true);
          } else if (curTok.type == lexicon.kFinal) {
            stmt = _parseVarDecl(lateInitialize: true, isTopLevel: true);
          } else if (curTok.type == lexicon.kLate) {
            stmt = _parseVarDecl(lateFinalize: true, isTopLevel: true);
          } else if (curTok.type == lexicon.kConst) {
            stmt = _parseVarDecl(isConst: true, isTopLevel: true);
          } else if (curTok.type == lexicon.kFun) {
            stmt = _parseFunction(isTopLevel: true);
          } else if (curTok.type == lexicon.kStruct) {
            stmt = _parseStructDecl(isTopLevel: true);
          } else {
            final err = HTError.unexpected(
                Semantic.declStmt, Semantic.declStmt, curTok.lexeme,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors?.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          }
        }
        break;
      case ParseStyle.namespace:
        if (curTok.lexeme == lexicon.kType) {
          stmt = _parseTypeAliasDecl();
        } else {
          if (curTok.type == lexicon.kNamespace) {
            stmt = _parseNamespaceDecl();
          } else if (curTok.type == lexicon.kExternal) {
            advance();
            if (curTok.type == lexicon.kAbstract) {
              advance();
              if (curTok.type != lexicon.kClass) {
                final err = HTError.unexpected(
                    lexicon.kAbstract, Semantic.classDeclaration, curTok.lexeme,
                    filename: currrentFileName,
                    line: curTok.line,
                    column: curTok.column,
                    offset: curTok.offset,
                    length: curTok.length);
                errors?.add(err);
                final errToken = advance();
                stmt = ASTEmptyLine(
                    source: currentSource,
                    line: errToken.line,
                    column: errToken.column,
                    offset: errToken.offset);
              } else {
                stmt = _parseClassDecl(isAbstract: true, isExternal: true);
              }
            } else if (curTok.type == lexicon.kClass) {
              stmt = _parseClassDecl(isExternal: true);
            } else if (curTok.type == lexicon.kEnum) {
              stmt = _parseEnumDecl(isExternal: true);
            } else if (curTok.type == lexicon.kFun) {
              stmt = _parseFunction(isExternal: true);
            } else if (lexicon.variableDeclarationKeywords
                .contains(curTok.type)) {
              final err = HTError.externalVar(
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else {
              final err = HTError.unexpected(
                  lexicon.kExternal, Semantic.declStmt, curTok.lexeme,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            }
          } else if (curTok.type == lexicon.kAbstract) {
            advance();
            stmt = _parseClassDecl(
                isAbstract: true, lateResolve: _isWithinModuleNamespace);
          } else if (curTok.type == lexicon.kClass) {
            stmt = _parseClassDecl(lateResolve: _isWithinModuleNamespace);
          } else if (curTok.type == lexicon.kEnum) {
            stmt = _parseEnumDecl();
          } else if (curTok.type == lexicon.kVar) {
            stmt = _parseVarDecl(
                isMutable: true, lateInitialize: _isWithinModuleNamespace);
          } else if (curTok.type == lexicon.kFinal) {
            stmt = _parseVarDecl(lateInitialize: _isWithinModuleNamespace);
          } else if (curTok.type == lexicon.kConst) {
            stmt = _parseVarDecl(isConst: true);
          } else if (curTok.type == lexicon.kFun) {
            stmt = _parseFunction();
          } else if (curTok.type == lexicon.kStruct) {
            stmt = _parseStructDecl();
          } else {
            final err = HTError.unexpected(
                Semantic.declStmt, Semantic.declStmt, curTok.lexeme,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors?.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          }
        }
        break;
      case ParseStyle.classDefinition:
        final isOverrided = expect([lexicon.kOverride], consume: true);
        final isExternal = expect([lexicon.kExternal], consume: true) ||
            (currentClass?.isExternal ?? false);
        final isStatic = expect([lexicon.kStatic], consume: true);
        if (curTok.lexeme == lexicon.kType) {
          if (isExternal) {
            final err = HTError.external(Semantic.typeAliasDeclaration,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors?.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          } else {
            stmt = _parseTypeAliasDecl();
          }
        } else {
          if (curTok.type == lexicon.kVar) {
            stmt = _parseVarDecl(
                classId: currentClass?.id,
                isOverrided: isOverrided,
                isExternal: isExternal,
                isMutable: true,
                isStatic: isStatic,
                lateInitialize: true);
          } else if (curTok.type == lexicon.kFinal) {
            stmt = _parseVarDecl(
                classId: currentClass?.id,
                isOverrided: isOverrided,
                isExternal: isExternal,
                isStatic: isStatic,
                lateInitialize: true);
          } else if (curTok.type == lexicon.kLate) {
            stmt = _parseVarDecl(
                classId: currentClass?.id,
                isOverrided: isOverrided,
                isExternal: isExternal,
                isStatic: isStatic,
                lateFinalize: true);
          } else if (curTok.type == lexicon.kConst) {
            if (isStatic) {
              stmt = _parseVarDecl(isConst: true, classId: currentClass?.id);
            } else {
              final err = HTError.external(Semantic.typeAliasDeclaration,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            }
          } else if (curTok.type == lexicon.kFun) {
            stmt = _parseFunction(
                category: FunctionCategory.method,
                classId: currentClass?.id,
                isOverrided: isOverrided,
                isExternal: isExternal,
                isStatic: isStatic);
          } else if (curTok.type == lexicon.kAsync) {
            if (isExternal) {
              final err = HTError.external(Semantic.asyncFunction,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else {
              stmt = _parseFunction(
                  category: FunctionCategory.method,
                  classId: currentClass?.id,
                  isAsync: true,
                  isOverrided: isOverrided,
                  isExternal: isExternal,
                  isStatic: isStatic);
            }
          } else if (curTok.type == lexicon.kGet) {
            stmt = _parseFunction(
                category: FunctionCategory.getter,
                classId: currentClass?.id,
                isOverrided: isOverrided,
                isExternal: isExternal,
                isStatic: isStatic);
          } else if (curTok.type == lexicon.kSet) {
            stmt = _parseFunction(
                category: FunctionCategory.setter,
                classId: currentClass?.id,
                isOverrided: isOverrided,
                isExternal: isExternal,
                isStatic: isStatic);
          } else if (curTok.type == lexicon.kConstruct) {
            if (isStatic) {
              final err = HTError.unexpected(
                  lexicon.kStatic, Semantic.declStmt, lexicon.kConstruct,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else if (isExternal && !currentClass!.isExternal) {
              final err = HTError.external(Semantic.ctorFunction,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else {
              stmt = _parseFunction(
                category: FunctionCategory.constructor,
                classId: currentClass?.id,
                isExternal: isExternal,
              );
            }
          } else if (curTok.type == lexicon.kFactory) {
            if (isStatic) {
              final err = HTError.unexpected(
                  lexicon.kStatic, Semantic.declStmt, lexicon.kConstruct,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else if (isExternal && !currentClass!.isExternal) {
              final err = HTError.external(Semantic.factory,
                  filename: currrentFileName,
                  line: curTok.line,
                  column: curTok.column,
                  offset: curTok.offset,
                  length: curTok.length);
              errors?.add(err);
              final errToken = advance();
              stmt = ASTEmptyLine(
                  source: currentSource,
                  line: errToken.line,
                  column: errToken.column,
                  offset: errToken.offset);
            } else {
              stmt = _parseFunction(
                category: FunctionCategory.factoryConstructor,
                classId: currentClass?.id,
                isExternal: isExternal,
                isStatic: true,
              );
            }
          } else {
            final err = HTError.unexpected(
                Semantic.classDefinition, Semantic.declStmt, curTok.lexeme,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors?.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          }
        }
        break;
      case ParseStyle.structDefinition:
        final isExternal = expect([lexicon.kExternal], consume: true);
        final isStatic = expect([lexicon.kStatic], consume: true);
        if (curTok.type == lexicon.kVar) {
          stmt = _parseVarDecl(
              classId: currentStructId,
              isField: true,
              isExternal: isExternal,
              isMutable: true,
              isStatic: isStatic,
              lateInitialize: true);
        } else if (curTok.type == lexicon.kFinal) {
          stmt = _parseVarDecl(
              classId: currentStructId,
              isField: true,
              isExternal: isExternal,
              isStatic: isStatic,
              lateInitialize: true);
        } else if (curTok.type == lexicon.kFun) {
          stmt = _parseFunction(
              category: FunctionCategory.method,
              classId: currentStructId,
              isExternal: isExternal,
              isField: true,
              isStatic: isStatic);
        } else if (curTok.type == lexicon.kAsync) {
          if (isExternal) {
            final err = HTError.external(Semantic.asyncFunction,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors?.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          } else {
            stmt = _parseFunction(
                category: FunctionCategory.method,
                classId: currentStructId,
                isAsync: true,
                isField: true,
                isExternal: isExternal,
                isStatic: isStatic);
          }
        } else if (curTok.type == lexicon.kGet) {
          stmt = _parseFunction(
              category: FunctionCategory.getter,
              classId: currentStructId,
              isField: true,
              isExternal: isExternal,
              isStatic: isStatic);
        } else if (curTok.type == lexicon.kSet) {
          stmt = _parseFunction(
              category: FunctionCategory.setter,
              classId: currentStructId,
              isField: true,
              isExternal: isExternal,
              isStatic: isStatic);
        } else if (curTok.type == lexicon.kConstruct) {
          if (isStatic) {
            final err = HTError.unexpected(
                lexicon.kStatic, Semantic.declStmt, lexicon.kConstruct,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors?.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          } else if (isExternal) {
            final err = HTError.external(Semantic.ctorFunction,
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors?.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          } else {
            stmt = _parseFunction(
                category: FunctionCategory.constructor,
                classId: currentStructId,
                isExternal: isExternal,
                isField: true);
          }
        } else {
          final err = HTError.unexpected(
              Semantic.structDefinition, Semantic.declStmt, curTok.lexeme,
              filename: currrentFileName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.length);
          errors?.add(err);
          final errToken = advance();
          stmt = ASTEmptyLine(
              source: currentSource,
              line: errToken.line,
              column: errToken.column,
              offset: errToken.offset);
        }
        break;
      case ParseStyle.functionDefinition:
        if (curTok.type == lexicon.kNamespace) {
          stmt = _parseNamespaceDecl();
        } else if (curTok.type == lexicon.kAbstract) {
          advance();
          stmt = _parseClassDecl(isAbstract: true, lateResolve: false);
        } else if (curTok.type == lexicon.kClass) {
          stmt = _parseClassDecl(lateResolve: false);
        } else if (curTok.type == lexicon.kEnum) {
          stmt = _parseEnumDecl();
        } else if (curTok.type == lexicon.kVar) {
          if (lexicon.destructuringDeclarationMark.contains(peek(1).type)) {
            stmt = _parseDestructuringDecl(isMutable: true);
          } else {
            stmt = _parseVarDecl(isMutable: true);
          }
        } else if (curTok.type == lexicon.kFinal) {
          if (lexicon.destructuringDeclarationMark.contains(peek(1).type)) {
            stmt = _parseDestructuringDecl();
          } else {
            stmt = _parseVarDecl();
          }
        } else if (curTok.type == lexicon.kLate) {
          stmt = _parseVarDecl(lateFinalize: true);
        } else if (curTok.type == lexicon.kConst) {
          stmt = _parseVarDecl(isConst: true);
        } else if (curTok.type == lexicon.kFun) {
          if (expect([lexicon.kFun, Semantic.identifier]) ||
              expect([
                lexicon.kFun,
                lexicon.externalFunctionTypeDefStart,
                Semantic.identifier,
                lexicon.externalFunctionTypeDefEnd,
                Semantic.identifier
              ])) {
            stmt = _parseFunction();
          } else {
            stmt = _parseFunction(category: FunctionCategory.literal);
          }
        } else if (curTok.type == lexicon.kAsync) {
          if (expect([lexicon.kAsync, Semantic.identifier]) ||
              expect([
                lexicon.kFun,
                lexicon.externalFunctionTypeDefStart,
                Semantic.identifier,
                lexicon.externalFunctionTypeDefEnd,
                Semantic.identifier
              ])) {
            stmt = _parseFunction(isAsync: true);
          } else {
            stmt = _parseFunction(
                category: FunctionCategory.literal, isAsync: true);
          }
        } else if (curTok.type == lexicon.kStruct) {
          stmt = _parseStructDecl(); // (lateInitialize: false);
        } else if (curTok.type == lexicon.kDelete) {
          stmt = _parseDeleteStmt();
        } else if (curTok.type == lexicon.kIf) {
          stmt = _parseIf();
        } else if (curTok.type == lexicon.kWhile) {
          stmt = _parseWhileStmt();
        } else if (curTok.type == lexicon.kDo) {
          stmt = _parseDoStmt();
        } else if (curTok.type == lexicon.kFor) {
          stmt = _parseForStmt();
        } else if (curTok.type == lexicon.kWhen) {
          stmt = _parseWhen();
        } else if (curTok.type == lexicon.kAssert) {
          stmt = _parseAssertStmt();
        } else if (curTok.type == lexicon.kThrow) {
          stmt = _parseThrowStmt();
        } else if (curTok.type == lexicon.kBreak) {
          final keyword = advance();
          final hasEndOfStmtMark =
              expect([lexicon.endOfStatementMark], consume: true);
          stmt = BreakStmt(keyword,
              hasEndOfStmtMark: hasEndOfStmtMark,
              source: currentSource,
              line: keyword.line,
              column: keyword.column,
              offset: keyword.offset,
              length: keyword.length);
        } else if (curTok.type == lexicon.kContinue) {
          final keyword = advance();
          final hasEndOfStmtMark =
              expect([lexicon.endOfStatementMark], consume: true);
          stmt = ContinueStmt(keyword,
              hasEndOfStmtMark: hasEndOfStmtMark,
              source: currentSource,
              line: keyword.line,
              column: keyword.column,
              offset: keyword.offset,
              length: keyword.length);
        } else if (curTok.type == lexicon.kReturn) {
          if (currentFunctionCategory != null &&
              currentFunctionCategory != FunctionCategory.constructor) {
            stmt = _parseReturnStmt();
          } else {
            final err = HTError.outsideReturn(
                filename: currrentFileName,
                line: curTok.line,
                column: curTok.column,
                offset: curTok.offset,
                length: curTok.length);
            errors?.add(err);
            final errToken = advance();
            stmt = ASTEmptyLine(
                source: currentSource,
                line: errToken.line,
                column: errToken.column,
                offset: errToken.offset);
          }
        } else {
          stmt = _parseExprStmt();
        }
        break;
      case ParseStyle.expression:
        stmt = _parseExpr();
    }

    stmt.precedingComments = precedingComments;

    if (curTok is TokenComment) {
      final token = advance() as TokenComment;
      if (token.isTrailing) {
        stmt.trailingComment = Comment.fromToken(token);
      }
    }

    return stmt;
  }

  AssertStmt _parseAssertStmt() {
    final keyword = match(lexicon.kAssert);
    match(lexicon.groupExprStart);
    final expr = _parseExpr();
    match(lexicon.groupExprEnd);
    final hasEndOfStmtMark =
        expect([lexicon.endOfStatementMark], consume: true);
    final stmt = AssertStmt(expr,
        hasEndOfStmtMark: hasEndOfStmtMark,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: expr.end - keyword.offset);
    return stmt;
  }

  ThrowStmt _parseThrowStmt() {
    final keyword = match(lexicon.kThrow);
    final message = _parseExpr();
    final hasEndOfStmtMark =
        expect([lexicon.endOfStatementMark], consume: true);
    final stmt = ThrowStmt(message,
        hasEndOfStmtMark: hasEndOfStmtMark,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: message.end - keyword.offset);
    return stmt;
  }

  /// Recursive descent parsing
  ///
  /// Assignment operator =, precedence 1, associativity right
  ASTNode _parseExpr() {
    _handlePrecedingComment();
    ASTNode? expr;
    final left = _parserTernaryExpr();
    if (lexicon.assignments.contains(curTok.type)) {
      final op = advance();
      final right = _parseExpr();
      expr = AssignExpr(left, op.lexeme, right,
          source: currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    } else {
      expr = left;
    }

    expr.precedingComments = currentPrecedingComments;
    currentPrecedingComments = [];

    return expr;
  }

  /// Ternery operator: e1 ? e2 : e3, precedence 3, associativity right
  ASTNode _parserTernaryExpr() {
    var condition = _parseIfNullExpr();
    if (expect([lexicon.ternaryThen], consume: true)) {
      leftValueLegality = false;
      final thenBranch = _parserTernaryExpr();
      match(lexicon.ternaryElse);
      final elseBranch = _parserTernaryExpr();
      condition = TernaryExpr(condition, thenBranch, elseBranch,
          source: currentSource,
          line: condition.line,
          column: condition.column,
          offset: condition.offset,
          length: curTok.offset - condition.offset);
    }
    return condition;
  }

  /// If null: e1 ?? e2, precedence 4, associativity left
  ASTNode _parseIfNullExpr() {
    var left = _parseLogicalOrExpr();
    if (curTok.type == lexicon.ifNull) {
      leftValueLegality = false;
      while (curTok.type == lexicon.ifNull) {
        final op = advance();
        final right = _parseLogicalOrExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: currentSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// Logical or: ||, precedence 5, associativity left
  ASTNode _parseLogicalOrExpr() {
    var left = _parseLogicalAndExpr();
    if (curTok.type == lexicon.logicalOr) {
      leftValueLegality = false;
      while (curTok.type == lexicon.logicalOr) {
        final op = advance();
        final right = _parseLogicalAndExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: currentSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// Logical and: &&, precedence 6, associativity left
  ASTNode _parseLogicalAndExpr() {
    var left = _parseEqualityExpr();
    if (curTok.type == lexicon.logicalAnd) {
      leftValueLegality = false;
      while (curTok.type == lexicon.logicalAnd) {
        final op = advance();
        final right = _parseEqualityExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: currentSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// Logical equal: ==, !=, precedence 7, associativity none
  ASTNode _parseEqualityExpr() {
    var left = _parseRelationalExpr();
    if (lexicon.equalitys.contains(curTok.type)) {
      leftValueLegality = false;
      final op = advance();
      final right = _parseRelationalExpr();
      left = BinaryExpr(left, op.lexeme, right,
          source: currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    }
    return left;
  }

  /// Logical compare: <, >, <=, >=, as, is, is!, in, in!, precedence 8, associativity none
  ASTNode _parseRelationalExpr() {
    var left = _parseAdditiveExpr();
    if (lexicon.logicalRelationals.contains(curTok.type)) {
      leftValueLegality = false;
      final op = advance();
      final right = _parseAdditiveExpr();
      left = BinaryExpr(left, op.lexeme, right,
          source: currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    } else if (lexicon.setRelationals.contains(curTok.type)) {
      leftValueLegality = false;
      final op = advance();
      late final String opLexeme;
      if (op.lexeme == lexicon.kIn) {
        opLexeme = expect([lexicon.logicalNot], consume: true)
            ? lexicon.kNotIn
            : lexicon.kIn;
      } else {
        opLexeme = op.lexeme;
      }
      final right = _parseAdditiveExpr();
      left = BinaryExpr(left, opLexeme, right,
          source: currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    } else if (lexicon.typeRelationals.contains(curTok.type)) {
      leftValueLegality = false;
      final op = advance();
      late final String opLexeme;
      if (op.lexeme == lexicon.kIs) {
        opLexeme = expect([lexicon.logicalNot], consume: true)
            ? lexicon.kIsNot
            : lexicon.kIs;
      } else {
        opLexeme = op.lexeme;
      }
      final right = _parseTypeExpr(isLocal: true);
      left = BinaryExpr(left, opLexeme, right,
          source: currentSource,
          line: left.line,
          column: left.column,
          offset: left.offset,
          length: curTok.offset - left.offset);
    }
    return left;
  }

  /// Add: +, -, precedence 13, associativity left
  ASTNode _parseAdditiveExpr() {
    var left = _parseMultiplicativeExpr();
    if (lexicon.additives.contains(curTok.type)) {
      leftValueLegality = false;
      while (lexicon.additives.contains(curTok.type)) {
        final op = advance();
        final right = _parseMultiplicativeExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: currentSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// Multiply *, /, ~/, %, precedence 14, associativity left
  ASTNode _parseMultiplicativeExpr() {
    var left = _parseUnaryPrefixExpr();
    if (lexicon.multiplicatives.contains(curTok.type)) {
      leftValueLegality = false;
      while (lexicon.multiplicatives.contains(curTok.type)) {
        final op = advance();
        final right = _parseUnaryPrefixExpr();
        left = BinaryExpr(left, op.lexeme, right,
            source: currentSource,
            line: left.line,
            column: left.column,
            offset: left.offset,
            length: curTok.offset - left.offset);
      }
    }
    return left;
  }

  /// Prefix -e, !e，++e, --e, precedence 15, associativity none
  ASTNode _parseUnaryPrefixExpr() {
    if (!(lexicon.unaryPrefixs.contains(curTok.type))) {
      return _parseUnaryPostfixExpr();
    } else {
      final op = advance();
      final value = _parseUnaryPostfixExpr();
      if (lexicon.unaryPrefixsOnLeftValue.contains(op.type)) {
        if (!leftValueLegality) {
          final err = HTError.invalidLeftValue(
              filename: currrentFileName,
              line: value.line,
              column: value.column,
              offset: value.offset,
              length: value.length);
          errors?.add(err);
        }
      }
      return UnaryPrefixExpr(op.lexeme, value,
          source: currentSource,
          line: op.line,
          column: op.column,
          offset: op.offset,
          length: curTok.offset - op.offset);
    }
  }

  /// Postfix e., e?., e[], e?[], e(), e?(), e++, e-- precedence 16, associativity right
  ASTNode _parseUnaryPostfixExpr() {
    var expr = _parsePrimaryExpr();
    while (lexicon.unaryPostfixs.contains(curTok.type)) {
      final op = advance();
      if (op.type == lexicon.memberGet) {
        var isNullable = false;
        if ((expr is MemberExpr && expr.isNullable) ||
            (expr is SubExpr && expr.isNullable) ||
            (expr is CallExpr && expr.isNullable)) {
          isNullable = true;
        }
        leftValueLegality = true;
        final name = match(Semantic.identifier);
        final key = IdentifierExpr(name.lexeme,
            isLocal: false,
            source: currentSource,
            line: name.line,
            column: name.column,
            offset: name.offset,
            length: name.length);
        expr = MemberExpr(expr, key,
            isNullable: isNullable,
            source: currentSource,
            line: expr.line,
            column: expr.column,
            offset: expr.offset,
            length: curTok.offset - expr.offset);
      } else if (op.type == lexicon.nullableMemberGet) {
        leftValueLegality = false;
        final name = match(Semantic.identifier);
        final key = IdentifierExpr(name.lexeme,
            isLocal: false,
            source: currentSource,
            line: name.line,
            column: name.column,
            offset: name.offset,
            length: name.length);
        expr = MemberExpr(expr, key,
            isNullable: true,
            source: currentSource,
            line: expr.line,
            column: expr.column,
            offset: expr.offset,
            length: curTok.offset - expr.offset);
      } else if (op.type == lexicon.subGetStart) {
        var isNullable = false;
        if ((expr is MemberExpr && expr.isNullable) ||
            (expr is SubExpr && expr.isNullable) ||
            (expr is CallExpr && expr.isNullable)) {
          isNullable = true;
        }
        var indexExpr = _parseExpr();
        leftValueLegality = true;
        match(lexicon.listEnd);
        expr = SubExpr(expr, indexExpr,
            isNullable: isNullable,
            source: currentSource,
            line: expr.line,
            column: expr.column,
            offset: expr.offset,
            length: curTok.offset - expr.offset);
      } else if (op.type == lexicon.nullableSubGet) {
        var indexExpr = _parseExpr();
        leftValueLegality = true;
        match(lexicon.listEnd);
        expr = SubExpr(expr, indexExpr,
            isNullable: true,
            source: currentSource,
            line: expr.line,
            column: expr.column,
            offset: expr.offset,
            length: curTok.offset - expr.offset);
      } else if (op.type == lexicon.nullableFunctionArgumentCall) {
        leftValueLegality = false;
        var positionalArgs = <ASTNode>[];
        var namedArgs = <String, ASTNode>{};
        _handleCallArguments(positionalArgs, namedArgs);
        expr = CallExpr(expr,
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            isNullable: true,
            source: currentSource,
            line: expr.line,
            column: expr.column,
            offset: expr.offset,
            length: curTok.offset - expr.offset);
      } else if (op.type == lexicon.functionArgumentStart) {
        var isNullable = false;
        if ((expr is MemberExpr && expr.isNullable) ||
            (expr is SubExpr && expr.isNullable) ||
            (expr is CallExpr && expr.isNullable)) {
          isNullable = true;
        }
        leftValueLegality = false;
        var positionalArgs = <ASTNode>[];
        var namedArgs = <String, ASTNode>{};
        _handleCallArguments(positionalArgs, namedArgs);
        expr = CallExpr(expr,
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            isNullable: isNullable,
            source: currentSource,
            line: expr.line,
            column: expr.column,
            offset: expr.offset,
            length: curTok.offset - expr.offset);
      } else if (op.type == lexicon.postIncrement ||
          op.type == lexicon.postDecrement) {
        leftValueLegality = false;
        expr = UnaryPostfixExpr(expr, op.lexeme,
            source: currentSource,
            line: expr.line,
            column: expr.column,
            offset: expr.offset,
            length: curTok.offset - expr.offset);
      }
    }
    return expr;
  }

  /// Expression without associativity
  ASTNode _parsePrimaryExpr() {
    // Don't use if else here because those token types might be same,
    // for example, functionArgumentStart & groupExprStart are both '('.

    if (curTok.type == lexicon.kNull) {
      final token = advance();
      leftValueLegality = false;
      return ASTLiteralNull(
          source: currentSource,
          line: token.line,
          column: token.column,
          offset: token.offset,
          length: token.length);
    }

    if (curTok.type == Semantic.literalBoolean) {
      final token = match(Semantic.literalBoolean) as TokenBooleanLiteral;
      leftValueLegality = false;
      return ASTLiteralBoolean(token.literal,
          source: currentSource,
          line: token.line,
          column: token.column,
          offset: token.offset,
          length: token.length);
    }

    if (curTok.type == Semantic.literalInteger) {
      final token = match(Semantic.literalInteger) as TokenIntLiteral;
      leftValueLegality = false;
      return ASTLiteralInteger(token.literal,
          source: currentSource,
          line: token.line,
          column: token.column,
          offset: token.offset,
          length: token.length);
    }

    if (curTok.type == Semantic.literalFloat) {
      final token = advance() as TokenFloatLiteral;
      leftValueLegality = false;
      return ASTLiteralFloat(token.literal,
          source: currentSource,
          line: token.line,
          column: token.column,
          offset: token.offset,
          length: token.length);
    }

    if (curTok.type == Semantic.literalString) {
      final token = advance() as TokenStringLiteral;
      leftValueLegality = false;
      return ASTLiteralString(token.literal, token.startMark, token.endMark,
          source: currentSource,
          line: token.line,
          column: token.column,
          offset: token.offset,
          length: token.length);
    }

    if (curTok.type == Semantic.literalStringInterpolation) {
      final token = advance() as TokenStringInterpolation;
      final interpolations = <ASTNode>[];
      final savedCurrent = curTok;
      final savedFirst = firstTok;
      final savedEnd = endOfFile;
      final savedLine = line;
      final savedColumn = column;
      for (final token in token.interpolations) {
        final nodes = parseToken(token,
            source: currentSource, style: ParseStyle.expression);
        ASTNode? expr;
        for (final node in nodes) {
          if (node is ASTEmptyLine) continue;
          if (expr == null) {
            expr = node;
          } else {
            final err = HTError.stringInterpolation(
                filename: currrentFileName,
                line: node.line,
                column: node.column,
                offset: node.offset,
                length: node.length);
            errors?.add(err);
            break;
          }
        }
        if (expr != null) {
          interpolations.add(expr);
        } else {
          // parser will always contain at least a empty line expr
          interpolations.add(nodes.first);
        }
      }
      curTok = savedCurrent;
      firstTok = savedFirst;
      endOfFile = savedEnd;
      line = savedLine;
      column = savedColumn;
      var i = 0;
      final text = token.literal.replaceAllMapped(
          RegExp(lexicon.stringInterpolationPattern),
          (Match m) =>
              '${lexicon.stringInterpolationStart}${i++}${lexicon.stringInterpolationEnd}');
      leftValueLegality = false;
      return ASTStringInterpolation(
          text, token.startMark, token.endMark, interpolations,
          source: currentSource,
          line: token.line,
          column: token.column,
          offset: token.offset,
          length: token.length);
    }

    if (curTok.type == lexicon.kThis) {
      final keyword = advance();
      leftValueLegality = false;
      return IdentifierExpr(keyword.lexeme,
          source: currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: keyword.length);
    }

    if (curTok.type == lexicon.kSuper) {
      final keyword = advance();
      leftValueLegality = false;
      return IdentifierExpr(keyword.lexeme,
          source: currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: keyword.length);
    }

    if (curTok.type == lexicon.kNew) {
      final keyword = advance();
      leftValueLegality = false;
      final idTok = match(Semantic.identifier) as TokenIdentifier;
      final id = IdentifierExpr.fromToken(idTok,
          isMarked: idTok.isMarked, source: currentSource);
      var positionalArgs = <ASTNode>[];
      var namedArgs = <String, ASTNode>{};
      if (expect([lexicon.functionArgumentStart], consume: true)) {
        _handleCallArguments(positionalArgs, namedArgs);
      }
      return CallExpr(id,
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          hasNewOperator: true,
          source: currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    }

    if (curTok.type == lexicon.kIf) {
      leftValueLegality = false;
      return _parseIf(isExpression: true);
    }

    if (curTok.type == lexicon.kWhen) {
      leftValueLegality = false;
      return _parseWhen(isExpression: true);
    }
    // a literal function expression
    if (curTok.type == lexicon.functionArgumentStart) {
      final tokenAfterGroupExprStart = curTok.next;
      final tokenAfterGroupExprEnd = seekGroupClosing(
          {lexicon.functionArgumentStart: lexicon.functionArgumentEnd});
      if ((tokenAfterGroupExprStart?.type == lexicon.groupExprEnd ||
              (tokenAfterGroupExprStart?.type == Semantic.identifier &&
                  (tokenAfterGroupExprStart?.next?.type == lexicon.comma ||
                      tokenAfterGroupExprStart?.next?.type ==
                          lexicon.typeIndicator ||
                      tokenAfterGroupExprStart?.next?.type ==
                          lexicon.groupExprEnd))) &&
          (tokenAfterGroupExprEnd.type == lexicon.functionBlockStart ||
              tokenAfterGroupExprEnd.type ==
                  lexicon.functionSingleLineBodyIndicator)) {
        leftValueLegality = false;
        return _parseFunction(
            category: FunctionCategory.literal, hasKeyword: false);
      }
    }

    if (curTok.type == lexicon.groupExprStart) {
      final start = advance();
      final innerExpr = _parseExpr();
      final end = match(lexicon.groupExprEnd);
      leftValueLegality = false;
      return GroupExpr(innerExpr,
          source: currentSource,
          line: start.line,
          column: start.column,
          offset: start.offset,
          length: end.offset + end.length - start.offset);
    }

    if (curTok.type == lexicon.listStart) {
      final start = advance();
      final listExpr = <ASTNode>[];
      while (
          curTok.type != lexicon.listEnd && curTok.type != Semantic.endOfFile) {
        ASTNode item;
        if (curTok.type == lexicon.spreadSyntax) {
          final spreadTok = advance();
          item = _parseExpr();
          listExpr.add(SpreadExpr(item,
              source: currentSource,
              line: spreadTok.line,
              column: spreadTok.column,
              offset: spreadTok.offset,
              length: item.end - spreadTok.offset));
        } else {
          item = _parseExpr();
          listExpr.add(item);
        }
        if (curTok.type != lexicon.listEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(item);
      }
      final end = match(lexicon.listEnd);
      leftValueLegality = false;
      return ListExpr(listExpr,
          source: currentSource,
          line: start.line,
          column: start.column,
          offset: start.offset,
          length: end.end - start.offset);
    }

    if (curTok.type == lexicon.functionBlockStart) {
      leftValueLegality = false;
      return _parseStructObj();
    }

    if (curTok.type == lexicon.kStruct) {
      leftValueLegality = false;
      return _parseStructObj(hasKeyword: true);
    }

    if (curTok.type == lexicon.kFun) {
      leftValueLegality = false;
      return _parseFunction(category: FunctionCategory.literal);
    }

    if (curTok.type == Semantic.identifier) {
      final id = advance() as TokenIdentifier;
      final isLocal = curTok.type != lexicon.assign;
      // TODO: type arguments
      leftValueLegality = true;
      return IdentifierExpr.fromToken(id,
          isMarked: id.isMarked, isLocal: isLocal, source: currentSource);
    }

    final err = HTError.unexpected(
        Semantic.expression, Semantic.expression, curTok.lexeme,
        filename: currrentFileName,
        line: curTok.line,
        column: curTok.column,
        offset: curTok.offset,
        length: curTok.length);
    errors?.add(err);
    final errToken = advance();
    return ASTEmptyLine(
        source: currentSource,
        line: errToken.line,
        column: errToken.column,
        offset: errToken.offset);
  }

  CommaExpr _handleCommaExpr(String endMark, {bool isLocal = true}) {
    final list = <ASTNode>[];
    while (curTok.type != endMark && curTok.type != Semantic.endOfFile) {
      if (list.isNotEmpty) {
        match(lexicon.comma);
      }
      final item = _parseExpr();
      _handleTrailingComment(item);
      list.add(item);
    }
    return CommaExpr(list,
        isLocal: isLocal,
        source: currentSource,
        line: list.first.line,
        column: list.first.column,
        offset: list.first.offset,
        length: curTok.offset - list.first.offset);
  }

  InOfExpr _handleInOfExpr() {
    final opTok = advance();
    final collection = _parseExpr();
    return InOfExpr(collection, opTok.lexeme == lexicon.kOf ? true : false,
        line: collection.line,
        column: collection.column,
        offset: collection.offset,
        length: curTok.offset - collection.offset);
  }

  TypeExpr _parseTypeExpr({bool isLocal = false}) {
    // function type
    if (curTok.type == lexicon.groupExprStart) {
      final startTok = advance();
      // TODO: generic parameters
      final parameters = <ParamTypeExpr>[];
      var isOptional = false;
      var isNamed = false;
      var isVariadic = false;
      while (curTok.type != lexicon.groupExprEnd &&
          curTok.type != Semantic.endOfFile) {
        final start = curTok;
        if (!isOptional) {
          isOptional = expect([lexicon.listStart], consume: true);
          if (!isOptional && !isNamed) {
            isNamed = expect([lexicon.functionBlockStart], consume: true);
          }
        }
        late final TypeExpr paramType;
        IdentifierExpr? paramSymbol;
        if (!isNamed) {
          isVariadic = expect([lexicon.variadicArgs], consume: true);
        } else {
          final paramId = match(Semantic.identifier);
          paramSymbol =
              IdentifierExpr.fromToken(paramId, source: currentSource);
          match(lexicon.typeIndicator);
        }
        paramType = _parseTypeExpr();
        final param = ParamTypeExpr(paramType,
            isOptional: isOptional,
            isVariadic: isVariadic,
            id: paramSymbol,
            source: currentSource,
            line: start.line,
            column: start.column,
            offset: start.offset,
            length: curTok.offset - start.offset);
        if (isOptional && expect([lexicon.listEnd], consume: true)) {
          break;
        } else if (isNamed &&
            expect([lexicon.functionBlockEnd], consume: true)) {
          break;
        } else if (curTok.type != lexicon.groupExprEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(param);
        parameters.add(param);
        if (isVariadic) {
          break;
        }
      }
      match(lexicon.groupExprEnd);
      match(lexicon.functionReturnTypeIndicator);
      final returnType = _parseTypeExpr();
      return FuncTypeExpr(returnType,
          isLocal: isLocal,
          paramTypes: parameters,
          hasOptionalParam: isOptional,
          hasNamedParam: isNamed,
          source: currentSource,
          line: startTok.line,
          column: startTok.column,
          offset: startTok.offset,
          length: curTok.offset - startTok.offset);
    }
    // structural type (interface of struct)
    else if (curTok.type == lexicon.structStart) {
      final startTok = advance();
      final fieldTypes = <FieldTypeExpr>[];
      while (curTok.type != lexicon.functionBlockEnd &&
          curTok.type != Semantic.endOfFile) {
        _handlePrecedingComment();
        late Token idTok;
        if (curTok.type == Semantic.literalString) {
          idTok = advance();
        } else {
          idTok = match(Semantic.identifier);
        }
        match(lexicon.typeIndicator);
        final typeExpr = _parseTypeExpr();
        fieldTypes.add(FieldTypeExpr(idTok.literal, typeExpr));
        expect([lexicon.comma], consume: true);
      }
      match(lexicon.functionBlockEnd);
      return StructuralTypeExpr(
        fieldTypes: fieldTypes,
        isLocal: isLocal,
        source: currentSource,
        line: startTok.line,
        column: startTok.column,
        length: curTok.offset - startTok.offset,
      );
    }
    // nominal type (class)
    else {
      final idTok = match(Semantic.identifier);
      final id = IdentifierExpr.fromToken(idTok, source: currentSource);
      PrimitiveTypeCategory category = PrimitiveTypeCategory.none;
      if (id.id == lexicon.typeAny) {
        category = PrimitiveTypeCategory.any;
      } else if (id.id == lexicon.typeUnknown) {
        category = PrimitiveTypeCategory.unknown;
      } else if (id.id == lexicon.typeVoid) {
        category = PrimitiveTypeCategory.vo1d;
      } else if (id.id == lexicon.typeNever) {
        category = PrimitiveTypeCategory.never;
      }
      final typeArgs = <TypeExpr>[];
      if (expect([lexicon.typeParameterStart], consume: true)) {
        if (curTok.type == lexicon.typeParameterEnd) {
          final err = HTError.emptyTypeArgs(
              filename: currrentFileName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.end - idTok.offset);
          errors?.add(err);
        }
        while ((curTok.type != lexicon.typeParameterEnd) &&
            (curTok.type != Semantic.endOfFile)) {
          final typeArg = _parseTypeExpr();
          expect([lexicon.comma], consume: true);
          _handleTrailingComment(typeArg);
          typeArgs.add(typeArg);
        }
        match(lexicon.typeParameterEnd);
      }
      final isNullable = expect([lexicon.nullableTypePostfix], consume: true);
      return TypeExpr(
        id: id,
        arguments: typeArgs,
        isNullable: isNullable,
        isLocal: isLocal,
        primitiveTypeCategory: category,
        source: currentSource,
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
    final startTok = match(lexicon.functionBlockStart);
    final statements = <ASTNode>[];
    while (curTok.type != lexicon.functionBlockEnd &&
        curTok.type != Semantic.endOfFile) {
      final stmt = parseStmt(style: sourceType);
      if (stmt != null) {
        statements.add(stmt);
      }
    }
    final endTok = match(lexicon.functionBlockEnd);
    if (statements.isEmpty) {
      final empty = ASTEmptyLine(
          source: currentSource,
          line: endTok.line,
          column: endTok.column,
          offset: endTok.offset,
          length: endTok.offset - startTok.end);
      empty.precedingComments = currentPrecedingComments;
      currentPrecedingComments = [];
      statements.add(empty);
    }

    return BlockStmt(statements,
        id: id,
        hasOwnNamespace: hasOwnNamespace,
        source: currentSource,
        line: startTok.line,
        column: startTok.column,
        offset: startTok.offset,
        length: curTok.offset - startTok.offset);
  }

  void _handleCallArguments(
      List<ASTNode> positionalArgs, Map<String, ASTNode> namedArgs) {
    var isNamed = false;
    while ((curTok.type != lexicon.groupExprEnd) &&
        (curTok.type != Semantic.endOfFile)) {
      if ((!isNamed &&
              expect([Semantic.identifier, lexicon.namedArgumentValueIndicator],
                  consume: false)) ||
          isNamed) {
        isNamed = true;
        final name = match(Semantic.identifier).lexeme;
        match(lexicon.namedArgumentValueIndicator);
        final namedArg = _parseExpr();
        if (curTok.type != lexicon.groupExprEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(namedArg);
        namedArgs[name] = namedArg;
      } else {
        late ASTNode positionalArg;
        if (curTok.type == lexicon.spreadSyntax) {
          final spreadTok = advance();
          final spread = _parseExpr();
          positionalArg = SpreadExpr(spread,
              source: currentSource,
              line: spreadTok.line,
              column: spreadTok.column,
              offset: spreadTok.offset,
              length: spread.end - spreadTok.offset);
        } else {
          positionalArg = _parseExpr();
        }
        if (curTok.type != lexicon.groupExprEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(positionalArg);
        positionalArgs.add(positionalArg);
      }
    }
    match(lexicon.functionArgumentEnd);
  }

  ASTNode _parseExprStmt() {
    if (curTok.type == lexicon.endOfStatementMark) {
      final empty = advance();
      final stmt = ASTEmptyLine(
          hasEndOfStmtMark: true,
          source: currentSource,
          line: empty.line,
          column: empty.column,
          offset: empty.offset,
          length: curTok.offset - empty.offset);
      return stmt;
    } else {
      final expr = _parseExpr();
      final hasEndOfStmtMark =
          expect([lexicon.endOfStatementMark], consume: true);
      final stmt = ExprStmt(expr,
          hasEndOfStmtMark: hasEndOfStmtMark,
          source: currentSource,
          line: expr.line,
          column: expr.column,
          offset: expr.offset,
          length: curTok.offset - expr.offset);
      return stmt;
    }
  }

  ReturnStmt _parseReturnStmt() {
    var keyword = advance();
    ASTNode? expr;
    if (curTok.type != lexicon.functionBlockEnd &&
        curTok.type != lexicon.endOfStatementMark &&
        curTok.type != Semantic.endOfFile) {
      expr = _parseExpr();
    }
    final hasEndOfStmtMark =
        expect([lexicon.endOfStatementMark], consume: true);
    return ReturnStmt(keyword,
        returnValue: expr,
        source: currentSource,
        hasEndOfStmtMark: hasEndOfStmtMark,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  ASTNode _parseExprOrStmtOrBlock({bool isExpression = false}) {
    if (curTok.type == lexicon.functionBlockStart) {
      return _parseBlockStmt(id: Semantic.elseBranch);
    } else {
      if (isExpression) {
        return _parseExpr();
      } else {
        final startTok = curTok;
        var node = parseStmt(style: ParseStyle.functionDefinition);
        if (node == null) {
          final err = HTError.unexpected(
              Semantic.exprStmt, Semantic.expression, curTok.lexeme,
              filename: currrentFileName,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.length);
          errors?.add(err);
          node = ASTEmptyLine(
              source: currentSource,
              line: curTok.line,
              column: curTok.column,
              offset: curTok.offset,
              length: curTok.offset - startTok.offset);
          node.precedingComments.addAll(currentPrecedingComments);
          currentPrecedingComments.clear();
        }
        return node;
      }
    }
  }

  IfStmt _parseIf({bool isExpression = false}) {
    final keyword = match(lexicon.kIf);
    match(lexicon.groupExprStart);
    final condition = _parseExpr();
    match(lexicon.groupExprEnd);
    var thenBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
    _handlePrecedingComment();
    ASTNode? elseBranch;
    if (isExpression) {
      match(lexicon.kElse);
      elseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
    } else {
      if (expect([lexicon.kElse], consume: true)) {
        elseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
      }
    }
    return IfStmt(condition, thenBranch,
        isExpression: isExpression,
        elseBranch: elseBranch,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  WhileStmt _parseWhileStmt() {
    final keyword = match(lexicon.kWhile);
    match(lexicon.groupExprStart);
    final condition = _parseExpr();
    match(lexicon.groupExprEnd);
    final loop = _parseBlockStmt(id: Semantic.whileLoop);
    return WhileStmt(condition, loop,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  DoStmt _parseDoStmt() {
    final keyword = advance();
    final loop = _parseBlockStmt(id: Semantic.doLoop);
    ASTNode? condition;
    if (expect([lexicon.kWhile], consume: true)) {
      match(lexicon.groupExprStart);
      condition = _parseExpr();
      match(lexicon.groupExprEnd);
    }
    final hasEndOfStmtMark =
        expect([lexicon.endOfStatementMark], consume: true);
    return DoStmt(loop, condition,
        hasEndOfStmtMark: hasEndOfStmtMark,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  ASTNode _parseForStmt() {
    final keyword = advance();
    final hasBracket = expect([lexicon.groupExprStart], consume: true);
    final forStmtType = peek(2).lexeme;
    VarDecl? decl;
    ASTNode? condition;
    ASTNode? increment;
    if (forStmtType == lexicon.kIn || forStmtType == lexicon.kOf) {
      if (!lexicon.forDeclarationKeywords.contains(curTok.type)) {
        final err = HTError.unexpected(
            Semantic.forStmt, Semantic.variableDeclaration, curTok.type,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
      }
      decl = _parseVarDecl(
          // typeInferrence: curTok.type != lexicon.VAR,
          isMutable: curTok.type != lexicon.kFinal);
      advance();
      final collection = _parseExpr();
      if (hasBracket) {
        match(lexicon.groupExprEnd);
      }
      final loop = _parseBlockStmt(id: Semantic.forLoop);
      return ForRangeStmt(decl, collection, loop,
          hasBracket: hasBracket,
          iterateValue: forStmtType == lexicon.kOf,
          source: currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    } else {
      if (!expect([lexicon.endOfStatementMark], consume: false)) {
        decl = _parseVarDecl(
            // typeInferrence: curTok.type != lexicon.VAR,
            isMutable: curTok.type != lexicon.kFinal,
            hasEndOfStatement: true);
      } else {
        match(lexicon.endOfStatementMark);
      }
      if (!expect([lexicon.endOfStatementMark], consume: false)) {
        condition = _parseExpr();
      }
      match(lexicon.endOfStatementMark);
      if (!expect([lexicon.groupExprEnd], consume: false)) {
        increment = _parseExpr();
      }
      if (hasBracket) {
        match(lexicon.groupExprEnd);
      }
      final loop = _parseBlockStmt(id: Semantic.forLoop);
      return ForStmt(decl, condition, increment, loop,
          hasBracket: hasBracket,
          source: currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    }
  }

  WhenStmt _parseWhen({bool isExpression = false}) {
    final keyword = advance();
    ASTNode? condition;
    if (curTok.type != lexicon.functionBlockStart) {
      match(lexicon.groupExprStart);
      condition = _parseExpr();
      match(lexicon.groupExprEnd);
    }
    final options = <ASTNode, ASTNode>{};
    ASTNode? elseBranch;
    match(lexicon.functionBlockStart);
    while (curTok.type != lexicon.functionBlockEnd &&
        curTok.type != Semantic.endOfFile) {
      _handlePrecedingComment();
      if (curTok.lexeme == lexicon.kElse) {
        advance();
        match(lexicon.whenBranchIndicator);
        elseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
      } else {
        ASTNode caseExpr;
        if (condition != null) {
          if (peek(1).type == lexicon.comma) {
            caseExpr =
                _handleCommaExpr(lexicon.whenBranchIndicator, isLocal: false);
          } else if (curTok.type == lexicon.kIn) {
            caseExpr = _handleInOfExpr();
          } else {
            caseExpr = _parseExpr();
          }
        } else {
          caseExpr = _parseExpr();
        }
        match(lexicon.whenBranchIndicator);
        var caseBranch = _parseExprOrStmtOrBlock(isExpression: isExpression);
        options[caseExpr] = caseBranch;
      }
    }
    match(lexicon.functionBlockEnd);
    return WhenStmt(options, elseBranch, condition,
        isExpression: isExpression,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  List<GenericTypeParameterExpr> _getGenericParams() {
    final genericParams = <GenericTypeParameterExpr>[];
    if (expect([lexicon.typeParameterStart], consume: true)) {
      while ((curTok.type != lexicon.typeParameterEnd) &&
          (curTok.type != Semantic.endOfFile)) {
        final idTok = match(Semantic.identifier);
        final id = IdentifierExpr.fromToken(idTok, source: currentSource);
        final param = GenericTypeParameterExpr(id,
            source: currentSource,
            line: idTok.line,
            column: idTok.column,
            offset: idTok.offset,
            length: curTok.offset - idTok.offset);
        if (curTok.type != lexicon.typeParameterEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(param);
        genericParams.add(param);
      }
      match(lexicon.typeParameterEnd);
    }
    return genericParams;
  }

  ImportExportDecl _parseImportDecl() {
    // TODO: duplicate import and self import error.
    final keyword = advance(); // not a keyword so don't use match
    final showList = <IdentifierExpr>[];
    if (curTok.type == lexicon.functionBlockStart) {
      advance();
      if (curTok.type == lexicon.functionBlockEnd) {
        final err = HTError.emptyImportList(
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.end - keyword.offset);
        errors?.add(err);
      }
      while (curTok.type != lexicon.functionBlockEnd &&
          curTok.type != Semantic.endOfFile) {
        _handlePrecedingComment();
        final idTok = match(Semantic.identifier);
        final id = IdentifierExpr.fromToken(idTok, source: currentSource);
        if (curTok.type != lexicon.functionBlockEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(id);
        showList.add(id);
      }
      match(lexicon.functionBlockEnd);
      // check lexeme here because expect() can only deal with token type
      final fromKeyword = advance().lexeme;
      if (fromKeyword != lexicon.kFrom) {
        final err = HTError.unexpected(
            Semantic.importStmt, lexicon.kFrom, curTok.lexeme,
            filename: currrentFileName,
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
      alias = IdentifierExpr.fromToken(aliasId, source: currentSource);
      hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
    }

    final fromPathTok = match(Semantic.literalString);
    String fromPathRaw = fromPathTok.literal;
    String fromPath;
    bool isPreloadedModule = false;
    if (fromPathRaw.startsWith(HTResourceContext.hetuPreloadedModulesPrefix)) {
      isPreloadedModule = true;
      fromPath = fromPathRaw
          .substring(HTResourceContext.hetuPreloadedModulesPrefix.length);
      hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
    } else {
      fromPath = fromPathRaw;
      final ext = path.extension(fromPathTok.lexeme);
      if (ext != HTResource.hetuModule && ext != HTResource.hetuScript) {
        if (showList.isNotEmpty) {
          final err = HTError.importListOnNonHetuSource(
              filename: currrentFileName,
              line: fromPathTok.line,
              column: fromPathTok.column,
              offset: fromPathTok.offset,
              length: fromPathTok.length);
          errors?.add(err);
        }
        match(lexicon.kAs);
        _handleAlias();
      } else {
        hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
        if (!hasEndOfStmtMark && expect([lexicon.kAs], consume: true)) {
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
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
    currentModuleImports.add(stmt);
    expect([lexicon.endOfStatementMark], consume: true);
    return stmt;
  }

  ImportExportDecl _parseExportStmt() {
    final keyword = advance(); // not a keyword so don't use match
    late final ImportExportDecl stmt;
    // export some of the symbols from this or other source
    if (curTok.type == lexicon.functionBlockStart) {
      advance();
      final showList = <IdentifierExpr>[];
      while (curTok.type != lexicon.functionBlockEnd &&
          curTok.type != Semantic.endOfFile) {
        _handlePrecedingComment();
        final idTok = match(Semantic.identifier);
        final id = IdentifierExpr.fromToken(idTok, source: currentSource);
        if (curTok.type != lexicon.functionBlockEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(id);
        showList.add(id);
      }
      match(lexicon.functionBlockEnd);
      String? fromPath;
      var hasEndOfStmtMark =
          expect([lexicon.endOfStatementMark], consume: true);
      if (!hasEndOfStmtMark && curTok.lexeme == lexicon.kFrom) {
        advance();
        final fromPathTok = match(Semantic.literalString);
        final ext = path.extension(fromPathTok.literal);
        if (ext != HTResource.hetuModule && ext != HTResource.hetuScript) {
          final err = HTError.importListOnNonHetuSource(
              filename: currrentFileName,
              line: fromPathTok.line,
              column: fromPathTok.column,
              offset: fromPathTok.offset,
              length: fromPathTok.length);
          errors?.add(err);
        }
        hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
      }
      stmt = ImportExportDecl(
          fromPath: fromPath,
          showList: showList,
          hasEndOfStmtMark: hasEndOfStmtMark,
          isExport: true,
          source: currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
      if (fromPath != null) {
        currentModuleImports.add(stmt);
      }
    }
    // export all of the symbols from other source
    else {
      final key = match(Semantic.literalString);
      final hasEndOfStmtMark =
          expect([lexicon.endOfStatementMark], consume: true);
      stmt = ImportExportDecl(
          fromPath: key.literal,
          hasEndOfStmtMark: hasEndOfStmtMark,
          isExport: true,
          source: currentSource,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
      currentModuleImports.add(stmt);
    }
    return stmt;
  }

  ASTNode _parseDeleteStmt() {
    var keyword = advance();
    final nextTok = peek(1);
    if (curTok.type == Semantic.identifier &&
        nextTok.type != lexicon.memberGet &&
        nextTok.type != lexicon.subGetStart) {
      final id = advance().lexeme;
      final hasEndOfStmtMark =
          expect([lexicon.endOfStatementMark], consume: true);
      return DeleteStmt(id,
          source: currentSource,
          hasEndOfStmtMark: hasEndOfStmtMark,
          line: keyword.line,
          column: keyword.column,
          offset: keyword.offset,
          length: curTok.offset - keyword.offset);
    } else {
      final expr = _parseExpr();
      final hasEndOfStmtMark =
          expect([lexicon.endOfStatementMark], consume: true);
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
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
        final empty = ASTEmptyLine(
            source: currentSource,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: curTok.offset - keyword.offset);
        return empty;
      }
    }
  }

  NamespaceDecl _parseNamespaceDecl({bool isTopLevel = false}) {
    final keyword = match(lexicon.kNamespace);
    final idTok = match(Semantic.identifier);
    final id = IdentifierExpr.fromToken(idTok, source: currentSource);
    final definition = _parseBlockStmt(
        id: id.id, sourceType: ParseStyle.module, hasOwnNamespace: false);
    return NamespaceDecl(
      id,
      definition,
      classId: currentClass?.id,
      isTopLevel: isTopLevel,
      source: currentSource,
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
    final id = IdentifierExpr.fromToken(idTok, source: currentSource);
    final genericParameters = _getGenericParams();
    match(lexicon.assign);
    final value = _parseTypeExpr();
    return TypeAliasDecl(id, value,
        classId: classId,
        genericTypeParameters: genericParameters,
        isTopLevel: isTopLevel,
        source: currentSource,
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
      ASTNode? additionalInitializer,
      bool hasEndOfStatement = false}) {
    final keyword = advance();
    final idTok = match(Semantic.identifier);
    final id = IdentifierExpr.fromToken(idTok, source: currentSource);
    String? internalName;
    if (classId != null && isExternal) {
      // if (!(currentClass!.isExternal) && !isStatic) {
      //   final err = HTError.externalMember(
      //       filename: currrentFileName,
      //       line: keyword.line,
      //       column: keyword.column,
      //       offset: curTok.offset,
      //       length: curTok.length);
      //   errors?.add(err);
      // }
      internalName = '$classId.${idTok.lexeme}';
    }
    TypeExpr? declType;
    if (expect([lexicon.typeIndicator], consume: true)) {
      declType = _parseTypeExpr();
    }
    ASTNode? initializer;
    if (!lateFinalize) {
      if (isConst) {
        match(lexicon.assign);
        initializer = _parseExpr();
      } else {
        if (expect([lexicon.assign], consume: true)) {
          initializer = _parseExpr();
        } else {
          initializer = additionalInitializer;
        }
      }
    }
    bool hasEndOfStmtMark = hasEndOfStatement;
    if (hasEndOfStatement) {
      match(lexicon.endOfStatementMark);
    } else {
      hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
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
        source: currentSource,
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
    if (peek(-1).type == lexicon.listStart) {
      endMark = lexicon.listEnd;
      isVector = true;
    } else {
      endMark = lexicon.functionBlockEnd;
    }
    while (curTok.type != endMark && curTok.type != Semantic.endOfFile) {
      _handlePrecedingComment();
      final idTok = match(Semantic.identifier);
      final id = IdentifierExpr.fromToken(idTok, source: currentSource);
      TypeExpr? declType;
      if (expect([lexicon.typeIndicator], consume: true)) {
        declType = _parseTypeExpr();
      }
      if (curTok.type != endMark) {
        match(lexicon.comma);
      }
      if (declType == null) {
        _handleTrailingComment(id);
      } else {
        _handleTrailingComment(declType);
      }
      ids[id] = declType;
    }
    match(endMark);
    match(lexicon.assign);
    final initializer = _parseExpr();
    bool hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
    return DestructuringDecl(
        ids: ids,
        isVector: isVector,
        initializer: initializer,
        hasEndOfStmtMark: hasEndOfStmtMark,
        isMutable: isMutable,
        source: currentSource,
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
    final savedCurFuncType = currentFunctionCategory;
    currentFunctionCategory = category;
    late Token startTok;
    String? externalTypedef;
    if (category != FunctionCategory.literal || hasKeyword) {
      // there are multiple keyword for function, so don't use match here.
      startTok = advance();
      if (!isExternal &&
          (isStatic ||
              category == FunctionCategory.normal ||
              category == FunctionCategory.literal)) {
        if (expect([lexicon.listStart], consume: true)) {
          externalTypedef = match(Semantic.identifier).lexeme;
          match(lexicon.listEnd);
        }
      }
    }
    Token? id;
    late String internalName;
    // to distinguish getter and setter, and to give default constructor a name
    switch (category) {
      case FunctionCategory.factoryConstructor:
      case FunctionCategory.constructor:
        hasUserDefinedConstructor = true;
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
            ? '${InternalIdentifier.anonymousFunction}${HTParser.anonymousFunctionIndex++}'
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
        expect([lexicon.groupExprStart], consume: true)) {
      final startTok = curTok;
      hasParamDecls = true;
      var isOptional = false;
      var isNamed = false;
      var isVariadic = false;
      while ((curTok.type != lexicon.groupExprEnd) &&
          (curTok.type != lexicon.listEnd) &&
          (curTok.type != lexicon.functionBlockEnd) &&
          (curTok.type != Semantic.endOfFile)) {
        _handlePrecedingComment();
        // 可选参数, 根据是否有方括号判断, 一旦开始了可选参数, 则不再增加参数数量arity要求
        if (!isOptional) {
          isOptional = expect([lexicon.listStart], consume: true);
          if (!isOptional && !isNamed) {
            //检查命名参数, 根据是否有花括号判断
            isNamed = expect([lexicon.functionBlockStart], consume: true);
          }
        }
        if (!isNamed) {
          isVariadic = expect([lexicon.variadicArgs], consume: true);
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
            IdentifierExpr.fromToken(paramId, source: currentSource);
        TypeExpr? paramDeclType;
        if (expect([lexicon.typeIndicator], consume: true)) {
          paramDeclType = _parseTypeExpr();
        }
        ASTNode? initializer;
        if (expect([lexicon.assign], consume: true)) {
          if (isOptional || isNamed) {
            initializer = _parseExpr();
          } else {
            final lastTok = peek(-1);
            final err = HTError.argInit(
                filename: currrentFileName,
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
            source: currentSource,
            line: paramId.line,
            column: paramId.column,
            offset: paramId.offset,
            length: curTok.offset - paramId.offset);
        if (curTok.type != lexicon.listEnd &&
            curTok.type != lexicon.functionBlockEnd &&
            curTok.type != lexicon.groupExprEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(param);
        paramDecls.add(param);
        if (isVariadic) {
          isFuncVariadic = true;
          break;
        }
      }
      if (isOptional) {
        match(lexicon.listEnd);
      } else if (isNamed) {
        match(lexicon.functionBlockEnd);
      }

      final endTok = match(lexicon.groupExprEnd);

      // setter can only have one parameter
      if ((category == FunctionCategory.setter) && (minArity != 1)) {
        final err = HTError.setterArity(
            filename: currrentFileName,
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
    if (expect([lexicon.functionReturnTypeIndicator], consume: true)) {
      if (category == FunctionCategory.constructor ||
          category == FunctionCategory.setter) {
        final err = HTError.unexpected(
            Semantic.function, Semantic.functionDefinition, Semantic.returnType,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
      }
      returnType = _parseTypeExpr();
    }
    // referring to another constructor
    else if (expect([lexicon.constructorInitializationListIndicator],
        consume: true)) {
      if (category != FunctionCategory.constructor) {
        final lastTok = peek(-1);
        final err = HTError.unexpected(
            Semantic.function,
            lexicon.functionBlockStart,
            lexicon.constructorInitializationListIndicator,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: lastTok.offset,
            length: lastTok.length);
        errors?.add(err);
      }
      if (isExternal) {
        final lastTok = peek(-1);
        final err = HTError.externalCtorWithReferCtor(
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: lastTok.offset,
            length: lastTok.length);
        errors?.add(err);
      }
      final ctorCallee = advance();
      if (!lexicon.redirectingConstructorCallKeywords
          .contains(ctorCallee.lexeme)) {
        final err = HTError.unexpected(
            Semantic.function, Semantic.ctorCallExpr, curTok.lexeme,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: ctorCallee.offset,
            length: ctorCallee.length);
        errors?.add(err);
      }
      Token? ctorKey;
      if (expect([lexicon.memberGet], consume: true)) {
        ctorKey = match(Semantic.identifier);
        match(lexicon.groupExprStart);
      } else {
        match(lexicon.groupExprStart);
      }
      var positionalArgs = <ASTNode>[];
      var namedArgs = <String, ASTNode>{};
      _handleCallArguments(positionalArgs, namedArgs);
      referCtor = RedirectingConstructorCallExpr(
          IdentifierExpr.fromToken(ctorCallee, source: currentSource),
          positionalArgs,
          namedArgs,
          key: ctorKey != null
              ? IdentifierExpr.fromToken(ctorKey, source: currentSource)
              : null,
          source: currentSource,
          line: ctorCallee.line,
          column: ctorCallee.column,
          offset: ctorCallee.offset,
          length: curTok.offset - ctorCallee.offset);
    }
    bool isExpressionBody = false;
    bool hasEndOfStmtMark = false;
    ASTNode? definition;
    if (curTok.type == lexicon.functionBlockStart) {
      if (category == FunctionCategory.literal && !hasKeyword) {
        startTok = curTok;
      }
      definition = _parseBlockStmt(id: Semantic.functionCall);
    } else if (expect([lexicon.functionSingleLineBodyIndicator],
        consume: true)) {
      isExpressionBody = true;
      if (category == FunctionCategory.literal && !hasKeyword) {
        startTok = curTok;
      }
      definition = _parseExpr();
      hasEndOfStmtMark = expect([lexicon.endOfStatementMark], consume: true);
    } else if (expect([lexicon.assign], consume: true)) {
      final err = HTError.unsupported(Semantic.redirectingFunctionDefinition,
          filename: currrentFileName,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.length);
      errors?.add(err);
    } else {
      if (category != FunctionCategory.constructor &&
          category != FunctionCategory.literal &&
          !isExternal &&
          !(currentClass?.isAbstract ?? false)) {
        final err = HTError.missingFuncBody(internalName,
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
      }
      if (category != FunctionCategory.literal) {
        expect([lexicon.endOfStatementMark], consume: true);
      }
    }
    currentFunctionCategory = savedCurFuncType;
    return FuncDecl(internalName,
        id: id != null
            ? IdentifierExpr.fromToken(id, source: currentSource)
            : null,
        classId: classId,
        genericTypeParameters: genericParameters,
        externalTypeId: externalTypedef,
        redirectingCtorCallExpr: referCtor,
        hasParamDecls: hasParamDecls,
        paramDecls: paramDecls,
        returnType: returnType,
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
        source: currentSource,
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
    final keyword = match(lexicon.kClass);
    if (currentClass != null && currentClass!.isNested) {
      final err = HTError.nestedClass(
          filename: currrentFileName,
          line: curTok.line,
          column: curTok.column,
          offset: keyword.offset,
          length: keyword.length);
      errors?.add(err);
    }
    final id = match(Semantic.identifier);
    final genericParameters = _getGenericParams();
    TypeExpr? superClassType;
    if (curTok.lexeme == lexicon.kExtends) {
      advance();
      if (curTok.lexeme == id.lexeme) {
        final err = HTError.extendsSelf(
            filename: currrentFileName,
            line: curTok.line,
            column: curTok.column,
            offset: curTok.offset,
            length: curTok.length);
        errors?.add(err);
      }
      superClassType = _parseTypeExpr();
    }
    final savedClass = currentClass;
    currentClass = HTClassDeclaration(
        id: id.lexeme,
        classId: classId,
        isExternal: isExternal,
        isAbstract: isAbstract);
    final savedHasUsrDefCtor = hasUserDefinedConstructor;
    hasUserDefinedConstructor = false;
    final definition = _parseBlockStmt(
        sourceType: ParseStyle.classDefinition,
        hasOwnNamespace: false,
        id: Semantic.classDefinition);
    final decl = ClassDecl(
        IdentifierExpr.fromToken(id, source: currentSource), definition,
        genericTypeParameters: genericParameters,
        superType: superClassType,
        isExternal: isExternal,
        isAbstract: isAbstract,
        isTopLevel: isTopLevel,
        hasUserDefinedConstructor: hasUserDefinedConstructor,
        lateResolve: lateResolve,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
    hasUserDefinedConstructor = savedHasUsrDefCtor;
    currentClass = savedClass;
    return decl;
  }

  EnumDecl _parseEnumDecl({bool isExternal = false, bool isTopLevel = false}) {
    final keyword = match(lexicon.kEnum);
    final id = match(Semantic.identifier);
    var enumerations = <IdentifierExpr>[];
    if (expect([lexicon.functionBlockStart], consume: true)) {
      _handlePrecedingComment();
      while (curTok.type != lexicon.functionBlockEnd &&
          curTok.type != Semantic.endOfFile) {
        final enumIdTok = match(Semantic.identifier);
        final enumId =
            IdentifierExpr.fromToken(enumIdTok, source: currentSource);
        if (curTok.type != lexicon.functionBlockEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(enumId);
        enumerations.add(enumId);
      }
      match(lexicon.functionBlockEnd);
    } else {
      expect([lexicon.endOfStatementMark], consume: true);
    }
    return EnumDecl(
        IdentifierExpr.fromToken(id, source: currentSource), enumerations,
        isExternal: isExternal,
        isTopLevel: isTopLevel,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  StructDecl _parseStructDecl({bool isTopLevel = false}) {
    //, bool lateInitialize = true}) {
    final keyword = match(lexicon.kStruct);
    final idTok = match(Semantic.identifier);
    final id = IdentifierExpr.fromToken(idTok, source: currentSource);
    IdentifierExpr? prototypeId;
    if (expect([lexicon.kExtends], consume: true)) {
      final prototypeIdTok = match(Semantic.identifier);
      if (prototypeIdTok.lexeme == id.id) {
        final err = HTError.extendsSelf(
            filename: currrentFileName,
            line: keyword.line,
            column: keyword.column,
            offset: keyword.offset,
            length: keyword.length);
        errors?.add(err);
      }
      prototypeId =
          IdentifierExpr.fromToken(prototypeIdTok, source: currentSource);
    }
    final savedStructId = currentStructId;
    currentStructId = id.id;
    final definition = <ASTNode>[];
    final startTok = match(lexicon.functionBlockStart);
    while (curTok.type != lexicon.functionBlockEnd &&
        curTok.type != Semantic.endOfFile) {
      final stmt = parseStmt(style: ParseStyle.structDefinition);
      if (stmt != null) {
        definition.add(stmt);
      }
    }
    final endTok = match(lexicon.functionBlockEnd);
    if (definition.isEmpty) {
      final empty = ASTEmptyLine(
          source: currentSource,
          line: endTok.line,
          column: endTok.column,
          offset: endTok.offset,
          length: endTok.offset - startTok.end);
      empty.precedingComments.addAll(currentPrecedingComments);
      currentPrecedingComments.clear();
      definition.add(empty);
    }
    currentStructId = savedStructId;
    return StructDecl(id, definition,
        prototypeId: prototypeId,
        isTopLevel: isTopLevel,
        // lateInitialize: lateInitialize,
        source: currentSource,
        line: keyword.line,
        column: keyword.column,
        offset: keyword.offset,
        length: curTok.offset - keyword.offset);
  }

  StructObjExpr _parseStructObj({bool hasKeyword = false}) {
    IdentifierExpr? prototypeId;
    if (hasKeyword) {
      match(lexicon.kStruct);
      if (hasKeyword && expect([lexicon.kExtends], consume: true)) {
        final idTok = match(Semantic.identifier);
        prototypeId = IdentifierExpr.fromToken(idTok, source: currentSource);
      }
    }
    prototypeId ??= IdentifierExpr(lexicon.globalPrototypeId);
    final structBlockStartTok = match(lexicon.functionBlockStart);
    final fields = <StructObjField>[];
    while (curTok.type != lexicon.functionBlockEnd &&
        curTok.type != Semantic.endOfFile) {
      if (curTok.type == Semantic.identifier ||
          curTok.type == Semantic.literalString) {
        final keyTok = advance();
        late final StructObjField field;
        if (curTok.type == lexicon.comma ||
            curTok.type == lexicon.functionBlockEnd) {
          final id = IdentifierExpr.fromToken(keyTok, source: currentSource);
          field = StructObjField(
              key: IdentifierExpr.fromToken(
                keyTok,
                isLocal: false,
                source: currentSource,
              ),
              fieldValue: id);
        } else {
          match(lexicon.structValueIndicator);
          final value = _parseExpr();
          field = StructObjField(
              key: IdentifierExpr.fromToken(
                keyTok,
                isLocal: false,
                source: currentSource,
              ),
              fieldValue: value);
        }
        if (curTok.type != lexicon.functionBlockEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(field);
        fields.add(field);
      } else if (curTok.type == lexicon.spreadSyntax) {
        advance();
        final value = _parseExpr();
        final field = StructObjField(fieldValue: value, isSpread: true);
        if (curTok.type != lexicon.functionBlockEnd) {
          match(lexicon.comma);
        }
        _handleTrailingComment(field);
        fields.add(field);
      } else if (curTok is TokenComment) {
        _handlePrecedingComment();
      } else {
        if (curTok is TokenEmptyLine) {
          advance();
        } else {
          final errTok = advance();
          final err = HTError.structMemberId(curTok.type,
              filename: currrentFileName,
              line: errTok.line,
              column: errTok.column,
              offset: errTok.offset,
              length: errTok.length);
          errors?.add(err);
        }
      }
    }
    if (fields.isEmpty) {
      final empty = StructObjField(
          source: currentSource,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.offset - structBlockStartTok.offset);
      empty.precedingComments.addAll(currentPrecedingComments);
      currentPrecedingComments.clear();
      fields.add(empty);
    }
    match(lexicon.functionBlockEnd);
    return StructObjExpr(fields,
        prototypeId: prototypeId,
        source: currentSource,
        line: structBlockStartTok.line,
        column: structBlockStartTok.column,
        offset: structBlockStartTok.offset,
        length: curTok.offset - structBlockStartTok.offset);
  }
}
