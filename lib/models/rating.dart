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
    this.role, // 'seller' or 'buyer' - vai trò của người được đánh giá
  });

  final String id;
  final String sellerId;  // ID của người được đánh giá (trong vai trò seller)
  final String sellerName;
  final double rating;
  final String review;
  final DateTime timestamp;
  final String raterUserId;  // ID của người đánh giá
  final String raterName;    // Tên người đánh giá
  final String? raterAvatar; // Avatar người đánh giá
  final String? role;        // Vai trò của người được đánh giá (seller/buyer)
}
