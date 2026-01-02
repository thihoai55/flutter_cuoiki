import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/post.dart';
import '../providers/post_provider.dart';

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

class EditPostScreen extends StatefulWidget {
  const EditPostScreen({super.key, required this.post});

  final PostItem post;

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _contactCtrl;

  late String _type;
  late String _category;
  late String _condition;
  bool _submitting = false;
  late List<String> _imageUrls;

  @override
  void initState() {
    super.initState();
    // Pre-fill với dữ liệu từ post
    _titleCtrl = TextEditingController(text: widget.post.title);
    _contentCtrl = TextEditingController(text: widget.post.content);
    _priceCtrl = TextEditingController(text: widget.post.price);
    _locationCtrl = TextEditingController(text: widget.post.location ?? '');
    _contactCtrl = TextEditingController(text: widget.post.contact ?? '');
    
    _type = widget.post.type;
    _category = widget.post.category;
    _condition = widget.post.condition ?? 'Mới';
    _imageUrls = List<String>.from(widget.post.images);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _imageUrls.addAll(images.map((e) => e.path));
        });
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

    setState(() => _submitting = true);

    final updatedPost = PostItem(
      id: widget.post.id,
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      category: _category,
      type: _type,
      price: _type == 'sell' ? _priceCtrl.text.trim() : '',
      authorId: widget.post.authorId,
      authorName: widget.post.authorName,
      authorAvatar: widget.post.authorAvatar,
      condition: _type == 'sell' ? _condition : null,
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      contact: _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
      images: _imageUrls,
      status: widget.post.status,
      timestamp: widget.post.timestamp,
      packageType: widget.post.packageType,
      likes: widget.post.likes,
      views: widget.post.views,
      likedBy: widget.post.likedBy,
      savedBy: widget.post.savedBy,
      sold: widget.post.sold,
      hidden: widget.post.hidden,
      soldTimestamp: widget.post.soldTimestamp,
      buyerId: widget.post.buyerId,
      buyerName: widget.post.buyerName,
      buyerAvatar: widget.post.buyerAvatar,
    );

    context.read<PostProvider>().updatePost(updatedPost);
    
    setState(() => _submitting = false);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật bài đăng!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = _type == 'buy';
    final accentColor = isBuy ? const Color(0xFF059669) : const Color(0xFFF59E0B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa bài đăng'),
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

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
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
                          'Cập nhật',
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
              if (_imageUrls.isNotEmpty)
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
                    itemCount: _imageUrls.length,
                    itemBuilder: (context, index) {
                      final imagePath = _imageUrls[index];
                      final isNetworkImage = imagePath.startsWith('http');
                      
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: isNetworkImage
                                  ? Image.network(
                                      imagePath,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error, color: Colors.red),
                                      ),
                                    )
                                  : Image.file(
                                      File(imagePath),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _imageUrls.removeAt(index)),
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
}
