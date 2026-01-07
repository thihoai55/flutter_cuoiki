import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/avatar_image.dart';
import '../widgets/main_layout.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();
  final _accountHolderCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  int _currentTab = 0;
  bool _saving = false;
  String? _error;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _nameCtrl.text = user.name;
      _emailCtrl.text = user.email;
      _phoneCtrl.text = user.phone ?? '';
      _bioCtrl.text = user.bio ?? '';
      _addressCtrl.text = user.address ?? '';
      _avatarCtrl.text = user.avatar ?? '';
      _bankNameCtrl.text = user.bankName ?? '';
      _bankAccountCtrl.text = user.bankAccount ?? '';
      _accountHolderCtrl.text = user.accountHolder ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _addressCtrl.dispose();
    _avatarCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    _accountHolderCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file != null) {
        final bytes = await file.readAsBytes();
        final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _avatarPath = dataUri;
          _avatarCtrl.text = '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không chọn được ảnh: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final avatarValue = (_avatarPath != null && _avatarPath!.isNotEmpty)
          ? _avatarPath
          : (_avatarCtrl.text.trim().isNotEmpty ? _avatarCtrl.text.trim() : null);

      await auth.updateProfile(
        id: user.id,
        name: _nameCtrl.text.trim().isEmpty ? user.name : _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        avatar: avatarValue,
        phone: _phoneCtrl.text.trim(),
        bankName: _bankNameCtrl.text.trim(),
        bankAccount: _bankAccountCtrl.text.trim(),
        accountHolder: _accountHolderCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu thông tin')),
        );
      }
    } catch (e) {
      setState(() => _error = 'Không thể lưu: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const MainLayoutWithCustomAppBar(
        title: 'Chỉnh sửa thông tin',
        showDrawer: true,
        child: Center(child: Text('Vui lòng đăng nhập lại để chỉnh sửa thông tin.')),
      );
    }

    return MainLayoutWithCustomAppBar(
      title: 'Chỉnh sửa thông tin',
      showDrawer: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFB91C1C)),
                ),
              ),
            if (_error != null) const SizedBox(height: 12),

            _ProfilePreview(
              name: _nameCtrl.text.isEmpty ? user.name : _nameCtrl.text,
              email: user.email,
              role: user.role,
              avatar: (_avatarPath != null && _avatarPath!.isNotEmpty)
                  ? _avatarPath
                  : (_avatarCtrl.text.trim().isNotEmpty ? _avatarCtrl.text.trim() : user.avatar),
            ),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildTabButton('Cá nhân', 0),
                  _buildTabButton('Địa chỉ', 1),
                  _buildTabButton('Ngân hàng', 2),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildTabContent(_currentTab),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Đang lưu...' : 'Lưu thay đổi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(int tab) {
    if (tab == 0) {
      // Personal info tab
      return Column(
        children: [
          _buildInput(
            label: 'Họ và tên',
            controller: _nameCtrl,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _buildInput(
            label: 'Email sinh viên',
            controller: _emailCtrl,
            icon: Icons.email_outlined,
            enabled: false,
          ),
          const SizedBox(height: 12),
          _buildInput(
            label: 'Số điện thoại',
            controller: _phoneCtrl,
            icon: Icons.phone_iphone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildInput(
            label: 'Giới thiệu bản thân',
            controller: _bioCtrl,
            icon: Icons.info_outline,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ảnh đại diện', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AvatarImage(
                      url: (_avatarPath != null && _avatarPath!.isNotEmpty)
                          ? _avatarPath
                          : (_avatarCtrl.text.trim().isNotEmpty ? _avatarCtrl.text.trim() : null),
                      size: 72,
                      initials: (_nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : 'U'),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickAvatar,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Chọn ảnh từ máy'),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _avatarCtrl,
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'Hoặc dán URL ảnh (tuỳ chọn)',
                              prefixIcon: Icon(Icons.link_outlined),
                            ),
                          ),
                          if (_avatarPath != null && _avatarPath!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Đang dùng ảnh trong máy',
                                style: TextStyle(color: Colors.green[700], fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    } else if (tab == 1) {
      // Address tab
      return _buildInput(
        label: 'Địa chỉ',
        controller: _addressCtrl,
        icon: Icons.location_on_outlined,
        maxLines: 3,
      );
    } else {
      // Bank info tab
      return Column(
        children: [
          _buildInput(
            label: 'Tên ngân hàng',
            controller: _bankNameCtrl,
            icon: Icons.account_balance,
            hint: 'Ví dụ: Vietcombank, Techcombank',
          ),
          const SizedBox(height: 12),
          _buildInput(
            label: 'Số tài khoản',
            controller: _bankAccountCtrl,
            icon: Icons.credit_card,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _buildInput(
            label: 'Chủ tài khoản',
            controller: _accountHolderCtrl,
            icon: Icons.person,
          ),
        ],
      );
    }
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    bool enabled = true,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
      ),
    );
  }
}


class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview({
    required this.name,
    required this.email,
    required this.role,
    required this.avatar,
  });

  final String name;
  final String email;
  final String role;
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AvatarImage(
              url: avatar,
              size: 76,
              initials: initials,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      role == 'admin' ? 'Quản trị viên' : 'Thành viên',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
