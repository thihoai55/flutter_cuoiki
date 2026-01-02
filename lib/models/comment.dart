class PostComment {
  PostComment({
    required this.id,
    required this.postId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.authorId,
    this.authorAvatar,
  });

  final String id;
  final String postId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final String? authorId;
  final String? authorAvatar;
}
