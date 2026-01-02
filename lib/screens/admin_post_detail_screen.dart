import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';
import '../widgets/post_image.dart';

class AdminPostDetailScreen extends StatefulWidget {
  final PostItem post;

  const AdminPostDetailScreen({super.key, required this.post});

  @override
  State<AdminPostDetailScreen> createState() => _AdminPostDetailScreenState();
}

class _AdminPostDetailScreenState extends State<AdminPostDetailScreen> {
  int _selectedImage = 0;

  List<String> get _images {
    if (widget.post.images.isNotEmpty) return widget.post.images;
    if (widget.post.image != null) return [widget.post.image!];
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    final mainImage = images.isNotEmpty ? images[_selectedImage] : null;
    final post = widget.post;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Bài Đăng'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh chính
            if (mainImage != null)
              PostImage(
                url: mainImage,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                placeholder: Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 64, color: Colors.grey),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 300,
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 64, color: Colors.grey),
              ),

            // Thumbnails nếu có nhiều ảnh
            if (images.length > 1)
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemBuilder: (context, index) {
                    final url = images[index];
                    final selected = index == _selectedImage;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedImage = index),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selected ? Colors.blue : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: PostImage(
                            url: url,
                            width: 92,
                            height: 92,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              width: 92,
                              height: 92,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemCount: images.length,
                ),
              ),
            
            // Nội dung
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Thông tin tác giả
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                          ),
                          child: post.authorAvatar != null
                              ? ClipOval(
                                  child: Image.network(
                                    post.authorAvatar!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(
                                        post.authorName[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    post.authorName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                post.timestamp != null
                                    ? 'Đăng lúc: ${post.timestamp!.toString().split('.')[0]}'
                                    : 'Vừa xong',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Thông tin bài đăng
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông Tin Bài Đăng',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow('Danh mục', post.category),
                        const SizedBox(height: 8),
                        _InfoRow('Loại', post.type == 'sell' ? 'Đang bán' : 'Cần mua'),
                        const SizedBox(height: 8),
                        _InfoRow(
                          'Giá',
                          post.price,
                          valueColor: const Color(0xFF16A34A),
                        ),
                        const SizedBox(height: 8),
                        if (post.condition != null)
                          _InfoRow('Tình trạng', post.condition!),
                        if (post.location != null)
                          const SizedBox(height: 8),
                        if (post.location != null)
                          _InfoRow('Địa điểm', post.location!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mô tả
                  const Text(
                    'Mô Tả Chi Tiết',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.content,
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                  const SizedBox(height: 16),

                  // Liên hệ
                  if (post.contact != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.phone, color: Colors.green[700]),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Liên Hệ',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                post.contact!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Hành động (nếu là pending)
                  if (post.status == 'pending')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hành Động',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final confirmed = await _confirmDialog(
                                    context,
                                    'Duyệt bài',
                                    'Bạn có chắc muốn duyệt bài này?',
                                  );
                                  if (confirmed == true) {
                                    if (context.mounted) {
                                      await context
                                          .read<PostProvider>()
                                          .approvePost(post.id, context.read());
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Đã duyệt bài đăng'),
                                          ),
                                        );
                                        Navigator.pop(context);
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Duyệt'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final reason = await _showRejectionModal(context);
                                  if (reason != null && reason.isNotEmpty) {
                                    if (context.mounted) {
                                      await context.read<PostProvider>().rejectPost(
                                            post.id,
                                            reason: reason,
                                            notificationProvider: context.read(),
                                          );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Đã từ chối bài đăng'),
                                          ),
                                        );
                                        Navigator.pop(context);
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.cancel),
                                label: const Text('Từ chối'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFEF4444),
                                  side: const BorderSide(
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showRejectionModal(BuildContext context) {
    final reasonCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lý Do Từ Chối'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Nhập lý do từ chối bài đăng này...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonCtrl.text),
            child: const Text('Từ chối'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow(
    this.label,
    this.value, {
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
