class PostItem {
  PostItem({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.type,
    required this.price,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.condition,
    this.location,
    this.contact,
    this.image,
    List<String> images = const [],
    List<String> videos = const [],
    this.status,
    this.hidden = false,
    this.timestamp,
    this.likes = 0,
    this.views = 0,
    List<String> likedBy = const [],
    List<String> savedBy = const [],
    this.packageType,
    this.sold = false,
    this.soldTimestamp,
    this.buyerId,
    this.buyerName,
    this.buyerAvatar,
    this.rejectionReason,
  })  : images = List<String>.from(images),
        videos = List<String>.from(videos),
        likedBy = List<String>.from(likedBy),
        savedBy = List<String>.from(savedBy);

  final String id;
  final String title;
  final String content;
  final String category; // e.g. "Sách & Tài liệu"
  final String type; // 'buy' | 'sell'
  final String price;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String? condition;
  final String? location;
  final String? contact;
  final String? image;
  final List<String> images;
  final List<String> videos;
  final String? status; // pending | approved | rejected
  final String? rejectionReason; // Lý do từ chối (nếu bị từ chối)
  final bool hidden;
  final DateTime? timestamp;
  int likes;
  int views;
  final List<String> likedBy;
  final List<String> savedBy;
  final String? packageType; // free | basic | premium (optional)
  bool sold;
  String? soldTimestamp;
  String? buyerId;
  String? buyerName;
  String? buyerAvatar;
}
