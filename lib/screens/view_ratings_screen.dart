import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/post_provider.dart';
import '../widgets/main_layout.dart';

class ViewRatingsScreen extends StatelessWidget {
  const ViewRatingsScreen({
    super.key,
    required this.user,
  });

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    
    // Get all ratings for this user
    final userRatings = postProvider.ratings
        .where((r) => r.sellerId == user.id)
        .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return MainLayoutWithCustomAppBar(
      title: 'Đánh giá của ${user.name}',
      showDrawer: true,
      child: userRatings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có đánh giá nào',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: userRatings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final rating = userRatings[index];
                return _RatingCard(rating: rating);
              },
            ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.rating});

  final rating;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating info
            Row(
              children: [
                // Avatar người đánh giá
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade100,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: (rating.raterAvatar != null && rating.raterAvatar!.isNotEmpty)
                      ? Image.network(
                          rating.raterAvatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                rating.raterName.isNotEmpty ? rating.raterName[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.w600),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            rating.raterName.isNotEmpty ? rating.raterName[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.w600),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.raterName,  // Tên người đánh giá
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        _formatDate(rating.timestamp),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Star rating
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRatingColor(rating.rating.toInt()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        rating.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Review
            if (rating.review != null && rating.review!.isNotEmpty) ...[const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  rating.review!,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} phút trước';
      }
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return const Color(0xFF16A34A); // Green
    if (rating >= 3) return const Color(0xFF2563EB); // Blue
    if (rating >= 2) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFEF4444); // Red
  }
}
