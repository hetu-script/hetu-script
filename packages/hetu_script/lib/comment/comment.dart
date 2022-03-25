import '../parser/token.dart' show TokenComment;

enum CommentType {
  singleLine,
  multiLine,
  documentation,
}

class Comment {
  final String content;

  final CommentType type;

  final bool isTrailing;

  Comment(this.content, {required this.type, this.isTrailing = false});

  Comment.fromToken(TokenComment token)
      : this(token.literal,
            type: token.commentType, isTrailing: token.isTrailing);
}
