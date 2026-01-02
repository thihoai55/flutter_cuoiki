class SellerRating {
  SellerRating({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.rating,
    required this.review,
    required this.timestamp,
    required this.raterUserId,
    required this.raterName,
    this.raterAvatar,
  });

  final String id;
  final String sellerId;
  final String sellerName;
  final double rating;
  final String review;
  final DateTime timestamp;
  final String raterUserId;  // ID của người đánh giá
  final String raterName;    // Tên người đánh giá
  final String? raterAvatar; // Avatar người đánh giá
}
