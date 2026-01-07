import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';

/// ===================================================================
/// FILE LƯU TRỮ BÀI ĐĂNG VÀO LOCAL STORAGE (SHAREDPREFERENCES)
/// ===================================================================
/// 
/// FILE NÀY CHỊU TRÁCH NHIỆM:
/// 1. Lưu bài đăng người dùng tạo vào điện thoại (local storage)
/// 2. Chuyển đổi dữ liệu PostItem <-> JSON để lưu trữ
/// 3. Thêm/Xóa/Sửa bài đăng
/// 
/// DỮ LIỆU LƯU Ở ĐÂU?
/// - Lưu trong SharedPreferences (tập tin nhỏ trên điện thoại)
/// - Key: 'user_posts_key'
/// - Value: JSON string chứa danh sách tất cả bài đăng
/// 
/// ẢNH LƯU KIỂU GÌ?
/// - Ảnh được chuyển thành Base64 Data URI (chuỗi text)
/// - Format: "data:image/jpeg;base64,<BASE64_STRING>"
/// - Lưu vào trường 'images' (list) trong JSON
/// - Khi hiển thị: decode Base64 → bytes → Image.memory()
/// ===================================================================

class PostStorageService {
  // Key để lưu trong SharedPreferences
  static const String _postsKey = 'user_posts_key';
  
  // Biến để truy cập SharedPreferences
  static late SharedPreferences _prefs;

  /// Khởi tạo SharedPreferences khi app bắt đầu
  /// GỌI HÀM NÀY TRONG main() TRƯỚC KHI CHẠY APP
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// ===== HÀM LƯU TẤT CẢ BÀI ĐĂNG =====
  /// 
  /// CÁCH HOẠT ĐỘNG:
  /// 1. Nhận danh sách bài đăng (List<PostItem>)
  /// 2. Chuyển mỗi PostItem thành JSON (serialize)
  /// 3. Gộp tất cả JSON thành 1 chuỗi text
  /// 4. Lưu chuỗi text vào SharedPreferences với key 'user_posts_key'
  /// 
  /// KẾT QUẢ: Dữ liệu được lưu vào điện thoại, không mất khi tắt app
  static Future<void> savePosts(List<PostItem> posts) async {
    // Bước 1: Chuyển từng PostItem thành JSON
    final jsonList = posts.map((p) => _postToJson(p)).toList();
    
    // Bước 2: Chuyển list JSON thành chuỗi text
    // Bước 3: Lưu vào SharedPreferences
    await _prefs.setString(_postsKey, jsonEncode(jsonList));
  }

  /// ===== HÀM LẤY TẤT CẢ BÀI ĐĂNG =====
  /// 
  /// CÁCH HOẠT ĐỘNG:
  /// 1. Lấy chuỗi JSON từ SharedPreferences
  /// 2. Chuyển chuỗi JSON thành List<PostItem> (deserialize)
  /// 3. Trả về danh sách bài đăng
  /// 
  /// KẾT QUẢ: Lấy lại dữ liệu đã lưu từ lần trước
  static Future<List<PostItem>> loadPosts() async {
    // Bước 1: Lấy chuỗi JSON từ SharedPreferences
    final jsonStr = _prefs.getString(_postsKey);
    if (jsonStr == null) return []; // Nếu chưa có dữ liệu → trả về list rỗng
    
    try {
      // Bước 2: Chuyển chuỗi JSON thành List
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      
      // Bước 3: Chuyển từng JSON thành PostItem
      return jsonList.map((json) => _postFromJson(json)).toList();
    } catch (e) {
      return []; // Nếu lỗi → trả về list rỗng
    }
  }

  /// ===== HÀM THÊM BÀI ĐĂNG MỚI =====
  /// 
  /// CÁCH HOẠT ĐỘNG:
  /// 1. Load tất cả bài đăng hiện tại
  /// 2. Thêm bài mới vào danh sách
  /// 3. Lưu lại toàn bộ danh sách
  static Future<void> addPost(PostItem post) async {
    final posts = await loadPosts();
    posts.add(post);
    await savePosts(posts);
  }

  /// ===== HÀM XÓA BÀI ĐĂNG =====
  /// 
  /// CÁCH HOẠT ĐỘNG:
  /// 1. Load tất cả bài đăng
  /// 2. Xóa bài có ID trung khớp
  /// 3. Lưu lại danh sách mới
  static Future<void> deletePost(String postId) async {
    final posts = await loadPosts();
    posts.removeWhere((p) => p.id == postId);
    await savePosts(posts);
  }

  /// ===== HÀM CẬP NHẬT BÀI ĐĂNG =====
  /// 
  /// CÁCH HOẠT ĐỘNG:
  /// 1. Load tất cả bài đăng
  /// 2. Tìm bài có ID trùng khớp
  /// 3. Thay thế bài cũ bằng bài mới
  /// 4. Lưu lại danh sách
  static Future<void> updatePost(PostItem post) async {
    final posts = await loadPosts();
    final index = posts.indexWhere((p) => p.id == post.id);
    if (index != -1) {
      posts[index] = post;
      await savePosts(posts);
    }
  }

  /// ===== CHUYỂN POSTITEM THÀNH JSON =====
  /// 
  /// QUAN TRỌNG: ẢNH LƯU Ở ĐÂY!
  /// - Trường 'images': List<String> chứa ảnh dạng Base64 Data URI
  /// - Ví dụ: ["data:image/jpeg;base64,/9j/4AAQ...", "data:image/jpeg;base64,iVBORw..."]
  /// - Không lưu file ảnh riêng, mà nhúng trực tiếp vào JSON
  /// 
  /// CÁC TRƯỜNG KHÁC:
  /// - id, title, content, category, v.v.: dữ liệu text bình thường
  /// - timestamp: chuyển DateTime → chuỗi ISO8601
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
      'images': post.images, // ← ẢNH LƯU Ở ĐÂY (List Base64 string)
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

  /// ===== CHUYỂN JSON THÀNH POSTITEM =====
  /// 
  /// CÁCH ĐỌC ẢNH TỪ JSON:
  /// - Trường 'images': lấy list string Base64 Data URI
  /// - Khi hiển thị: decode Base64 → bytes → Image.memory(bytes)
  /// - Xem hàm _decodeDataUri() trong create_post_screen.dart
  /// 
  /// CÁC TRƯỜNG KHÁC:
  /// - timestamp: chuyển chuỗi ISO8601 → DateTime
  /// - likedBy, savedBy: chuyển JSON array → List<String>
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
      images: List<String>.from(json['images'] ?? []), // ← ẢNH LẤY TỪ ĐÂY
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

/// ===================================================================
/// TÓM TẮT QUY TRÌNH LƯU DỮ LIỆU BÀI ĐĂNG:
/// ===================================================================
/// 
/// 1. ĐĂNG BÀI:
///    User tạo bài → Chọn ảnh → Ảnh chuyển thành Base64
///    → PostItem có trường images = ["data:image/jpeg;base64,..."]
/// 
/// 2. LƯU:
///    PostItem → _postToJson() → JSON
///    → jsonEncode() → chuỗi text
///    → SharedPreferences.setString('user_posts_key', chuỗi)
///    → Lưu vào tập tin trên điện thoại
/// 
/// 3. LOAD:
///    SharedPreferences.getString('user_posts_key') → lấy chuỗi text
///    → jsonDecode() → List JSON
///    → _postFromJson() → List<PostItem>
///    → Hiển thị bài đăng và ảnh
/// 
/// 4. HIỂN THỊ ẢNH:
///    Lấy chuỗi Base64 từ post.images[0]
///    → Tách "data:image/jpeg;base64," → lấy phần Base64
///    → base64Decode() → bytes
///    → Image.memory(bytes) → hiển thị ảnh
/// 
/// ===================================================================
/// LƯU Ý:
/// - Dữ liệu lưu trong SharedPreferences KHÔNG MẤT khi tắt app
/// - SharedPreferences là tập tin nhỏ do Flutter quản lý
/// - Không phải database, không phải API, là local storage
/// ===================================================================
