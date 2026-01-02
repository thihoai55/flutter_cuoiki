class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    this.bio,
    this.phone,
    this.rating = 0,
    this.ratingCount = 0,
    this.address,
    this.joinDate,
    this.verifications = const [],
    List<String>? followers,
    List<String>? following,
    this.bankName,
    this.bankAccount,
    this.accountHolder,
  })  : followers = followers ?? [],
        following = following ?? [];

  AppUser copyWith({
    String? name,
    String? email,
    String? role,
    String? avatar,
    String? bio,
    String? phone,
    double? rating,
    int? ratingCount,
    String? address,
    DateTime? joinDate,
    List<String>? verifications,
    List<String>? followers,
    List<String>? following,
    String? bankName,
    String? bankAccount,
    String? accountHolder,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      address: address ?? this.address,
      joinDate: joinDate ?? this.joinDate,
      verifications: verifications ?? this.verifications,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      accountHolder: accountHolder ?? this.accountHolder,
    );
  }

  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatar;
  final String? bio;
  final String? phone;
  final double rating;
  final int ratingCount;
  final String? address;
  final DateTime? joinDate;
  final List<String> verifications;
  final List<String> followers;
  final List<String> following;
  final String? bankName;
  final String? bankAccount;
  final String? accountHolder;
}
