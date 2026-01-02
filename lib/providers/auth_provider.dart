import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_api.dart';

class AuthProvider extends ChangeNotifier {
  bool isReady = true;
  AppUser? currentUser;
  List<AppUser> _users = [];

  Future<void> loadUsers() async {
    _users = await UserApi.getAllUsers();
    notifyListeners();
  }

  Future<AppUser> login(String email, String password) async {
    final user = await UserApi.login(email, password);
    if (user == null) {
      throw Exception('Email hoặc mật khẩu không đúng');
    }
    currentUser = user;
    notifyListeners();
    return user;
  }

  Future<AppUser> register(String name, String email, String password) async {
    final user = await UserApi.register(name, email, password);
    currentUser = user;
    _users = await UserApi.getAllUsers();
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
    notifyListeners();
  }

  List<AppUser> get users => List.unmodifiable(_users);
}
