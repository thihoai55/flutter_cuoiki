import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';

class PostStorageService {
  static const String _postsKey = 'user_posts_key';
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Lưu toàn bộ bài đăng người dùng
  static Future<void> savePosts(List<PostItem> posts) async {
    final jsonList = posts.map((p) => _postToJson(p)).toList();
    await _prefs.setString(_postsKey, jsonEncode(jsonList));
  }

  /// Lấy toàn bộ bài đăng được lưu
  static Future<List<PostItem>> loadPosts() async {
    final jsonStr = _prefs.getString(_postsKey);
    if (jsonStr == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((json) => _postFromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Thêm bài đăng mới
  static Future<void> addPost(PostItem post) async {
    final posts = await loadPosts();
    posts.add(post);
    await savePosts(posts);
  }

  /// Xóa bài đăng
  static Future<void> deletePost(String postId) async {
    final posts = await loadPosts();
    posts.removeWhere((p) => p.id == postId);
    await savePosts(posts);
  }

  /// Cập nhật bài đăng
  static Future<void> updatePost(PostItem post) async {
    final posts = await loadPosts();
    final index = posts.indexWhere((p) => p.id == post.id);
    if (index != -1) {
      posts[index] = post;
      await savePosts(posts);
    }
  }

  /// Convert PostItem to JSON
  static Map<String, dynamic> _postToJson(PostItem post) {
    return {
      'id': post.id,
      'title': post.title,
      'content': post.content,
      'category': post.category,
      'type': post.type,
      'price': post.price,
      'authorId': post.authorId,
      'authorName': post.authorName,
      'authorAvatar': post.authorAvatar,
      'condition': post.condition,
      'location': post.location,
      'contact': post.contact,
      'image': post.image,
      'images': post.images,
      'videos': post.videos,
      'status': post.status,
      'hidden': post.hidden,
      'timestamp': post.timestamp?.toIso8601String(),
      'likes': post.likes,
      'views': post.views,
      'likedBy': post.likedBy,
      'savedBy': post.savedBy,
      'packageType': post.packageType,
      'sold': post.sold,
      'soldTimestamp': post.soldTimestamp,
      'buyerId': post.buyerId,
      'buyerName': post.buyerName,
      'buyerAvatar': post.buyerAvatar,
    };
  }

  /// Convert JSON to PostItem
  static PostItem _postFromJson(Map<String, dynamic> json) {
    return PostItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? '',
      type: json['type'] ?? 'sell',
      price: json['price'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      authorAvatar: json['authorAvatar'],
      condition: json['condition'],
      location: json['location'],
      contact: json['contact'],
      image: json['image'],
      images: List<String>.from(json['images'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      status: json['status'] ?? 'pending',
      hidden: json['hidden'] ?? false,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      likes: json['likes'] ?? 0,
      views: json['views'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      savedBy: List<String>.from(json['savedBy'] ?? []),
      packageType: json['packageType'],
      sold: json['sold'] ?? false,
      soldTimestamp: json['soldTimestamp'] as String?,
      buyerId: json['buyerId'],
      buyerName: json['buyerName'],
      buyerAvatar: json['buyerAvatar'],
    );
  }
}
