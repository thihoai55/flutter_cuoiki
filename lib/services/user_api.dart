import '../models/user.dart';

class UserApi {
  static Future<List<AppUser>> getAllUsers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockUsers;
  }

  static Future<AppUser?> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _mockUsers.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<AppUser?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockUsers.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<AppUser> register(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final exists = _mockUsers.any((u) => u.email.toLowerCase() == email.toLowerCase());
    if (exists) throw Exception('Email đã tồn tại');
    
    final user = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      role: 'user',
      bio: 'Chào mừng tôi đến sàn trao đổi!',
      rating: 0,
      ratingCount: 0,
      joinDate: DateTime.now(),
      verifications: ['email'],
    );
    _mockUsers.add(user);
    return user;
  }

  static Future<AppUser> updateProfile({
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
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockUsers.indexWhere((u) => u.id == id);
    if (index == -1) throw Exception('Không tìm thấy người dùng');

    final updated = _mockUsers[index].copyWith(
      name: name,
      bio: bio,
      address: address,
      avatar: avatar,
      phone: phone,
      bankName: bankName,
      bankAccount: bankAccount,
      accountHolder: accountHolder,
    );
    _mockUsers[index] = updated;
    return updated;
  }

  static final List<AppUser> _mockUsers = [
    AppUser(
      id: '1',
      name: 'Admin',
      email: 'admin@student.edu.vn', 
      role: 'admin',
      avatar: 'https://i.pravatar.cc/150?img=1',
      bio: 'Quản trị viên hệ thống',
      phone: '0900000001',
      rating: 5.0,
      
      ratingCount: 45,
      address: 'TP. Hồ Chí Minh',
      joinDate: DateTime(2023, 1, 15),
      verifications: ['email', 'phone', 'identity'],
    ),
    AppUser(
      id: '2',
      name: 'Nguyễn Văn A',
      email: 'sv@student.edu.vn',
      role: 'user',
      avatar: 'https://vn1.vdrive.vn/alohamedia.vn/2025/08/fe4832ae2a3e37f030d13e5e2c131196.jpg',
      bio: 'Sinh viên ĐH Bách Khoa, yêu thích mua bán sách',
      phone: '0900000002',
      rating: 4.8,
      ratingCount: 32,
      address: 'Quận 10, TP.HCM',
      joinDate: DateTime(2023, 3, 20),
      verifications: ['email', 'phone'],
      followers: ['3', '5', '7', '10'],
      following: ['4', '6', '8'],
    ),
    AppUser(
      id: '3',
      name: 'Trần Thị B',
      email: 'tranb@student.edu.vn',
      role: 'user',
      avatar: 'https://i.pravatar.cc/150?img=3',
      bio: 'Thích tìm kiếm đồ cũ giá tốt',
      phone: '0900000003',
      rating: 4.6,
      ratingCount: 28,
      address: 'Quận 1, TP.HCM',
      joinDate: DateTime(2023, 4, 10),
      verifications: ['email', 'phone'],
      followers: ['2', '5', '8', '9', '12'],
      following: ['2', '7', '11'],
    ),
    AppUser(
      id: '4',
      name: 'Lê Văn C',
      email: 'lec@student.edu.vn',
      role: 'user',
      avatar: 'https://i.pravatar.cc/150?img=4',
      bio: 'Tư nhân bán xe đạp và phụ kiện thể thao',
      phone: '0900000004',
      rating: 4.9,
      ratingCount: 56,
      address: 'Quận 5, TP.HCM',
      joinDate: DateTime(2023, 2, 5),
      verifications: ['email', 'phone', 'identity'],
      followers: ['2', '6', '9', '11', '13', '14'],
      following: ['2', '5', '8'],
    ),
    AppUser(
      id: '5',
      name: 'Phạm Thị D',
      email: 'phamd@student.edu.vn',
      role: 'user',
      avatar: 'https://i.pravatar.cc/150?img=5',
      bio: 'Bán quần áo, giày dép chính hãng',
      phone: '0900000005',
      rating: 4.7,
      ratingCount: 41,
      address: 'Quận 3, TP.HCM',
      joinDate: DateTime(2023, 5, 12),
      verifications: ['email', 'phone'],
      followers: ['2', '3', '7', '9', '10', '13'],
      following: ['2', '4', '6', '11'],
    ),
    AppUser(
      id: '6',
      name: 'Hoàng Văn E',
      email: 'hoange@student.edu.vn',
      role: 'user',
      avatar: 'https://i.pravatar.cc/150?img=6',
      bio: 'Chuyên bán đồ nội thất và gia dụng',
      phone: '0900000006',
      rating: 4.5,
      ratingCount: 35,
      address: 'Quận 7, TP.HCM',
      joinDate: DateTime(2023, 6, 8),
      verifications: ['email', 'phone'],
      followers: ['3', '5', '8', '11', '14'],
      following: ['2', '4', '7'],
    ),
    AppUser(
      id: '7',
      name: 'Vũ Thị F',
      email: 'vuf@student.edu.vn',
      role: 'user',
      avatar: 'https://i.pravatar.cc/150?img=7',
      bio: 'Bán tai nghe, loa, đồ điện tử cao cấp',
      phone: '0900000007',
      rating: 4.9,
      ratingCount: 62,
      address: 'Quận 4, TP.HCM',
      joinDate: DateTime(2023, 1, 25),
      verifications: ['email', 'phone', 'identity'],
      followers: ['2', '3', '4', '9', '10', '12', '13', '15'],
      following: ['2', '5', '8', '11'],
    ),
    AppUser(
      id: '8',
      name: 'Đặng Văn G',
      email: 'dangg@student.edu.vn',
      role: 'user',
      avatar: 'https://i.pravatar.cc/150?img=8',
      bio: 'Tìm mua sách học tập lập trình',
      phone: '0900000008',
      rating: 4.4,
      ratingCount: 22,
      address: 'Quận 6, TP.HCM',
      joinDate: DateTime(2023, 7, 3),
      verifications: ['email'],
      followers: ['3', '4', '5', '6', '10'],
      following: ['2', '7', '11', '14'],
    ),
    AppUser(
      id: '9',
      name: 'Bùi Thị H',
      email: 'buih@student.edu.vn',
      role: 'user',
      avatar: 'https://i.pravatar.cc/150?img=9',
      bio: 'Bán bộ đồ dùng học tập, văn phòng phẩm',
      phone: '0900000009',
      rating: 4.6,
      ratingCount: 29,
      address: 'Quận 8, TP.HCM',
      joinDate: DateTime(2023, 4, 15),
      verifications: ['email', 'phone'],
      followers: ['3', '4', '5', '7', '12'],
      following: ['2', '5', '8'],
    ),
    AppUser(
      id: '10',
      name: 'Đinh Văn I',
      email: 'dinhi@student.edu.vn',
      role: 'user',
      avatar: 'https://i.pravatar.cc/150?img=10',
      bio: 'Chuyên bán mouse, bàn phím gaming',
      phone: '0900000010',
      rating: 4.8,
      ratingCount: 48,
      address: 'Quận 9, TP.HCM',
      joinDate: DateTime(2023, 3, 10),
      verifications: ['email', 'phone'],
      followers: ['2', '3', '4', '5', '7', '11', '13'],
      following: ['2', '4', '6', '8'],
    ),
    AppUser(
      id: '11',
      name: 'Dương Thị K',
      email: 'duongk@student.edu.vn',
      role: 'user',
      avatar: 'https://i.pravatar.cc/150?img=11',
      bio: 'Bán giày dép Nike, Adidas chính hãng',
      phone: '0900000011',
      rating: 4.7,
      ratingCount: 38,
      address: 'Quận 11, TP.HCM',
      joinDate: DateTime(2023, 5, 20),
      verifications: ['email', 'phone', 'identity'],
      followers: ['2', '4', '5', '6', '8', '9', '10', '12', '14'],
      following: ['2', '4', '7', '13'],
    ),
    AppUser(
      id: '12',
      name: 'Lý Văn L',
      email: 'lyl@student.edu.vn',
      role: 'user',
      avatar: 'https://i.pravatar.cc/150?img=12',
      bio: 'Bán vợt cầu lông, dụng cụ thể thao',
      phone: '0900000012',
      rating: 4.5,
      ratingCount: 26,
      address: 'Quận 12, TP.HCM',
      joinDate: DateTime(2023, 6, 5),
      verifications: ['email', 'phone'],
      followers: ['3', '5', '7', '10'],
      following: ['2', '4', '6', '8', '11'],
    ),
    AppUser(
      id: '13',
      name: 'Mai Thị M',
      email: 'maim@student.edu.vn',
      role: 'user',
      avatar: 'https://i.pravatar.cc/150?img=13',
      bio: 'Bán guitar, đàn, nhạc cụ',
      phone: '0900000013',
      rating: 4.9,
      ratingCount: 52,
      address: 'Bình Thạnh, TP.HCM',
      joinDate: DateTime(2023, 2, 14),
      verifications: ['email', 'phone', 'identity'],
      followers: ['4', '5', '7', '10', '11', '14', '15'],
      following: ['2', '5', '7', '8'],
    ),
    AppUser(
      id: '14',
      name: 'Ngô Văn N',
      email: 'ngon@student.edu.vn',
      role: 'user',
      avatar: 'https://i.pravatar.cc/150?img=14',
      bio: 'Tìm mua điện thoại cũ giá rẻ',
      phone: '0900000014',
      rating: 4.3,
      ratingCount: 18,
      address: 'Gò Vấp, TP.HCM',
      joinDate: DateTime(2023, 7, 18),
      verifications: ['email'],
      followers: ['7', '11', '13'],
      following: ['2', '5', '7', '11'],
    ),
    AppUser(
      id: '15',
      name: 'Phan Thị O',
      email: 'phano@student.edu.vn',
      role: 'user',
      avatar: 'https://i.pravatar.cc/150?img=15',
      bio: 'Bán balo, túi xách, phụ kiện',
      phone: '0900000015',
      rating: 4.6,
      ratingCount: 33,
      address: 'Tân Phú, TP.HCM',
      joinDate: DateTime(2023, 4, 22),
      verifications: ['email', 'phone'],
      followers: ['4', '5', '7', '10', '11', '13'],
      following: ['2', '4', '6', '7', '8'],
    ),
  ];
}
