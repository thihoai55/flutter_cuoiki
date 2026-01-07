import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/rating.dart';
import '../models/transaction.dart';
import '../models/notification.dart';
import '../services/post_api.dart';
import '../services/post_storage_service.dart';
import '../services/notification_storage_service.dart';
import 'notification_provider.dart';
import 'follow_provider.dart';

class PostProvider extends ChangeNotifier {
  List<PostItem> _posts = [];
  List<PostComment> _comments = [];
  final List<PurchaseTransaction> _transactions = [];
  final List<SellerRating> _ratings = [];
  // Map userId -> List of saved post IDs
  final Map<String, List<String>> _savedPostIdsByUser = {};

  List<PostItem> get posts => List.unmodifiable(_posts);
  
  // Get saved posts for specific user
  List<PostItem> savedPostsForUser(String userId) {
    final savedIds = _savedPostIdsByUser[userId] ?? [];
    return _posts.where((p) => savedIds.contains(p.id)).toList();
  }
  
  // Deprecated: use savedPostsForUser(userId)
  List<PostItem> get savedPosts => [];
  
  // Check if post is saved by user
  bool isPostSavedByUser(String postId, String userId) {
    final savedIds = _savedPostIdsByUser[userId] ?? [];
    return savedIds.contains(postId);
  }

  Future<void> loadPosts() async {
    // Load from API
    final apiPosts = await PostApi.getAllPosts();
    // Load from local storage (user-created posts)
    final storagePosts = await PostStorageService.loadPosts();
    // Combine both
    _posts = [...apiPosts, ...storagePosts];
    notifyListeners();
  }

  Future<void> loadComments(String postId) async {
    final comments = await PostApi.getCommentsForPost(postId);
    _comments.removeWhere((c) => c.postId == postId);
    _comments.addAll(comments);
    notifyListeners();
  }

  List<PostComment> commentsOf(String postId) =>
      _comments.where((c) => c.postId == postId).toList();

  List<PurchaseTransaction> get transactions => List.unmodifiable(_transactions);
  List<SellerRating> get ratings => List.unmodifiable(_ratings);

  /// Toggle like and send notification
  Future<void> toggleLike(String postId, String userId, String userName, String? userAvatar) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = _posts[idx];
    final already = post.likedBy.contains(userId);
    
    if (already) {
      post.likedBy.remove(userId);
      post.likes = (post.likes - 1).clamp(0, 1 << 31);
    } else {
      post.likedBy.add(userId);
      post.likes += 1;
      
      // Send notification to post author
      if (post.authorId != userId) {
        final notification = AppNotification(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          userId: post.authorId,
          type: 'like',
          time: DateTime.now(),
          title: 'Có người thích bài đăng của bạn',
          message: '$userName đã thích bài đăng "${post.title}"',
          postId: postId,
          fromUserId: userId,
          fromUserName: userName,
          fromUserAvatar: userAvatar,
          timestamp: DateTime.now(),
          isRead: false,
        );
        await NotificationStorageService.addNotification(notification);
      }
    }
    notifyListeners();
  }

  /// Toggle save post (add to saved list)
  Future<void> toggleSave(String postId, String userId) async {
    // Update user's saved list
    final savedIds = _savedPostIdsByUser[userId] ?? [];
    if (savedIds.contains(postId)) {
      savedIds.remove(postId);
    } else {
      savedIds.add(postId);
    }
    _savedPostIdsByUser[userId] = savedIds;
    
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = _posts[idx];
    
    if (post.savedBy.contains(userId)) {
      post.savedBy.remove(userId);
    } else {
      post.savedBy.add(userId);
    }
    notifyListeners();
  }

  /// Check if post is saved by specific user
  bool isSavedByUser(String postId, String userId) {
    final post = _posts.firstWhere((p) => p.id == postId, orElse: () => throw Exception('Post not found'));
    return post.savedBy.contains(userId);
  }

  void incrementView(String postId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    _posts[idx].views += 1;
    notifyListeners();
  }

  /// Add comment and send notification
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String? authorAvatar,
    required String content,
  }) async {
    final comment = PostComment(
      id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      content: content,
      createdAt: DateTime.now(),
    );

    await PostApi.addComment(comment);
    _comments.add(comment);
    
    // Send notification to post author
    final post = _posts.firstWhere((p) => p.id == postId, orElse: () => _posts.first);
    if (post.authorId != authorId) {
      final notification = AppNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        userId: post.authorId,
        type: 'comment',
        time: DateTime.now(),
        title: 'Có bình luận mới',
        message: '$authorName đã bình luận: "$content"',
        postId: postId,
        fromUserId: authorId,
        fromUserName: authorName,
        fromUserAvatar: authorAvatar,
        timestamp: DateTime.now(),
        isRead: false,
      );
      await NotificationStorageService.addNotification(notification);
    }
    
    notifyListeners();
  }

  PostItem? postById(String id) {
    try {
      return _posts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<PostItem> postsBy(String authorId) =>
      _posts.where((p) => p.authorId == authorId).toList();

  List<PostItem> postsByCategory(String category) =>
      _posts.where((p) => p.category == category).toList();

  List<PostItem> relatedPosts(String postId) {
    final post = postById(postId);
    if (post == null) return [];
    return _posts
        .where((p) =>
            p.id != postId && p.category == post.category && p.status == 'approved')
        .take(6)
        .toList();
  }

  Future<void> addPost(
    PostItem post, {
    NotificationProvider? notificationProvider,
    FollowProvider? followProvider,
  }) async {
    // Đảm bảo có image chính
    final normalized = post.image != null || post.images.isEmpty
        ? post
        : PostItem(
            id: post.id,
            title: post.title,
            content: post.content,
            category: post.category,
            type: post.type,
            price: post.price,
            authorId: post.authorId,
            authorName: post.authorName,
            authorAvatar: post.authorAvatar,
            condition: post.condition,
            location: post.location,
            contact: post.contact,
            image: post.images.first,
            images: post.images,
            videos: post.videos,
            status: post.status,
            hidden: post.hidden,
            timestamp: post.timestamp,
            likes: post.likes,
            views: post.views,
            likedBy: post.likedBy,
            savedBy: post.savedBy,
            packageType: post.packageType,
            sold: post.sold,
            soldTimestamp: post.soldTimestamp,
            buyerId: post.buyerId,
            buyerName: post.buyerName,
            buyerAvatar: post.buyerAvatar,
            rejectionReason: post.rejectionReason,
          );

    await PostStorageService.addPost(normalized);
    _posts.add(normalized);

    notifyListeners();
  }

  /// Duyệt bài đăng và chỉ gửi thông báo sau khi bài ở trạng thái 'approved'
  Future<void> approvePost(String postId, NotificationProvider notificationProvider) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final current = _posts[idx];
    final approved = PostItem(
      id: current.id,
      title: current.title,
      content: current.content,
      category: current.category,
      type: current.type,
      price: current.price,
      authorId: current.authorId,
      authorName: current.authorName,
      authorAvatar: current.authorAvatar,
      timestamp: current.timestamp,
      images: current.images,
      image: current.image,
      likes: current.likes,
      likedBy: current.likedBy,
      savedBy: current.savedBy,
      views: current.views,
      sold: current.sold,
      status: 'approved',
      hidden: false,
      location: current.location,
      contact: current.contact,
      condition: current.condition,
      videos: current.videos,
      packageType: current.packageType,
      soldTimestamp: current.soldTimestamp,
      buyerId: current.buyerId,
      buyerName: current.buyerName,
      buyerAvatar: current.buyerAvatar,
    );

    // Cập nhật storage và bộ nhớ
    await PostStorageService.updatePost(approved);
    _posts[idx] = approved;

    // Gửi thông báo cho người cần mua nếu là bài bán premium (chỉ sau khi approved)
    if (approved.type == 'sell' && approved.packageType == 'premium') {
      await _sendPremiumPostNotifications(approved, notificationProvider);
    }

    // Gửi thông báo cho tác giả khi được duyệt
    notificationProvider.addNotification(
      userId: approved.authorId,
      message: 'Bài "${approved.title}" đã được duyệt',
      type: 'approved',
      postId: approved.id,
    );

    notifyListeners();
  }
  
  Future<void> _sendPremiumPostNotifications(PostItem post, NotificationProvider notificationProvider) async {
    try {
      // Tìm tất cả người mua có bài đăng cùng danh mục
      final buyerIds = <String>{};
      for (final otherPost in _posts) {
        if (otherPost.type == 'buy' && 
            otherPost.category == post.category && 
            otherPost.authorId != post.authorId) {
          buyerIds.add(otherPost.authorId);
        }
      }
      
      // Gửi thông báo đến từng người mua
      for (final buyerId in buyerIds) {
        notificationProvider.addNotification(
          userId: buyerId,
          message: '"${post.title}" - ${post.price} trong danh mục ${post.category}',
          type: 'post',
          postId: post.id,
        );
      }
    } catch (e) {
      debugPrint('Error sending premium post notifications: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    await PostStorageService.deletePost(postId);
    _posts.removeWhere((p) => p.id == postId);
    _comments.removeWhere((c) => c.postId == postId);
    _transactions.removeWhere((t) => t.postId == postId);
    notifyListeners();
  }

  /// Từ chối duyệt bài đăng (không gửi thông báo)
  Future<void> rejectPost(String postId, {String? reason, required NotificationProvider notificationProvider}) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final current = _posts[idx];
    final rejected = PostItem(
      id: current.id,
      title: current.title,
      content: current.content,
      category: current.category,
      type: current.type,
      price: current.price,
      authorId: current.authorId,
      authorName: current.authorName,
      authorAvatar: current.authorAvatar,
      timestamp: current.timestamp,
      images: current.images,
      image: current.image,
      likes: current.likes,
      likedBy: current.likedBy,
      savedBy: current.savedBy,
      views: current.views,
      sold: current.sold,
      hidden: true,
      status: 'rejected',
      rejectionReason: reason,
      location: current.location,
      contact: current.contact,
      condition: current.condition,
      videos: current.videos,
      packageType: current.packageType,
      soldTimestamp: current.soldTimestamp,
      buyerId: current.buyerId,
      buyerName: current.buyerName,
      buyerAvatar: current.buyerAvatar,
    );

    await PostStorageService.updatePost(rejected);
    _posts[idx] = rejected;

    // Thông báo cho tác giả kèm lý do
    notificationProvider.addNotification(
      userId: rejected.authorId,
      message: 'Bài "${rejected.title}" bị từ chối: ${reason ?? 'Không có lý do'}',
      type: 'rejected',
      postId: rejected.id,
    );
    notifyListeners();
  }

  Future<void> toggleHidePost(String postId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    
    final post = _posts[idx];
    final updatedPost = PostItem(
      id: post.id,
      title: post.title,
      content: post.content,
      category: post.category,
      type: post.type,
      price: post.price,
      authorId: post.authorId,
      authorName: post.authorName,
      authorAvatar: post.authorAvatar,
      timestamp: post.timestamp,
      images: post.images,
      image: post.image,
      likes: post.likes,
      likedBy: post.likedBy,
      savedBy: post.savedBy,
      views: post.views,
      sold: post.sold,
      hidden: !post.hidden,
      status: post.status,
      location: post.location,
      contact: post.contact,
      condition: post.condition,
    );
    
    _posts[idx] = updatedPost;
    await PostStorageService.updatePost(updatedPost);
    notifyListeners();
  }

  void updatePost(PostItem updatedPost) {
    final idx = _posts.indexWhere((p) => p.id == updatedPost.id);
    if (idx == -1) return;
    _posts[idx] = updatedPost;
    notifyListeners();
  }

  void markAsSold(String postId, {
    required String buyerId,
    required String buyerName,
    required String? buyerAvatar,
  }) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    _posts[idx].sold = true;
    _posts[idx].soldTimestamp = DateTime.now().toIso8601String();
    _posts[idx].buyerId = buyerId;
    _posts[idx].buyerName = buyerName;
    _posts[idx].buyerAvatar = buyerAvatar;
    notifyListeners();
  }

  /// ============ QUY TRÌNH ĐẶT MUA HÀNG & CẬP NHẬT TRẠNG THÁI ============
  /// 
  /// LƯU TRỮ: Dữ liệu transaction chỉ lưu trong RAM (_transactions list), KHÔNG persist 
  /// vào SharedPreferences. Nếu user tắt/reload app, tất cả transaction sẽ mất. 
  /// Cần thêm transaction_storage_service.dart để persist như post storage.
  /// 
  /// FLOW ĐẶT HÀNG:
  /// 1. Người mua click "Mua ngay" ở PostDetailScreen
  /// 2. Show dialog "Xác nhận mua", nhập tên/SĐT/địa chỉ
  /// 3. Tạo PurchaseTransaction object gửi addTransaction() ← HÀM NÀY
  /// 4. Lưu vào _transactions (RAM)
  /// 5. Gửi thông báo cho người bán qua NotificationProvider (persist vào SharedPreferences)
  /// 
  /// FLOW CẬP NHẬT TRẠNG THÁI:
  /// - pending → approved (người bán duyệt)
  /// - approved → shipping (bắt đầu giao hàng)
  /// - shipping → completed (hoàn thành giao hàng)
  /// Người mua xem ở MyOrdersScreen hoặc OrderTrackingScreen
  /// 
  void addTransaction(PurchaseTransaction transaction) {
    // Thêm transaction mới vào danh sách lưu tạm trong RAM
    _transactions.add(transaction);
    // Thông báo cho tất cả listeners (screens) để cập nhật UI
    notifyListeners();
  }

  /// Cập nhật trạng thái transaction (pending → approved → shipping → completed)
  /// Lưu tạm trong RAM chỉ, sẽ mất khi reload app!
  void updateTransactionStatus(String transactionId, String status) {
    final idx = _transactions.indexWhere((t) => t.id == transactionId);
    if (idx == -1) return;
    _transactions[idx].status = status;
    // Thông báo UI cập nhật trạng thái transaction
    notifyListeners();
  }
  
  // Mark post as sold (hide from public)
  void markPostAsSold(String postId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    _posts[idx].sold = true;
    _posts[idx].soldTimestamp = DateTime.now().toIso8601String();
    notifyListeners();
  }

  List<PurchaseTransaction> transactionsBy(String userId) =>
      _transactions.where((t) => t.buyerId == userId).toList();

  List<PurchaseTransaction> transactionsFor(String sellerId) {
    final sellerPostIds = postsBy(sellerId).map((p) => p.id).toSet();
    return _transactions.where((t) => sellerPostIds.contains(t.postId)).toList();
  }

  // Get count of pending/awaiting_payment transactions for seller
  int getPendingTransactionsCount(String sellerId) {
    final sellerPostIds = postsBy(sellerId).map((p) => p.id).toSet();
    return _transactions
        .where((t) => 
          sellerPostIds.contains(t.postId) && 
          (t.status == 'pending' || t.status == 'awaiting_payment'))
        .length;
  }

  /// Rating
  void addRating(SellerRating rating) {
    _ratings.add(rating);
    notifyListeners();
  }

  List<SellerRating> ratingsFor(String sellerId) =>
      _ratings.where((r) => r.sellerId == sellerId).toList();

  double averageRatingFor(String sellerId) {
    final list = ratingsFor(sellerId);
    if (list.isEmpty) return 0;
    final sum = list.fold<double>(0, (prev, r) => prev + r.rating);
    return sum / list.length;
  }
}
