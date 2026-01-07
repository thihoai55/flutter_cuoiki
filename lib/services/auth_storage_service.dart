import 'package:shared_preferences/shared_preferences.dart';

/// ============ DỊCH VỤ LƯU TRỮ THÔNG TIN ĐĂNG NHẬP ============
/// 
/// Chức năng: Lưu userId vào SharedPreferences để tự động đăng nhập lại
/// khi người dùng mở lại app (không cần nhập email/password lại)
/// 
/// FLOW:
/// 1. Đăng nhập/Đăng ký → Lưu userId vào SharedPreferences
/// 2. Mở app lại → Đọc userId từ SharedPreferences → Tự động đăng nhập
/// 3. Đăng xuất → Xóa userId khỏi SharedPreferences
/// 
/// LƯU TRỮ:
/// - Key: 'current_user_id'
/// - Value: userId (String)
/// - Persist: Vào file SharedPreferences (KHÔNG mất khi reload app)
/// 
class AuthStorageService {
  static const String _currentUserKey = 'current_user_id';

  /// Khởi tạo service (gọi trước khi sử dụng)
  static Future<void> init() async {
    await SharedPreferences.getInstance();
  }

  /// Lưu userId khi đăng nhập thành công hoặc đăng ký
  /// userId sẽ được lưu vào SharedPreferences để persist
  static Future<void> saveCurrentUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, userId);
  }

  /// Lấy userId đã lưu (dùng khi khởi động app để auto-login)
  /// Trả về null nếu chưa đăng nhập hoặc đã logout
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  /// Xóa userId khi đăng xuất
  /// Sau khi xóa, lần mở app sau sẽ phải đăng nhập lại
  static Future<void> clearCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  /// Kiểm tra xem có userId đã lưu không
  static Future<bool> hasCurrentUser() async {
    final userId = await getCurrentUserId();
    return userId != null && userId.isNotEmpty;
  }
}
