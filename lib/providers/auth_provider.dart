import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_api.dart';
import '../services/auth_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  bool isReady = true;
  AppUser? currentUser;
  List<AppUser> _users = [];

  /// ============ TỰ ĐỘNG ĐĂNG NHẬP KHI KHỞI ĐỘNG APP ============
  /// 
  /// Hàm này được gọi khi app khởi động (từ main.dart)
  /// - Đọc userId từ SharedPreferences
  /// - Nếu có userId đã lưu → Tự động load thông tin user
  /// - Nếu không có → Người dùng cần đăng nhập thủ công
  /// 
  Future<void> tryAutoLogin() async {
    final savedUserId = await AuthStorageService.getCurrentUserId();
    if (savedUserId != null) {
      // Tìm user theo userId đã lưu
      final user = await UserApi.getUserById(savedUserId);
      if (user != null) {
        currentUser = user;
        notifyListeners();
      }
    }
  }

  Future<void> loadUsers() async {
    _users = await UserApi.getAllUsers();
    notifyListeners();
  }

  /// Đăng nhập và LƯU userId vào SharedPreferences
  Future<AppUser> login(String email, String password) async {
    final user = await UserApi.login(email, password);
    if (user == null) {
      throw Exception('Email hoặc mật khẩu không đúng');
    }
    currentUser = user;
    // ===== LƯU userId VÀO SHAREDPREFERENCES =====
    await AuthStorageService.saveCurrentUserId(user.id);
    notifyListeners();
    return user;
  }

  /// Đăng ký và LƯU userId vào SharedPreferences
  Future<AppUser> register(String name, String email, String password) async {
    final user = await UserApi.register(name, email, password);
    currentUser = user;
    _users = await UserApi.getAllUsers();
    // ===== LƯU userId VÀO SHAREDPREFERENCES =====
    await AuthStorageService.saveCurrentUserId(user.id);
    notifyListeners();
    return user;
  }

  Future<AppUser?> getUserById(String id) async {
    return await UserApi.getUserById(id);
  }

  Future<AppUser> updateProfile({
    required String id,
    String? name,
    String? bio,
    String? address,
    String? avatar,
    String? phone,
    String? bankName,
    String? bankAccount,
    String? accountHolder,
  }) async {
    final updated = await UserApi.updateProfile(
      id: id,
      name: name,
      bio: bio,
      address: address,
      avatar: avatar,
      phone: phone,
      bankName: bankName,
      bankAccount: bankAccount,
      accountHolder: accountHolder,
    );

    currentUser = updated;
    final idx = _users.indexWhere((u) => u.id == updated.id);
    if (idx != -1) {
      _users[idx] = updated;
    }
    notifyListeners();
    return updated;
  }

  void logout() {
    currentUser = null;
    // ===== XÓA userId KHỎI SHAREDPREFERENCES =====
    // Sau khi logout, lần mở app sau sẽ phải đăng nhập lại
    AuthStorageService.clearCurrentUserId();
    notifyListeners();
  }

  List<AppUser> get users => List.unmodifiable(_users);
}
