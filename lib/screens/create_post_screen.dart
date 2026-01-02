import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/follow_provider.dart';
import 'user_profile_screen.dart';

const _categories = <String>[
  'Sách & Tài liệu',
  'Đồ điện tử',
  'Đồ dùng học tập',
  'Xe đạp',
  'Quần áo',
  'Gia dụng',
  'Nội thất',
  'Thể thao',
  'Nhạc cụ',
  'Phụ kiện',
  'Khác',
];

const _packageConfig = <String, Map<String, Object>>{
  'free': {
    'name': 'Gói Free',
    'price': 0.0,
    'icon': '🎁',
    'features': ['Hiển thị cơ bản', 'Không mất phí', 'Đăng lên 1 lần/ngày'],
  },
  'basic': {
    'name': 'Gói Cơ bản',
    'price': 15000.0,
    'icon': '⭐',
    'features': ['Ưu tiên hơn gói Free', 'Hiển thị trong 14 ngày', 'Đặt lên đầu'],
  },
  'premium': {
    'name': 'Gói Premium',
    'price': 50000.0,
    'icon': '👑',
    'features': ['Ưu tiên cao nhất', 'Hiển thị nổi bật', 'Gợi ý tới người mua phù hợp', '30 ngày', 'Hỗ trợ ưu tiên'],
  },
};

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

Widget _imageErrorPlaceholder() {
  return Container(
    color: Colors.grey[200],
    alignment: Alignment.center,
    child: const Icon(Icons.error, color: Colors.red),
  );
}

Uint8List? _decodeDataUri(String data) {
  if (!data.startsWith('data:image')) return null;
  final commaIndex = data.indexOf(',');
  if (commaIndex == -1) return null;
  final payload = data.substring(commaIndex + 1);
  try {
    return base64Decode(payload);
  } catch (_) {
    return null;
  }
}

class _PickedImage {
  _PickedImage({required this.source, this.bytes});

  final String source;
  final Uint8List? bytes;

  bool get isNetwork => source.startsWith('http');

  String get asPersistedString {
    if (isNetwork || source.startsWith('data:image')) return source;
    if (bytes != null) return 'data:image/jpeg;base64,${base64Encode(bytes!)}';
    return source;
  }
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();

  String _type = 'sell'; // sell or buy
  String _category = _categories.first;
  String _condition = 'Mới';
  String _selectedPackage = 'basic';
  String _paymentMethod = 'wallet'; // wallet, vnpay, momo
  bool _submitting = false;
  final List<_PickedImage> _images = [];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  double _packagePrice(String id) {
    final raw = _packageConfig[id]?['price'] as double?;
    return raw ?? 0;
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        final picked = await Future.wait(images.map((file) async {
          final bytes = await file.readAsBytes();
          return _PickedImage(source: file.path, bytes: bytes);
        }));

        setState(() => _images.addAll(picked));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final packagePrice = _packagePrice(_selectedPackage);
    
    if (_type == 'sell' && packagePrice > 0) {
      // Show payment modal
      _showPaymentModal(packagePrice);
    } else {
      _createPost();
    }
  }

  void _showPaymentModal(double price) {
    final walletProvider = context.read<WalletProvider>();
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    final balance = currentUser != null
        ? walletProvider.balanceForUser(currentUser.id)
        : 0.0;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.payment, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Thanh toán'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông tin đơn hàng
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin đơn hàng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Bài đăng:'),
                          Expanded(
                            child: Text(
                              _titleCtrl.text,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Gói:'),
                          Text(
                            (_packageConfig[_selectedPackage]?['name'] as String?) ?? _selectedPackage,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Số dư ví
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.white),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Số dư ví của bạn',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${balance.toStringAsFixed(0)}đ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Phương thức thanh toán
                const Text(
                  'Phương thức thanh toán',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),
                
                _buildPaymentMethodOption(
                  'wallet',
                  'Ví điện tử',
                  '💳',
                  'Số dư: ${balance.toStringAsFixed(0)}đ',
                  balance >= price,
                  setDialogState,
                ),
                const SizedBox(height: 8),
                _buildPaymentMethodOption(
                  'vnpay',
                  'VNPay',
                  '🏦',
                  'Thanh toán qua VNPay',
                  true,
                  setDialogState,
                ),
                const SizedBox(height: 8),
                _buildPaymentMethodOption(
                  'momo',
                  'Momo',
                  '📱',
                  'Thanh toán qua Momo',
                  true,
                  setDialogState,
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                // Tổng tiền
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng tiền:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${price.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                
                // Cảnh báo nếu không đủ tiền
                if (_paymentMethod == 'wallet' && balance < price) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Số dư không đủ. Vui lòng nạp thêm tiền!',
                            style: TextStyle(color: Colors.red[700], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: (_paymentMethod == 'wallet' && balance < price)
                  ? null
                  : () {
                      Navigator.pop(dialogContext);
                      _processPayment(price);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: const Text('Xác nhận thanh toán'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(
    String value,
    String name,
    String icon,
    String subtitle,
    bool enabled,
    StateSetter setDialogState,
  ) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: enabled
          ? () {
              setDialogState(() {
                _paymentMethod = value;
              });
            }
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: enabled
              ? (isSelected ? const Color(0xFFEFF6FF) : Colors.white)
              : Colors.grey[100],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: enabled ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: enabled ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _paymentMethod,
              onChanged: enabled
                  ? (val) {
                      if (val != null) {
                        setDialogState(() {
                          _paymentMethod = val;
                        });
                      }
                    }
                  : null,
              activeColor: const Color(0xFF2563EB),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(double price) async {
    final walletProvider = context.read<WalletProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    
    if (user == null) return;
    
    if (_paymentMethod == 'wallet') {
      // Thanh toán bằng ví
      final success = walletProvider.pay(
        price,
        description: 'Thanh toán gói ${_packageConfig[_selectedPackage]?['name']} - ${_titleCtrl.text}',
        userId: user.id,
      );
      
      if (success) {
        _createPostAndNavigate();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Thanh toán thành công ${price.toStringAsFixed(0)}đ từ ví!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Số dư không đủ!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Thanh toán qua cổng thanh toán khác (VNPay, Momo)
      // Giả lập thanh toán thành công
      await Future.delayed(const Duration(seconds: 1));
      // Ghi nhận giao dịch external để có lịch sử
      walletProvider.recordExternalPayment(
        price,
        description: 'Thanh toán gói ${_packageConfig[_selectedPackage]?['name']} - ${_titleCtrl.text}',
        userId: user.id,
        paymentMethod: _paymentMethod.toUpperCase(),
      );
      _createPostAndNavigate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thanh toán thành công qua $_paymentMethod!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _createPostAndNavigate() {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final post = PostItem(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      category: _category,
      type: _type,
      price: _type == 'sell' ? _priceCtrl.text.trim() : '',
      authorId: user.id,
      authorName: user.name,
      authorAvatar: user.avatar,
      condition: _type == 'sell' ? _condition : null,
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      contact: _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
      images: _images.map((e) => e.asPersistedString).toList(),
      status: 'pending',
      timestamp: DateTime.now(),
      packageType: _type == 'sell' ? _selectedPackage : null,
    );

    context.read<PostProvider>().addPost(
      post,
      notificationProvider: context.read<NotificationProvider>(),
      followProvider: context.read<FollowProvider>(),
    );
    
    // Chuyển đến trang profile tab pending
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          user: user,
          initialTab: 'pending',
        ),
      ),
    );
  }

  void _createPost() {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final post = PostItem(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      category: _category,
      type: _type,
      price: _type == 'sell' ? _priceCtrl.text.trim() : '',
      authorId: user.id,
      authorName: user.name,
      authorAvatar: user.avatar,
      condition: _type == 'sell' ? _condition : null,
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      contact: _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
      images: _images.map((e) => e.asPersistedString).toList(),
      status: 'pending',
      timestamp: DateTime.now(),
      packageType: _type == 'sell' ? _selectedPackage : null,
    );

    context.read<PostProvider>().addPost(
      post,
      notificationProvider: context.read<NotificationProvider>(),
      followProvider: context.read<FollowProvider>(),
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đăng bài thành công! Chờ duyệt...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = _type == 'buy';
    final accentColor = isBuy ? const Color(0xFF059669) : const Color(0xFFF59E0B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo bài đăng'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type selector
              _buildTypeSelector(isBuy, accentColor),
              const SizedBox(height: 24),

              // Form fields
              _buildFormSection(accentColor),
              const SizedBox(height: 24),

              // Package selection
              if (_type == 'sell') ...[
                _buildPackageSection(),
                const SizedBox(height: 24),
              ],

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Đăng bài',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(bool isBuy, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton('Cần bán', 'sell', isBuy ? Colors.grey[200]! : Colors.amber[100]!),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTypeButton('Cần mua', 'buy', isBuy ? Colors.green[100]! : Colors.grey[200]!),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, String value, Color bgColor) {
    final isSelected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: value == 'sell' ? Colors.amber : Colors.green)
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
            color: isSelected
                ? (value == 'sell' ? Colors.amber[900] : Colors.green[900])
                : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          _buildInputField(
            label: 'Tiêu đề *',
            controller: _titleCtrl,
            hint: 'Ví dụ: Sách Giải Tích 1 - Mới 95%',
            validator: (v) => v?.isEmpty ?? true ? 'Nhập tiêu đề' : null,
          ),
          const SizedBox(height: 16),

          // Content
          _buildInputField(
            label: 'Mô tả chi tiết *',
            controller: _contentCtrl,
            hint: 'Mô tả sản phẩm, tình trạng, lý do bán...',
            maxLines: 4,
            validator: (v) => v?.isEmpty ?? true ? 'Nhập mô tả' : null,
          ),
          const SizedBox(height: 16),

          // Category
          _buildDropdownField(
            label: 'Danh mục *',
            value: _category,
            items: _categories,
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 16),

          if (_type == 'sell') ...[
            // Price
            _buildInputField(
              label: 'Giá *',
              controller: _priceCtrl,
              hint: 'Ví dụ: 120.000đ',
              validator: (v) => v?.isEmpty ?? true ? 'Nhập giá' : null,
            ),
            const SizedBox(height: 16),

            // Condition
            _buildDropdownField(
              label: 'Tình trạng *',
              value: _condition,
              items: ['Mới', 'Như mới', 'Tốt', 'Đã sử dụng'],
              onChanged: (v) => setState(() => _condition = v!),
            ),
            const SizedBox(height: 16),
          ],

          // Location
          _buildInputField(
            label: 'Địa chỉ',
            controller: _locationCtrl,
            hint: 'Ví dụ: Quận 10, TP.HCM',
          ),
          const SizedBox(height: 16),

          // Contact
          _buildInputField(
            label: 'Số điện thoại',
            controller: _contactCtrl,
            hint: 'Ví dụ: 0912345678',
          ),
          const SizedBox(height: 16),

          // Images section
          _buildImageSection(),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(item),
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ảnh & Video',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[50],
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      const Text(
                        'Chọn ảnh hoặc video từ máy',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Chọn file'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_images.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      final image = _images[index];
                      final dataBytes = _decodeDataUri(image.source) ?? image.bytes;
                      Widget content;

                      if (image.isNetwork) {
                        content = Image.network(
                          image.source,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => _imageErrorPlaceholder(),
                        );
                      } else if (dataBytes != null) {
                        content = Image.memory(
                          dataBytes,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => _imageErrorPlaceholder(),
                        );
                      } else {
                        content = _imageErrorPlaceholder();
                      }

                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: content,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _images.removeAt(index)),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackageSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn gói đăng bài',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gói Premium sẽ giúp bài đăng của bạn nổi bật hơn',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Column(
            children: ['free', 'basic', 'premium']
                .map((pkgId) => _buildPackageCard(pkgId))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(String packageId) {
    final isSelected = _selectedPackage == packageId;
    final config = _packageConfig[packageId]!;
    final price = config['price'] as double;
    final icon = config['icon'] as String;
    final name = config['name'] as String;
    final features = config['features'] as List;

    return GestureDetector(
      onTap: () => setState(() => _selectedPackage = packageId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB).withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: features.take(2).map((f) => Text('• $f', style: const TextStyle(fontSize: 11, color: Colors.grey))).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price == 0 ? 'Free' : '${price.toStringAsFixed(0)}đ',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2563EB)),
                ),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Radio<String>(
                    value: packageId,
                    groupValue: _selectedPackage,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (v) => setState(() => _selectedPackage = v!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
