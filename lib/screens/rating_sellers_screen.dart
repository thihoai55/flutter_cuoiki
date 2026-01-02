import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../providers/notification_provider.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import '../models/rating.dart';
import '../widgets/main_layout.dart';

class RatingSellersScreen extends StatelessWidget {
  const RatingSellersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final postProvider = context.watch<PostProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const MainLayoutWithCustomAppBar(
        title: 'Đánh giá người mua/bán',
        showDrawer: true,
        child: Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    // Lấy tất cả transactions mà user tham gia (là buyer hoặc seller)
    final allTransactions = postProvider.transactions.where((tx) =>
      (tx.buyerId == user.id || tx.sellerId == user.id) &&
      (tx.status == 'payment_confirmed' || tx.status == 'shipping' || tx.status == 'completed')
    ).toList();

    // Lọc ra danh sách người đã giao dịch, phân biệt theo vai trò (seller/buyer)
    // Key format: "personId_role" (e.g., "4_seller" or "4_buyer")
    final Map<String, List<PurchaseTransaction>> peopleMap = {};
    
    for (var tx in allTransactions) {
      // Nếu user là buyer, thêm seller vào danh sách với role "seller"
      if (tx.buyerId == user.id) {
        final key = '${tx.sellerId}_seller';
        peopleMap.putIfAbsent(key, () => []).add(tx);
      }
      // Nếu user là seller, thêm buyer vào danh sách với role "buyer"
      if (tx.sellerId == user.id) {
        final key = '${tx.buyerId}_buyer';
        peopleMap.putIfAbsent(key, () => []).add(tx);
      }
    }

    return MainLayoutWithCustomAppBar(
      title: 'Đánh giá người mua/bán',
      showDrawer: true,
      child: peopleMap.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Chưa có giao dịch nào để đánh giá',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: peopleMap.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final compositeKey = peopleMap.keys.elementAt(index);
                final transactions = peopleMap[compositeKey]!;
                
                // Parse composite key: "personId_role"
                final parts = compositeKey.split('_');
                final personId = parts[0];
                final role = parts[1]; // "seller" or "buyer"
                final isSeller = role == 'seller';
                
                return FutureBuilder<AppUser?>(
                  future: auth.getUserById(personId),
                  builder: (context, snapshot) {
                    final person = snapshot.data;
                    if (person == null) {
                      return const SizedBox.shrink();
                    }
                    
                    return _PersonRatingCard(
                      person: person,
                      isSeller: isSeller,
                      transactionCount: transactions.length,
                      onRate: () => _showRatingModal(context, person, isSeller),
                    );
                  },
                );
              },
            ),
    );
  }

  void _showRatingModal(BuildContext context, AppUser person, bool isSeller) {
    showDialog(
      context: context,
      builder: (context) => _RatingModal(
        person: person,
        isSeller: isSeller,
      ),
    );
  }
}

class _PersonRatingCard extends StatelessWidget {
  const _PersonRatingCard({
    required this.person,
    required this.isSeller,
    required this.transactionCount,
    required this.onRate,
  });

  final AppUser person;
  final bool isSeller;
  final int transactionCount;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Custom avatar widget with better error handling
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade100,
            ),
            clipBehavior: Clip.hardEdge,
            child: (person.avatar != null && person.avatar!.isNotEmpty)
                ? Image.network(
                    person.avatar!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 20, color: Colors.blue, fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 20, color: Colors.blue, fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      isSeller ? Icons.store : Icons.shopping_bag,
                      size: 13,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        isSeller ? 'Người bán' : 'Người mua',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.receipt, size: 13, color: Colors.grey[600]),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        '$transactionCount giao dịch',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 15, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(
                      person.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      ' (${person.ratingCount})',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: onRate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Đánh giá', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingModal extends StatefulWidget {
  const _RatingModal({
    required this.person,
    required this.isSeller,
  });

  final AppUser person;
  final bool isSeller;

  @override
  State<_RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends State<_RatingModal> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Đánh giá ${widget.isSeller ? "người bán" : "người mua"}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Person info
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade100,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: (widget.person.avatar != null && widget.person.avatar!.isNotEmpty)
                      ? Image.network(
                          widget.person.avatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                widget.person.name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.w600),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            widget.person.name[0].toUpperCase(),
                            style: const TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.w600),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.person.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      Text(
                        widget.isSeller ? 'Người bán' : 'Người mua',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Rating stars
            const Text(
              'Đánh giá của bạn:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            
            // Comment
            const Text(
              'Nhận xét:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Chia sẻ trải nghiệm của bạn...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => _submitRating(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),
          child: const Text('Gửi đánh giá'),
        ),
      ],
    );
  }

  void _submitRating(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final notifProvider = context.read<NotificationProvider>();
    final postProvider = context.read<PostProvider>();
    final currentUser = auth.currentUser;

    if (currentUser == null) return;

    // Lưu rating vào PostProvider
    final newRating = SellerRating(
      id: 'rating_${DateTime.now().millisecondsSinceEpoch}',
      sellerId: widget.person.id,
      sellerName: widget.person.name,
      rating: _rating.toDouble(),
      review: _commentController.text.isNotEmpty ? _commentController.text : 'Không có nhận xét',
      timestamp: DateTime.now(),
      raterUserId: currentUser.id,
      raterName: currentUser.name,
      raterAvatar: currentUser.avatar,
    );
    
    postProvider.addRating(newRating);
    
    // Gửi notification cho người được đánh giá
    notifProvider.addNotification(
      userId: widget.person.id,
      type: 'rating',
      message: '${currentUser.name} đã đánh giá bạn $_rating sao${_commentController.text.isNotEmpty ? ': "${_commentController.text}"' : ''}',
      postId: null,
    );

    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gửi đánh giá thành công!'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }
}
