import '../parser/token.dart' show TokenComment;

enum CommentType {
  emptyLine,
  singleLine,
  multiLine,
  documentation,
}

/// Comment or Empty line before a statement.
class Comment {
  final String content;

  final CommentType type;

  final bool isTrailing;

  Comment({this.content = '', required this.type, this.isTrailing = false});

  Comment.fromCommentToken(TokenComment token)
      : this(
            content: token.literal,
            type: token.commentType,
            isTrailing: token.isTrailing);

  Comment.emptyLine() : this(type: CommentType.emptyLine);
}
