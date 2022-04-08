import '../ast/ast.dart';
import '../lexer/lexicon2.dart';
import '../lexer/lexicon_default_impl.dart';
import '../analyzer/analysis_error.dart';

/// A interpreter that computes the constant value before compilation.
/// If the AstNode provided is non-constant value, return null.
class HTConstantInterpreter implements AbstractASTVisitor<void> {
  late final HTLexicon _lexicon;

  HTConstantInterpreter({HTLexicon? lexicon})
      : _lexicon = lexicon ?? HTDefaultLexicon();

  /// Errors of a single file
  late List<HTAnalysisError> errors = [];

  void evalAstNode(ASTNode node) => node.accept(this);

  @override
  void visitCompilation(ASTCompilation node) {
    node.subAccept(this);
  }

  @override
  void visitSource(ASTSource node) {
    node.subAccept(this);
  }

  @override
  void visitEmptyExpr(ASTEmptyLine node) {}

  @override
  void visitNullExpr(ASTLiteralNull node) {}

  @override
  void visitBooleanExpr(ASTLiteralBoolean node) {}

  @override
  void visitIntLiteralExpr(ASTLiteralInteger node) {}

  @override
  void visitFloatLiteralExpr(ASTLiteralFloat node) {}

  @override
  void visitStringLiteralExpr(ASTLiteralString node) {}

  @override
  void visitStringInterpolationExpr(ASTStringInterpolation node) {
    final interpolations = <String>[];
    for (final expr in node.interpolations) {
      expr.accept(this);
      if (!expr.isConstValue) {
        return;
      }
      interpolations.add(_lexicon.stringify(expr.value));
    }
    var text = node.text;
    for (var i = 0; i < interpolations.length; ++i) {
      text = text.replaceAll(
          '${_lexicon.functionBlockStart}$i${_lexicon.functionBlockEnd}',
          interpolations[i]);
    }
    node.value = text;
  }

  @override
  void visitIdentifierExpr(IdentifierExpr node) {
    node.subAccept(this);
  }

  @override
  void visitSpreadExpr(SpreadExpr node) {
    node.subAccept(this);
  }

  @override
  void visitCommaExpr(CommaExpr node) {
    node.subAccept(this);
  }

  @override
  void visitListExpr(ListExpr node) {
    node.subAccept(this);
  }

  @override
  void visitInOfExpr(InOfExpr node) {
    node.subAccept(this);
  }

  @override
  void visitGroupExpr(GroupExpr node) {
    node.subAccept(this);
    if (node.inner.isConstValue) {
      node.value = node.inner.value;
    }
  }

  @override
  void visitTypeExpr(TypeExpr node) {
    node.subAccept(this);
  }

  @override
  void visitParamTypeExpr(ParamTypeExpr node) {
    node.subAccept(this);
  }

  @override
  void visitFunctionTypeExpr(FuncTypeExpr node) {
    node.subAccept(this);
  }

  @override
  void visitFieldTypeExpr(FieldTypeExpr node) {
    node.subAccept(this);
  }

  @override
  void visitStructuralTypeExpr(StructuralTypeExpr node) {
    node.subAccept(this);
  }

  @override
  void visitGenericTypeParamExpr(GenericTypeParameterExpr node) {
    node.subAccept(this);
  }

  /// -e, !e，++e, --e
  @override
  void visitUnaryPrefixExpr(UnaryPrefixExpr node) {
    node.subAccept(this);
    if (node.op == _lexicon.logicalNot && node.object.isConstValue) {
      node.value = !node.object.value;
    } else if (node.op == _lexicon.negative &&
        node.object is ASTLiteralInteger) {
      node.value = -(node.object as ASTLiteralInteger).value;
    }
  }

  @override
  void visitUnaryPostfixExpr(UnaryPostfixExpr node) {
    node.subAccept(this);
  }

  /// *, /, ~/, %, +, -, <, >, <=, >=, ==, !=, &&, ||
  @override
  void visitBinaryExpr(BinaryExpr node) {
    final left = node.left.value;
    final right = node.right.value;
    if (node.op == _lexicon.multiply) {
      if (left != null && right != null) {
        node.value = left * right;
      }
    } else if (node.op == _lexicon.devide) {
      if (left != null && right != null) {
        node.value = left / right;
      }
    } else if (node.op == _lexicon.truncatingDevide) {
      if (left != null && right != null) {
        node.value = left ~/ right;
      }
    } else if (node.op == _lexicon.modulo) {
      if (left != null && right != null) {
        node.value = left % right;
      }
    } else if (node.op == _lexicon.add) {
      if (left != null && right != null) {
        node.value = left + right;
      }
    } else if (node.op == _lexicon.subtract) {
      if (left != null && right != null) {
        node.value = left - right;
      }
    } else if (node.op == _lexicon.lesser) {
      if (left != null && right != null) {
        node.value = left < right;
      }
    } else if (node.op == _lexicon.lesserOrEqual) {
      if (left != null && right != null) {
        node.value = left <= right;
      }
    } else if (node.op == _lexicon.greater) {
      if (left != null && right != null) {
        node.value = left > right;
      }
    } else if (node.op == _lexicon.greaterOrEqual) {
      if (left != null && right != null) {
        node.value = left >= right;
      }
    } else if (node.op == _lexicon.equal) {
      if (left != null && right != null) {
        node.value = left == right;
      }
    } else if (node.op == _lexicon.notEqual) {
      if (left != null && right != null) {
        node.value = left != right;
      }
    } else if (node.op == _lexicon.logicalAnd) {
      if (left != null && right != null) {
        node.value = left && right;
      }
    } else if (node.op == _lexicon.logicalOr) {
      if (left != null && right != null) {
        node.value = left || right;
      }
    }
  }

  /// e1 ? e2 : e3
  @override
  void visitTernaryExpr(TernaryExpr node) {
    node.subAccept(this);
  }

  @override
  void visitAssignExpr(AssignExpr node) {
    node.subAccept(this);
  }

  @override
  void visitMemberExpr(MemberExpr node) {
    node.subAccept(this);
  }

  @override
  void visitSubExpr(SubExpr node) {
    node.subAccept(this);
  }

  @override
  void visitCallExpr(CallExpr node) {
    node.subAccept(this);
  }

  @override
  void visitAssertStmt(AssertStmt node) {
    node.subAccept(this);
  }

  @override
  void visitThrowStmt(ThrowStmt node) {
    node.subAccept(this);
  }

  @override
  void visitExprStmt(ExprStmt node) {
    node.subAccept(this);
  }

  @override
  void visitBlockStmt(BlockStmt node) {
    node.subAccept(this);
  }

  @override
  void visitReturnStmt(ReturnStmt node) {
    node.subAccept(this);
  }

  @override
  void visitIf(IfStmt node) {
    node.subAccept(this);
  }

  @override
  void visitWhileStmt(WhileStmt node) {
    node.subAccept(this);
  }

  @override
  void visitDoStmt(DoStmt node) {
    node.subAccept(this);
  }

  @override
  void visitForStmt(ForStmt node) {
    node.subAccept(this);
  }

  @override
  void visitForRangeStmt(ForRangeStmt node) {
    node.subAccept(this);
  }

  @override
  void visitWhen(WhenStmt node) {
    node.subAccept(this);
  }

  @override
  void visitBreakStmt(BreakStmt node) {
    node.subAccept(this);
  }

  @override
  void visitContinueStmt(ContinueStmt node) {
    node.subAccept(this);
  }

  @override
  void visitDeleteStmt(DeleteStmt node) {
    node.subAccept(this);
  }

  @override
  void visitDeleteMemberStmt(DeleteMemberStmt node) {
    node.subAccept(this);
  }

  @override
  void visitDeleteSubStmt(DeleteSubStmt node) {
    node.subAccept(this);
  }

  @override
  void visitImportExportDecl(ImportExportDecl node) {
    node.subAccept(this);
  }

  @override
  void visitNamespaceDecl(NamespaceDecl node) {
    node.subAccept(this);
  }

  @override
  void visitTypeAliasDecl(TypeAliasDecl node) {
    node.subAccept(this);
  }

  // @override
  // void visitConstDecl(ConstDecl node) {
  //   node.subAccept(this);
  // }

  @override
  void visitVarDecl(VarDecl node) {
    node.subAccept(this);
    if (node.isConst && !node.initializer!.isConstValue) {
      final err = HTAnalysisError.constValue(
          filename: node.source!.fullName,
          line: node.initializer!.line,
          column: node.initializer!.column,
          offset: node.initializer!.offset,
          length: node.initializer!.length);
      errors.add(err);
    }
  }

  @override
  void visitDestructuringDecl(DestructuringDecl node) {
    node.subAccept(this);
  }

  @override
  void visitParamDecl(ParamDecl node) {
    node.subAccept(this);
  }

  @override
  void visitReferConstructCallExpr(RedirectingConstructorCallExpr node) {
    node.subAccept(this);
  }

  @override
  void visitFuncDecl(FuncDecl node) {
    node.subAccept(this);
  }

  @override
  void visitClassDecl(ClassDecl node) {
    node.subAccept(this);
  }

  @override
  void visitEnumDecl(EnumDecl node) {
    node.subAccept(this);
  }

  @override
  void visitStructDecl(StructDecl node) {
    node.subAccept(this);
  }

  @override
  void visitStructObjExpr(StructObjExpr node) {
    node.subAccept(this);
  }

  @override
  void visitStructObjField(StructObjField node) {
    node.subAccept(this);
  }
}
